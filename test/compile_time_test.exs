defmodule CompileTimeTest do
  # This module tests some compile-time behavior.
  #
  # The code in each test's `fun/0` won't compile, but that fact is hidden when
  # it's wrapped in a `defmodule`.
  #
  # Based on examples found in:
  # https://github.com/phoenixframework/phoenix/blob/master/test/phoenix/verified_routes_test.exs
  use ExUnit.Case

  alias CompareChain.ErrorMessage

  test "including no comparison operators raises at compile time" do
    assert_raise(ArgumentError, ErrorMessage.comparison_required(), fn ->
      defmodule NoOperators do
        import CompareChain
        def fun, do: compare?(5)
      end
    end)
  end

  test "nested calls to `compare?` raises at compile time" do
    assert_raise(ArgumentError, ErrorMessage.nested_not_allowed(), fn ->
      defmodule NestedCalls do
        import CompareChain
        def fun, do: compare?(compare?(~D[2020-01-01] < ~D[2020-01-02], Date) == true)
      end
    end)
  end
end
