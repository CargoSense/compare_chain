defmodule CompareChain do
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))

    ast
    |> Macro.prewalker()
    |> Enum.reduce_while([], fn
      {c, meta, [_left, right]}, acc when c in [:and, :or] ->
        {:cont, [{c, meta, right} | acc]}

      node, acc ->
        {:halt, [{nil, nil, node} | acc]}
    end)
    |> Enum.reduce(nil, fn
      {nil, nil, node}, nil ->
        chain(node, module)

      {c, meta, node}, acc ->
        {c, meta, [acc, chain(node, module)]}
    end)
  end

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
