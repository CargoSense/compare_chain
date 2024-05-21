defmodule CompareChain.Core do
  @moduledoc false

  alias CompareChain.ErrorMessage

  require Logger

  @doc false
  def compare?(Kernel, operator, left, right) do
    if is_struct(left) or is_struct(right) do
      message = ErrorMessage.struct_warning(operator, left, right)
      Logger.warning(message)
    end

    apply(Kernel, operator, [left, right])
  end

  def compare?(module, operator, left, right) when is_atom(module) do
    if operator == :=== or operator == :!== do
      message = ErrorMessage.strict_operator_warning()
      Logger.warning(message)
    end

    {kernel_fun, evals_to} =
      case operator do
        :< -> {:==, :lt}
        :> -> {:==, :gt}
        :<= -> {:!=, :gt}
        :>= -> {:!=, :lt}
        :== -> {:==, :eq}
        :!= -> {:!=, :eq}
        :=== -> {:==, :eq}
        :!== -> {:!=, :eq}
      end

    comparison = apply(module, :compare, [left, right])
    apply(Kernel, kernel_fun, [comparison, evals_to])
  end
end
