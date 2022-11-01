defmodule CompareChain do
  @valid_ops [:<, :>, :<=, :>=]
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))

    ast
    |> Macro.prewalker()
    |> Enum.reduce_while([], fn
      {op, _, [_left, right]}, acc when op in @valid_ops ->
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

  def run() do
    a = ~U[2020-01-01 00:00:00Z]
    b = ~U[2021-01-01 00:00:00Z]
    c = ~U[2022-01-01 00:00:00Z]
    d = ~U[2023-01-01 00:00:00Z]

    # # true
    compare?(a < b <= c, DateTime) |> IO.inspect()

    # false
    compare?(%{b: b}[:b] >= d, DateTime) |> IO.inspect()

    :ok
  end
end
