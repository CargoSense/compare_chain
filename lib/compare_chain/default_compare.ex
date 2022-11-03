defmodule CompareChain.DefaultCompare do
  @moduledoc false
  def compare(left, right) do
    cond do
      left < right -> :lt
      left > right -> :gt
      left == right -> :eq
    end
  end
end
