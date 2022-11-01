defmodule CompareChain do
  @valid_ops [:<, :>, :<=, :>=]
  defmacro compare?(expr, module) do
    ast = quote(do: unquote(expr))

    %{pairs: pairs} =
      ast
      |> Macro.postwalker()
      |> Enum.reduce(%{pairs: [], prev: []}, fn
        {op, _, _}, %{pairs: pairs, prev: [b, a]} = acc when op in @valid_ops ->
          %{acc | pairs: [{op, a, b} | pairs], prev: [b]}

        {_, _, nil} = var, %{prev: prev} = acc ->
          %{acc | prev: [var | prev]}
      end)

    pairs
    |> Enum.map(fn {op, a, b} ->
      {compare, result} =
        case op do
          :< -> {:==, :lt}
          :> -> {:==, :gt}
          :<= -> {:!=, :gt}
          :>= -> {:!=, :lt}
        end

      quote do
        Kernel.unquote(compare)(unquote(module).compare(unquote(a), unquote(b)), unquote(result))
      end
    end)
    |> Enum.reduce(true, fn expr, acc ->
      quote do
        unquote(expr) and unquote(acc)
      end
    end)
  end

  def run() do
    a = ~U[2020-01-01 00:00:00Z]
    b = ~U[2021-01-01 00:00:00Z]
    c = ~U[2022-01-01 00:00:00Z]

    # true
    compare?(a < b <= c, DateTime) |> IO.inspect()

    # false
    compare?(a >= b, DateTime) |> IO.inspect()
  end
end
