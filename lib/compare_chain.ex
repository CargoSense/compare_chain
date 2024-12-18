defmodule CompareChain do
  @moduledoc """
  Convenience macros for doing comparisons

  ## Valid expressions

  Valid expressions for `compare?/1` and `compare?/2` follow these three rules:

  ### 1. A comparison operator like `<` must be present.

  At least one of these must be included: `<`, `>`, `<=`, `>=`, `==`, `!=`,
  `===`, or `!===`. So this is valid:

      compare?(1 < 2 < 3)

  but this is not:

      compare?(true)

  because it does not contain any comparisons.

  ### 2. All arguments to boolean operators must also be valid expressions.

  The boolean operators `and`, `or`, and `not` are allowed in expressions so
  long as all of their arguments (eventually) contain a comparison. So this is
  valid:

      compare?(1 < 2 < 3 and 4 < 5)

  as is this:

      compare?(not (not 1 < 2 < 3))

  but this is not:

      compare?(1 < 2 < 3 and true)

  because the right side of `and` fails to contain a comparison. This
  expression can be refactored to be valid by moving the non-comparison branch
  outside `compare?/1` like so:

      compare?(1 < 2 < 3) and true

  ### 3. The root operator of an expression must be a comparison or a boolean.

  So this is not valid:

      compare?(my_function(a < b), Date)

  because its root operator is `my_function/1`. This expression can be
  refactored to be valid by moving `compare?/2` inside `my_function/1` like so:

      my_function(compare?(a < b, Date))

  We restrict expressions in this fashion so we can guarantee that `compare?/1`
  and `compare?/2` will always return a boolean.

  Also note that arguments to _comparisons_ may be arbitrarily complicated:

      compare?(a < Date.utc_today(), Date)
  """

  alias CompareChain.Core
  alias CompareChain.ErrorMessage

  @doc """
  Macro that performs chained comparison with operators like `<`.

  You may also include the boolean operators `and`, `or`, and `not` in the
  expression so long as all their arguments all (eventually) contain
  comparisons. See the moduledoc for more details.

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

  > ### Comparing structs will warn {: .warning}
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

  > ### Invalid expressions will raise {: .error}
  >
  > See the section on valid expressions in the moduledoc for details.
  """
  defmacro compare?(expr) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, Kernel)
  end

  @doc """
  Macro that performs chained, semantic comparison with operators like `<` by
  rewriting the expression using the `compare/2` function defined by the
  provided module.

  This is like how you can provide a module as the second argument to
  `Enum.sort/2` when you need to sort items semantically.

  You may also include the boolean operators `and`, `or`, and `not` in the
  expression so long as all their arguments all (eventually) contain
  comparisons. See the moduledoc for more details.

  For a version that does chained comparison using the normal `<` operators,
  see: `compare?/1`.

  ## Examples

  Semantic comparison:

      iex> import CompareChain
      iex> a = ~D[2017-03-31]
      iex> b = ~D[2017-04-01]
      iex> compare?(a < b, Date)
      true

  > #### Semantic vs. Structural Comparison Differences {: .info}
  >
  > In the above example, `compare?(a < b, Date)` evaluates to `true`. On its
  > own, `a < b` evaluates to `false` (with a warning). **This is why it's so
  > important to not use comparison operators on structs directly.** The answer
  > is not what you would expect.
  >
  > _Trivia!_ If you're curious, `b` comes before `a` because in term ordering,
  > maps of equal size are compared key by key in ascending order. In this case,
  > `:day` is the first key (due to ASCII byte ordering) where `a` and `b`
  > differ. Since `a.day == 31` and `b.day == 1`, we have `b < a`.

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

  > ### Using the "strict" operators will warn {: .warning}
  >
  > Expressions which include either `===` or `!==` like:
  >
  >     iex> compare?(~D[2017-03-31] !== ~D[2017-04-01], Date)
  >     true
  >
  > Will result in a warning:
  >
  > ```plain
  > ... [warning] Performing semantic comparison using either: `===` or `!===`.
  > This is reinterpreted as `==` or `!=`, respectively.
  > ```
  >
  > These operators have no additional meaning over `==` and `!=` when doing
  > semantic comparison.

  > ### Invalid expressions will raise {: .error}
  >
  > See the section on valid expressions in the moduledoc for details.
  """
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, module)
  end

  defguardp is_symmetric_op(op) when op == :== or op == :!= or op == :=== or op == :!==
  defguardp is_asymmetric_op(op) when op == :<= or op == :>= or op == :< or op == :>
  defguardp is_combination_op(op) when op == :and or op == :or or op == :not
  defguardp is_comparison_op(op) when is_symmetric_op(op) or is_asymmetric_op(op)
  defguardp is_comparison(node) when is_tuple(node) and is_comparison_op(elem(node, 0))
  defguardp is_combination(node) when is_tuple(node) and is_combination_op(elem(node, 0))

  defp do_compare?(ast, module) do
    ast
    |> preprocess()
    |> chain_nested_comparisons()
    |> convert_comparisons(module)
  end

  defp preprocess(ast) do
    # Unwrap blocks so they don't mess with how we detect nested comparisons.
    ast_without_blocks =
      Macro.prewalk(ast, fn
        {:__block__, _, [node]} -> node
        node -> node
      end)

    if not valid?(ast_without_blocks) do
      raise ArgumentError, ErrorMessage.invalid_expression(ast)
    end

    ast_without_blocks
  end

  defp valid?(ast), do: valid?(ast, false)
  defp valid?(node, false) when is_combination(node), do: Enum.all?(elem(node, 2), &valid?/1)
  defp valid?(node, false) when is_comparison(node), do: true
  defp valid?(_, _), do: false

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

  defp convert_comparisons(ast, module) do
    Macro.prewalk(ast, fn
      node when is_comparison(node) -> convert_comparison(node, module)
      node -> node
    end)
  end

  defp convert_comparison({op, meta, [left, right]}, module) do
    # We use `Core.compare?/4` instead of direct AST manipulation so we can
    # warn at runtime.
    compare_fun = {:., meta, [Core, :compare?]}
    {compare_fun, meta, [module, op, left, right]}
  end
end
