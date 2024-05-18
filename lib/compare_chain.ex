defmodule CompareChain do
  @moduledoc """
  Convenience macros for doing comparisons
  """

  require Integer

  @doc """
  Macro that performs chained comparison using operators like `<` and
  combinations using `and` `or`, and `not`.

  ## Examples

  Chained comparison:

      iex> import CompareChain
      iex> compare?(1 < 2 < 3)
      true

  Comparisons joined by logical operators:

      iex> import CompareChain
      iex> compare?(1 >= 2 >= 3 or 4 >= 5 >= 6)
      false

  ## Notes

  You must include at least one comparison like `<` in your expression.
  Failing to do so will result in a compile time error.

  Including a struct in the expression will result in a warning.
  You probably want to use `compare?/2` instead.
  """
  defmacro compare?(expr) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, CompareChain.DefaultCompare)
  end

  @doc """
  Similar to `compare?/1` except you can provide a module that defines a
  `compare/2` for semantic comparisons.

  This is like how you can provide a module as the second argument to
  `Enum.sort/2`.

  ## Examples

  Basic comparison (note how `a < b == false` natively because of structural
  comparison):

      iex> import CompareChain
      iex> a = ~D[2017-03-31]
      iex> b = ~D[2017-04-01]
      iex> a < b
      false
      iex> compare?(a < b, Date)
      true

  Chained comparison:

      iex> import CompareChain
      iex> a = ~D[2017-03-31]
      iex> b = ~D[2017-04-01]
      iex> c = ~D[2017-04-02]
      iex> compare?(a < b < c, Date)
      true

  Comparisons joined by logical operators:

      iex> import CompareChain
      iex> a = ~T[15:00:00]
      iex> b = ~T[16:00:00]
      iex> c = ~T[17:00:00]
      iex> compare?(a < b and b > c, Time)
      false

  More complex expressions:

      iex> import CompareChain
      iex> compare?(%{a: ~T[16:00:00]}.a <= ~T[17:00:00], Time)
      true

  Custom module:

      iex> import CompareChain
      iex> defmodule AlwaysGreaterThan do
      iex>   def compare(_left, _right), do: :gt
      iex> end
      iex> compare?(1 > 2 > 3, AlwaysGreaterThan)
      true

  ## Notes

  You must include at least one comparison like `<` in your expression.
  Failing to do so will result in a compile time error.
  """
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, module)
  end

  # Calls `chain` on the arguments of `and` and `or`.
  # E.g. for `a < b < c and d > e`,
  #
  #                      and
  #                     /   \
  #          (a < b < c)     (c > d)
  #
  # becomes
  #
  #                      and
  #                     /   \
  #     chain(a < b < c)     chain(c > d)
  defp do_compare?(ast, module) do
    {ast, chain_or_raise_called?} =
      Macro.postwalk(ast, false, fn
        {op, meta, [left, right]}, called? when op in [:and, :or] ->
          {left, called_left?} = maybe_call_chain_or_raise(left, module)
          {right, called_right?} = maybe_call_chain_or_raise(right, module)

          called? = called? or called_left? or called_right?

          {{op, meta, [left, right]}, called?}

        node, called? ->
          {node, called?}
      end)

    # If no `and`s or `or`s were present in `ast`, we haven't called
    # `chain_or_raise` yet and so we need to do so.
    if not chain_or_raise_called? do
      chain_or_raise(ast, module)
    else
      ast
    end
  end

  defp maybe_call_chain_or_raise(node, module) do
    case node do
      {op, _, _} when op in [:<, :>, :<=, :>=, :==, :!=, :not] ->
        {chain_or_raise(node, module), true}

      _ ->
        {node, false}
    end
  end

  defp chain_or_raise(node, module) do
    node = chain(node, module)

    if node == :no_comparison_operators_found do
      raise ArgumentError, CompareChain.ErrorMessage.chain_error_message()
    else
      node
    end
  end

  # Transforms a chain of comparisons into a series of `and`'d pairs.
  # E.g. for `a < b < c`,
  #
  #         <
  #        / \
  #       <   c
  #      / \
  #     a   b
  #
  # becomes
  #
  #         and
  #        /   \
  #       ~     ~
  #      / \   / \
  #     a   b b   c
  #
  # where `~` is roughly `compare(left, right) == :lt`.
  defp chain(ast, module) do
    {not_count, ast} = unwrap_nots(ast)

    expr_or_atom =
      ast
      |> chain_nested_ops()
      |> Enum.map(fn op -> op_to_module_expr(op, module) end)
      |> Enum.reduce(:no_comparison_operators_found, fn expr, acc ->
        if acc == :no_comparison_operators_found do
          expr
        else
          quote(do: unquote(acc) and unquote(expr))
        end
      end)

    cond do
      expr_or_atom == :no_comparison_operators_found ->
        :no_comparison_operators_found

      Integer.is_odd(not_count) ->
        quote(do: not unquote(expr_or_atom))

      true ->
        expr_or_atom
    end
  end

  # Unwraps any nested series of `not`s and counts the number of `not`s.
  # E.g. `not (not (not (1 < 2)))` returns `{3, 1 < 2}`
  defp unwrap_nots(ast) do
    [nil]
    |> Stream.cycle()
    |> Enum.reduce_while({0, ast}, fn
      _, {count, {:not, _, [node]}} ->
        {:cont, {count + 1, node}}

      # Do I need to also account for `:__block__` elsewhere?
      _, {count, {:__block__, _, [node]}} ->
        {:cont, {count, node}}

      _, {count, node} ->
        {:halt, {count, node}}
    end)
  end

  # Converts nested expressions like:
  #
  #     <(<(<(a, b), c), d)
  #
  # to a list of paired expresions like:
  #
  #     [<(a, b), <(b, c), <(c, d)]
  defp chain_nested_ops(ast) do
    ast
    # Build up a stack of comparison operators and their right arguments.
    # This works because the right is guaranteed to be a comparison leaf, not
    # another comparison.
    |> Macro.prewalker()
    |> Enum.drop_while(fn
      {op, _, _} when op in [:<, :>, :<=, :>=, :==, :!=] -> false
      _ -> true
    end)
    |> Enum.reduce_while([], fn
      {op, _, [_left, right]}, acc when op in [:<, :>, :<=, :>=, :==, :!=] ->
        {:cont, [{op, right} | acc]}

      node, acc ->
        {:halt, [{nil, node} | acc]}
    end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [{_, left}, {op, right}] -> {op, left, right} end)
  end

  # Converts an ast like:
  #
  #     {<, left, right}
  #
  # to an expression like:
  #
  #     module.compare(left, right) == :lt
  defp op_to_module_expr({op, left, right}, module) do
    {kernel_fun, evals_to} =
      case op do
        :< -> {:==, :lt}
        :> -> {:==, :gt}
        :<= -> {:!=, :gt}
        :>= -> {:!=, :lt}
        :== -> {:==, :eq}
        :!= -> {:!=, :eq}
      end

    inner_comparison =
      quote do
        unquote(module).compare(unquote(left), unquote(right))
      end

    quote do
      Kernel.unquote(kernel_fun)(unquote(inner_comparison), unquote(evals_to))
    end
  end
end
