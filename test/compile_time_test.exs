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

  test "including no comparison operators raises" do
    assert_raise(
      ArgumentError,
      ErrorMessage.invalid_expression(5),
      fn ->
        defmodule NoOperators do
          import CompareChain
          def fun, do: compare?(5)
        end
      end
    )
  end

  test "a non-comparison-or-combination at the root of the ast raises" do
    assert_raise(
      ArgumentError,
      ErrorMessage.invalid_expression(quote(do: abs(~D[2020-01-01] < ~D[2020-01-02]))),
      fn ->
        defmodule NestedCalls do
          import CompareChain
          def fun, do: compare?(abs(~D[2020-01-01] < ~D[2020-01-02]), Date)
        end
      end
    )
  end

  test "one branch of a combination failing to contain a comparison raises" do
    assert_raise(
      ArgumentError,
      ErrorMessage.invalid_expression(quote(do: 1 < 2 < 3 and true)),
      fn ->
        defmodule NestedCalls do
          import CompareChain
          def fun, do: compare?(1 < 2 < 3 and true)
        end
      end
    )
  end
end
