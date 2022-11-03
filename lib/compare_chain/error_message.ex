defmodule CompareChain.ErrorMessage do
  @moduledoc false

  # Public for testing
  @doc false
  def chain_error_message() do
    """
    No comparison operators found.
    Expression must include at least one of `<`, `>`, `<=`, or `>=`.
    """
  end

  # Public for testing
  @doc false
  def raise_on_not_message() do
    """
    Expression may not include unary `not` operator.
    Consider using negation rules, e.g.
    `not (a < b)` becomes `a >= b`.
    """
  end
end
