defmodule CompileTimeTest do
  # This module tests some compile-time behavior.
  #
  # The code in each test's `fun/0` won't compile, but that fact is hidden when
  # it's wrapped in a `defmodule`.
  #
  # Based on examples found in:
  # https://github.com/phoenixframework/phoenix/blob/master/test/phoenix/verified_routes_test.exs
  use ExUnit.Case

  import CompareChain.ErrorMessage

  test "including no comparison operators raises at compile time" do
    assert_raise(ArgumentError, chain_error_message(), fn ->
      defmodule NoOperators do
        import CompareChain
        def fun, do: compare?(5)
      end
    end)
  end

  test "including not in message raises at compile time" do
    assert_raise(ArgumentError, raise_on_not_message(), fn ->
      defmodule Not do
        import CompareChain
        def fun, do: compare?(not (1 > 2))
      end
    end)
  end
end
