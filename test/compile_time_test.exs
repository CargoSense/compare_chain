defmodule CompileTimeTest do
  use ExUnit.Case

  import CompareChain.ErrorMessage
  import CompileTimeAssertions

  test "including no comparison operators raises at compile time" do
    assert_compile_time_raise(ArgumentError, chain_error_message(), fn ->
      import CompareChain
      compare?(5)
    end)
  end

  test "including not in message raises at compile time" do
    assert_compile_time_raise(ArgumentError, raise_on_not_message(), fn ->
      import CompareChain
      compare?(not (1 > 2))
    end)
  end
end
