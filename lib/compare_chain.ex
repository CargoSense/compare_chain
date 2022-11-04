defmodule CompareChain do
  @moduledoc """
  Convenience macros for doing comparisons
  """

  @doc """
  Macro that performs chained comparison using operators like `<` and
  combinations using `and` and `or`.

  ## Examples

  Basic comparison:

    ```
    iex> import CompareChain
    iex> compare?(1 < 2)
    true
    ```

  Chained comparison:

    ```
    iex> import CompareChain
    iex> compare?(1 < 2 < 3)
    true
    ```

  Comparisons joined by logical operators:

    ```
    iex> import CompareChain
    iex> compare?(1 >= 2 and 4 > 3)
    false
    ```

  ## Notes

  You may not use `not` in the `compare?/1` expression.
  Doing so will result in a compile time error.
  Consider using negation rules, e.g. `not (a < b)` becomes ` a >= b`.

  You must include at least one comparison like `<` in your expression.
  Failing to do so will result in a compile time error.
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
  See the notes in `compare?/1` as they apply to `compare?/2` as well.

  ## Examples

  Basic comparison (note how `a < b == false` natively because of structural
  comparison):

    ```
    iex> import CompareChain
    iex> a = ~D[2017-03-31]
    iex> b = ~D[2017-04-01]
    iex> a < b
    false
    iex> compare?(a < b, Date)
    true
    ```

  Chained comparison:

    ```
    iex> import CompareChain
    iex> a = ~D[2017-03-31]
    iex> b = ~D[2017-04-01]
    iex> c = ~D[2017-04-02]
    iex> compare?(a < b < c, Date)
    true
    ```

  Comparisons joined by logical operators:

    ```
    iex> import CompareChain
    iex> a = ~T[15:00:00]
    iex> b = ~T[16:00:00]
    iex> c = ~T[17:00:00]
    iex> compare?(a < b and b > c, Time)
    false
    ```

  Custom module:

    ```
    iex> import CompareChain
    iex> defmodule AlwaysGreaterThan do
    iex>   def compare(_left, _right), do: :gt
    iex> end
    iex> compare?(1 > 2 > 3, AlwaysGreaterThan)
    true
    ```
  """
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, module)
  end

  # Calls `chain` on the arguments of `and` and `or`.
  # E.g. for `a < b < c and d > e`,
  #
  # ```
  #              and
  #             /   \
  #  (a < b < c)     (c > d)
  # ```
  #
  # becomes
  #
  # ```
  #                   and
  #                  /   \
  #  chain(a < b < c)     chain(c > d)
  # ```
  defp do_compare?(ast, module) do
    ast
    |> Macro.prewalker()
    # Build a stack of `and`s and `or`s and their right arguments.
    # This works because
    #   1. the `and` and `or` combinations are always higher than `<` and
    #      friends in the ast and
    #   2. the right argument will always be a combination leaf, never another
    #      combination.
    # The head of the stack will be special: `{nil, nil, node}`.
    |> Enum.reduce_while([], fn
      {c, meta, [_left, right]}, acc when c in [:and, :or] ->
        {:cont, [{c, meta, right} | acc]}

      node, acc ->
        {:halt, [{nil, nil, node} | acc]}
    end)
    # Unwind stack back into the ast while calling `chain` on the nodes.
    |> Enum.reduce(nil, fn
      {nil, nil, node}, nil ->
        chain_or_raise(node, module)

      {c, meta, node}, acc ->
        {c, meta, [acc, chain_or_raise(node, module)]}
    end)
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
  # ```
  #     <
  #    / \
  #   <   c
  #  / \
  # a   b
  # ```
  #
  # becomes
  #
  # ```
  #     and
  #    /   \
  #   ~     ~
  #  / \   / \
  # a   b b   c
  # ```
  #
  # where `~` is roughly `compare(left, right) == :lt`.
  defp chain(ast, module) do
    ast
    |> Macro.prewalker()
    # Build up a stack of comparison operators and their right arguments.
    # This works because the right is guaranteed to be a comparison leaf, not
    # another comparison.
    |> Enum.reduce_while([], fn
      {:not, _, [_]}, _ ->
        raise_on_not()

      {op, _, [_left, right]}, acc when op in [:<, :>, :<=, :>=] ->
        {:cont, [{op, right} | acc]}

      node, acc ->
        {:halt, [{nil, node} | acc]}
    end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(:no_comparison_operators_found, fn [{_, left}, {op, right}], acc ->
      {kernel_fun, evals_to} =
        case op do
          :< -> {:==, :lt}
          :> -> {:==, :gt}
          :<= -> {:!=, :gt}
          :>= -> {:!=, :lt}
        end

      inner_comparison =
        quote do
          unquote(module).compare(unquote(left), unquote(right))
        end

      outer_comparison =
        quote do
          Kernel.unquote(kernel_fun)(unquote(inner_comparison), unquote(evals_to))
        end

      if acc == :no_comparison_operators_found do
        outer_comparison
      else
        quote(do: unquote(acc) and unquote(outer_comparison))
      end
    end)
  end

  defp raise_on_not() do
    raise ArgumentError, CompareChain.ErrorMessage.raise_on_not_message()
  end
end
