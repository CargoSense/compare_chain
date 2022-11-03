defmodule CompareChainTest do
  use ExUnit.Case

  import CompareChain

  test "basic `compare?/1` examples" do
    assert compare?(1 < 2)
    assert compare?(1 < 2 < 3)
    refute compare?(1 >= 2)
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
