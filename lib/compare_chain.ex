defmodule CompareChain do
  defmacro compare?(expr) do
    ast = quote(do: unquote(expr))
    do_compare?(ast, CompareChain.DefaultCompare)
  end

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
    # Build a stack of `and`s and `or`s.
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
        chain(node, module)

      {c, meta, node}, acc ->
        {c, meta, [acc, chain(node, module)]}
    end)
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
  #      and
  #     /   \
  # true   and
  #       /   \
  #      ~     ~
  #     / \   / \
  #    a   b b   c
  # ```
  #
  # where `~` is roughly `compare(left, right) == :lt`.
  # The dangling `true` is just to make the reduce simpler.
  defp chain(ast, module) do
    ast
    |> Macro.prewalker()
    |> Enum.reduce_while([], fn
      {op, _, [_left, right]}, acc when op in [:<, :>, :<=, :>=] ->
        {:cont, [{op, right} | acc]}

      node, acc ->
        {:halt, [{nil, node} | acc]}
    end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(true, fn [{_, left}, {op, right}], acc ->
      {kernel_fun, evals_to} =
        case op do
          :< -> {:==, :lt}
          :> -> {:==, :gt}
          :<= -> {:!=, :gt}
          :>= -> {:!=, :lt}
        end

      comparison =
        quote do
          unquote(module).compare(unquote(left), unquote(right))
        end

      quote do
        unquote(acc) and Kernel.unquote(kernel_fun)(unquote(comparison), unquote(evals_to))
      end
    end)
  end
end
