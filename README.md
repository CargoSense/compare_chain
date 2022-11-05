# CompareChain

## Description

Provides convenience macros for comparisons which do:

  * chained comparisons like `a < b < c`
  * semantic comparisons using the structural operators `<`, `>`, `<=`, and `>=`
  * combinations using `and`, `or`, and `not`

### Examples

```elixir
iex> import CompareChain

# Chained comparisons
iex> compare?(1 < 2 < 3)
true

# Semantic comparisons
iex> compare?(~D[2017-03-31] < ~D[2017-04-01], Date)
true

# Semantic comparisons with logical operators
iex> compare?(~T[16:00:00] <= ~T[16:00:00] and not (~T[17:00:00] <= ~T[17:00:00]), Time)
false

# More complex expressions
iex> compare?(%{a: ~T[16:00:00]}.a <= ~T[17:00:00], Time)
true
```

## Installation

Add `compare_chain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:compare_chain, "~> 0.1.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/compare_chain>.

## Usage

Once installed, you can add

```elixir
import CompareChain
```

to your `defmodule` and you will have access to `compare?/1` and `compare?/2`.

## Background and motivation

Many languages provide syntactic sugar for chained comparisons.
For example in Python, `a < b < c` would be evaluated as `(a < b) and (b < c)`.

Elixir does not provide this.
Instead, `a < b < c` is evaluated as `(a < b) < c`.
Since `a < b` is a boolean, that's probably not what you want.

Further, operators like `<` do _structural_ comparison instead of _semantic_ comparison.
For most situations, you probably want to use `compare/2`.
From the [docs](https://hexdocs.pm/elixir/Kernel.html#module-structural-comparison):

<blockquote>
<details>

<summary>Show/Hide</summary>

The comparison functions in this module perform structural comparison.
This means structures are compared based on their representation and not on their semantic value.
This is specially important for functions that are meant to provide ordering, such as `>/2`, `</2`, `>=/2`, `<=/2`, `min/2`, and `max/2`.
For example:

```elixir
~D[2017-03-31] > ~D[2017-04-01]
```

will return true because structural comparison compares the `:day` field before `:month` or `:year`.
Therefore, when comparing structs, you often use the `compare/2` function made available by the structs modules themselves:

```elixir
iex> Date.compare(~D[2017-03-31], ~D[2017-04-01])
:lt
```

</details>
</blockquote>

The `compare/2` approach works well in many situations, but even moderately complicated logic can be cumbersome.
If we wanted the native equivalent of:

```elixir
iex> compare?(~D[2017-03-31] <= ~D[2017-04-01] < ~D[2017-04-02], Date)
```

we'd have to write:

```elixir
iex> Date.compare(~D[2017-03-31], ~D[2017-04-01]) != :gt and Date.compare(~D[2017-04-01]), ~D[2017-04-02]) == :lt
```

The goal of both `compare?/1` and `compare?/2` is to provide the syntactic sugar for chained comparisons.
With `compare?/2`, there is the added benefit of being able to use the structural comparison operators for semantic comparison.
