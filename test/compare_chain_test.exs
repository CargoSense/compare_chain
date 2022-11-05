defmodule CompareChainTest do
  use ExUnit.Case

  doctest CompareChain

  import CompareChain

  test "comparison on incompatible structs raises" do
    # Finding the expected error message this way seems a bit brittle.
    stacktrace =
      try do
        Date.compare(~D[2022-01-01], ~T[00:00:00]) == :lt
      rescue
        err -> Exception.format(:error, err, __STACKTRACE__)
      end

    "** (MatchError) " <> message = stacktrace |> String.split("\n") |> List.first()

    assert_raise(MatchError, message, fn ->
      compare?(~D[2022-01-01] < ~T[00:00:00], Date)
    end)
  end

  test "basic `compare?/2` examples" do
    a = ~U[2020-01-01 00:00:00Z]
    b = ~U[2021-01-01 00:00:00Z]
    c = ~U[2022-01-01 00:00:00Z]
    d = ~U[2023-01-01 00:00:00Z]

    assert compare?(a < b <= c, DateTime)
    refute compare?(%{val: b}.val >= d, DateTime)
    assert compare?(a > b or c < d, DateTime)
    refute compare?(a > b and c < d, DateTime)
  end
end
