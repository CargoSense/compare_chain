defmodule CompareChain.Core do
  @moduledoc false

  alias CompareChain.ErrorMessage

  require Logger

  def compare(operator, left, right) do
    if is_struct(left) or is_struct(right) do
      message = ErrorMessage.struct_warning(operator, left, right)
      Logger.warning(message)
    end

    apply(Kernel, operator, [left, right])
  end

  def compare(module, operator, left, right) when is_atom(module) and module != Kernel do
    if operator == :=== or operator == :!== do
      message = ErrorMessage.strict_operator_warning()
      Logger.warning(message)
    end

    apply(module, :compare, [left, right])
  end
end
