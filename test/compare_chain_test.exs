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

  test "compare?/1 with mismatched structs raises warning" do
    warning_message =
      ExUnit.CaptureLog.capture_log(fn ->
        compare?(~D[2022-01-02] < ~T[00:00:00])
      end)

    assert warning_message =~ """
           Performing structural comparison on one or more mismatched structs.

           Left (%Date{} struct):

             ~D[2022-01-02]

           Right (%Time{} struct):

             ~T[00:00:00]
           """
  end

  test "compare?/1 with matching structs raises warning with a hint" do
    warning_message =
      ExUnit.CaptureLog.capture_log(fn ->
        compare?(~D[2022-01-02] < ~D[2022-02-01])
      end)

    assert warning_message =~ """
           [warning] Performing structural comparison on matching structs.

           Did you mean to use `compare?/2`?

             compare?(~D[2022-01-02] ??? ~D[2022-02-01], Date)
           """
  end

  test "works with boolean literals" do
    assert compare?((true and 1 < 2) or false)
  end

  test "works with `==` and `!=`" do
    assert compare?(~T[00:00:00] == ~T[00:00:00], Time)
    refute compare?(~T[00:00:00] == ~T[11:11:11], Time)
    refute compare?(~T[00:00:00] != ~T[00:00:00], Time)
    assert compare?(~T[00:00:00] != ~T[11:11:11], Time)
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

  test "nested nots" do
    assert compare?(
             ~D[2020-01-01] > ~D[2020-01-02] or
               (not (not (not (not (~D[2020-01-01] < ~D[2020-01-02])))) and
                  not (not (~D[2020-01-01] < ~D[2020-01-02]))) or
               not (~D[2020-01-01] < ~D[2020-01-02]),
             Date
           )
  end
end
