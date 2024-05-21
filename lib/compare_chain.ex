defmodule CompareChain do
  @moduledoc """
  Convenience macros for doing comparisons
  """

  alias CompareChain.Core
  alias CompareChain.ErrorMessage

  @doc """
  Macro that performs chained comparison with operators like `<`.

  You man also include combinations using `and`, `or`, and `not` in the
  expression.

  For a version that also does semantic comparison, see: `compare?/2`.

  ## Examples

  Chained comparison:

      iex> import CompareChain
      iex> compare?(1 < 2 < 3)
      true

  Comparisons joined by logical operators:

      iex> import CompareChain
      iex> compare?(1 >= 2 >= 3 or 4 >= 5 >= 6)
      false

  ## Warnings and errors

  > ### Comparing structs {: .warning}
  >
  > Expressions which compare matching structs like:
  >
  >     iex> compare?(~D[2017-03-31] < ~D[2017-04-01])
  >     false
  >
  > Will result in a warning:
  >
  > ```plain
  > ... [warning] Performing structural comparison on matching structs.
  >
  > Did you mean to use `compare?/2`?
  >
  >   compare?(~D[2017-03-31] < ~D[2017-04-01], Date)
  > ```
  >
  > You probably want to use `compare?/2`, which does semantic comparison,
  > instead.

  > ### Compilation requirement {: .error}
  >
  > You must include at least one comparison like `<` in your expression.
  > Failing to do so will result in a compile time error.
  """
  defmacro compare?(expr) do
    ast = quote(do: unquote(expr))
    do_compare?(ast)
  end

  @doc """
  Macro that performs chained, semantic comparison with operators like `<` by
  rewriting the expression using the `compare/2` function defined by the
  provided module.

  This is like how you can provide a module as the second argument to
  `Enum.sort/2` when you need to sort items semantically.

  You man also include combinations using `and`, `or`, and `not` in the
  expression.

  For a version that does chained comparison using the normal `<` operators,
  see: `compare?/1`.

  ## Examples

  Semantic comparison (note how `a < b == false` because of native structural
  comparison):

      iex> import CompareChain
      iex> a = ~D[2017-03-31]
      iex> b = ~D[2017-04-01]
      iex> a < b
      false
      iex> compare?(a < b, Date)
      true

  Chained, semantic comparison:

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

  ## Warnings and errors

  > ### Compilation requirement {: .error}
  >
  > You must include at least one comparison like `<` in your expression.
  > Failing to do so will result in a compile time error.
  """
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, module)
  end

  defguardp is_symmetric_op(op) when op == :== or op == :!= or op == :=== or op == :!==
  defguardp is_asymmetric_op(op) when op == :<= or op == :>= or op == :< or op == :>
  defguardp is_comparison_op(op) when is_symmetric_op(op) or is_asymmetric_op(op)
  defguardp is_comparison(node) when is_tuple(node) and is_comparison_op(elem(node, 0))

  defp do_compare?(ast) do
    ast
    |> preprocess()
    |> chain_nested_comparisons()
    |> default_comparisons()
  end

  defp do_compare?(ast, module) do
    ast
    |> preprocess()
    |> chain_nested_comparisons()
    |> semantic_comparisons(module)
  end

  defp preprocess(ast) do
    {preprocessed_ast, comparison_found?} =
      ast
      # Nested `compare?`s like `compare?(compare?(a < b, Date) == true)`
      # aren't supported.
      |> Macro.prewalk(fn
        {:compare?, _, _} -> raise ArgumentError, ErrorMessage.nested_not_allowed()
        node -> node
      end)
      # Unwrap blocks so they don't mess with how we detect nested comparisons.
      |> Macro.prewalk(fn
        {:__block__, _, [node]} -> node
        node -> node
      end)
      # Check if we have any comparison operators.
      |> Macro.prewalk(false, fn
        node, _ when is_comparison(node) -> {node, true}
        node, comparison_found? -> {node, comparison_found?}
      end)

    if not comparison_found? do
      raise ArgumentError, ErrorMessage.comparison_required()
    end

    preprocessed_ast
  end

  defp chain_nested_comparisons(ast) do
    ast
    |> Macro.prewalk(fn
      {_, _, [inner, _]} = outer when is_comparison(outer) and is_comparison(inner) ->
        chain_nested_comparison(outer)

      node ->
        node
    end)
  end

  # Converts an ast like `==(c, <=(a, b))` to an ast like `<=(==(c, a), b)`.
  # We do this to cover an edge case where symmetric comparison operators have
  # a higher precedence than the asymmetric operators. They therefore appear
  # "out of order" in the AST. This reordering should result in an equivalent
  # expression due to symmetry.
  defp chain_nested_comparison({outer, meta_outer, [c, {inner, meta_inner, [a, b]}]})
       when is_symmetric_op(outer) and is_asymmetric_op(inner) do
    # Reminder! The ((c, a), b) order looks wrong but is correct.
    reordered_ast = {inner, meta_inner, [{outer, meta_outer, [c, a]}, b]}
    chain_nested_comparison(reordered_ast)
  end

  # Converts an ast for `a < b < c` to an ast for `a < b and b < c`.
  defp chain_nested_comparison({outer, meta, [{inner, _, [a, b]}, c]}) do
    left = {inner, meta, [a, b]}
    right = {outer, meta, [b, c]}
    {:and, meta, [left, right]}
  end

  defp default_comparisons(ast) do
    Macro.prewalk(ast, fn
      node when is_comparison(node) -> default_comparison(node)
      node -> node
    end)
  end

  defp default_comparison({op, meta, [left, right]}) do
    # We use `Core.compare/3` here so we can warn at runtime when structs are
    # provided as arguments. We can't detect structs easily at compile time.
    compare_fun = {:., meta, [Core, :compare]}
    {compare_fun, meta, [op, left, right]}
  end

  # Convert structural comparisons to semantic comparisons.
  defp semantic_comparisons(ast, module) do
    Macro.prewalk(ast, fn
      node when is_comparison(node) -> semantic_comparison(node, module)
      node -> node
    end)
  end

  # Converts an ast for `left < right` to an ast for
  # `module.compare(left, right) == :lt`.
  defp semantic_comparison({op, meta, [left, right]}, module) do
    {kernel_fun, evals_to} =
      case op do
        :< -> {:==, :lt}
        :> -> {:==, :gt}
        :<= -> {:!=, :gt}
        :>= -> {:!=, :lt}
        :== -> {:==, :eq}
        :!= -> {:!=, :eq}
        :=== -> {:==, :eq}
        :!== -> {:!=, :eq}
      end

    # We're using `Core.compare/4` instead of the module directly so we can
    # warn at runtime about the use of strict operators.
    compare_fun = {:., meta, [Core, :compare]}
    comparison = {compare_fun, meta, [module, op, left, right]}
    {kernel_fun, meta, [comparison, evals_to]}
  end
end
