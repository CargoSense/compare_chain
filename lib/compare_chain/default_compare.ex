defmodule CompareChain.DefaultCompare do
  @moduledoc false

  alias CompareChain.ErrorMessage

  require Logger

  def compare(left, right) do
    if is_struct(left) or is_struct(right) do
      message = ErrorMessage.struct_warning(left, right)
      Logger.warning(message)
    end

    cond do
      left < right -> :lt
      left > right -> :gt
      left == right -> :eq
    end
  end
end
