defmodule CompareChain.ErrorMessage do
  @moduledoc false

  # Public for testing
  @doc false
  def chain_error_message() do
    """
    No comparison operators found.
    Expression must include at least one of `<`, `>`, `<=`, `>=`, `==`, or `!=`.
    """
  end
end
