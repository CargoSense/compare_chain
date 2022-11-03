defmodule CompareChain.DefaultCompare do
  def compare(left, right) do
    cond do
      left < right -> :lt
      left > right -> :gt
      left == right -> :eq
    end
  end
end
