# CompareChain

**Chained semantic comparisons for Elixir.**

[![Package](https://img.shields.io/hexpm/v/compare_chain?logo=elixir&style=for-the-badge)](https://hex.pm/packages/compare_chain)
[![Downloads](https://img.shields.io/hexpm/dt/compare_chain?logo=elixir&style=for-the-badge)](https://hex.pm/packages/compare_chain)
[![Build](https://img.shields.io/github/actions/workflow/status/CargoSense/compare_chain/ci.yml?branch=main&logo=github&style=for-the-badge)](https://github.com/CargoSense/compare_chain/actions/workflows/ci.yml)

## Key Features

CompareChain provides convenience macros for comparisons like:

- chained comparisons (`a < b < c`)
- semantic comparisons using structural operators (`<`, `>`, `<=`, `>=`, `==`, `!=`, `===`, and `!==`)
- combinations (`and`, `or`, and `not`)

## Background

Say you have an interval of time bounded by two `%Date{}` structs, `start_date` and `end_date`, and you want to know whether or not a third `date` falls within that interval. How would you write this in Elixir?

```elixir
Date.compare(start_date, date) == :lt and
  Date.compare(date, end_date) == :lt
```

The above code is verbose, somewhat hard to read, and potentially incorrect (though not obviously so). What if `date` is considered "within" the interval inclusive of the `start_date` or `end_date`? To include the bounds in the comparison, you'd instead write the expression like this:

```elixir
Date.compare(start_date, date) != :gt and
  Date.compare(date, end_date) != :gt

# …or, terser but less performant:
Date.compare(start_date, date) in [:lt, :eq]
```

To spot the difference between these two cases, you must keep in mind:

- the order of the arguments passed to `Date.compare/2`,
- the specific comparison operators for each clause (`==` vs. `!=`), and
- the specific comparison atoms for each clause (`:lt` vs. `:gt`).

Contrast this example with how equivalent Python code:

```python
# excluding bounds
start_date < date < end_date

# including bounds
start_date <= date <= end_date
```

Much easier to read! Why can't you write this in Elixir? Two reasons:

1. Structural comparison operators
2. Chained vs. nested comparisons

### Structural Comparison Operators

Operators like `<` do _structural_ comparison (instead of _semantic_ comparison). From the [`Kernel` docs](https://hexdocs.pm/elixir/Kernel.html#module-structural-comparison):

> …**comparisons in Elixir are structural**, as it has the goal of comparing data types as efficiently as possible to create flexible and performant data structures. This distinction is specially important for functions that provide ordering, such as `>/2`, `</2`, `>=/2`, `<=/2`, `min/2`, and `max/2`. For example:
>
> ```elixir
> ~D[2017-03-31] > ~D[2017-04-01]
> ```
>
> will return `true` because structural comparison compares the `:day` field before `:month` or `:year`. In order to perform semantic comparisons, the relevant data-types provide a `compare/2` function, such as `Date.compare/2`:
>
> ```elixir
> iex> Date.compare(~D[2017-03-31], ~D[2017-04-01])
> :lt
> ```

In other words, although `~D[2017-03-31] > ~D[2017-04-01]` is valid code, it does _not_ tell you if `~D[2017-03-31]` is a later date than `~D[2017-04-01]` as you might expect.
Instead, you'd use `Date.compare/2`.

### Chained vs. Nested Comparisons

Additionally, even if `~D[2017-03-31] > ~D[2017-04-01]` did semantic comparison, you still couldn't write the interval check like you do in Python. In Python, an expression like `1 < 2 < 3` is syntactic sugar for `(1 < 2) and (2 < 3)` (a series of "chained" expressions).

Elixir doesn't provide an equivalent syntactic sugar. Instead, `1 < 2 < 3` is evaluated as `(1 < 2) < 3` (a series of "nested" expressions). `(1 < 2) < 3` evaluates to `true < 3` which is _probably_ not what you want!

### A Solution!

CompareChain addresses these complexities with the macro `CompareChain.compare?/2`:

```elixir
import CompareChain

# excluding bounds
compare?(start_date < date < end_date, Date)

# including bounds
compare?(start_date <= date <= end_date, Date)
```

`CompareChain.compare?/2` compiles these expressions as:

```elixir
# excluding bounds
Date.compare(start_date, date) == :lt and
  Date.compare(date, end_date) == :lt

# including bounds
Date.compare(start_date, date) != :gt and
  Date.compare(date, end_date) != :gt
```

Your code is more readable while remaining correct!

`CompareChain.compare?/1` also enables chained comparison using the structural operators:

```elixir
compare?(1 < 2 < 3)
```

## Installation

Add `compare_chain` to your project's dependencies in `mix.exs` and run `mix deps.get`:

```elixir
def deps do
  [
    {:compare_chain, "~> 0.5"}
  ]
end
```

## Usage

Import CompareChain to enable access to `CompareChain.compare?/1` and `CompareChain.compare?/2`:

```elixir
iex> import CompareChain

# Chained comparisons
iex> compare?(1 < 2 < 3)
true

# Semantic comparisons
iex> compare?(~D[2017-03-31] < ~D[2017-04-01], Date)
true

# Chained semantic comparisons
iex> compare?(~D[2017-03-31] < ~D[2017-04-01] < ~D[2017-04-02], Date)
true

# Semantic comparisons with logical operators
iex> compare?(~T[16:00:00] <= ~T[16:00:00] and not (~T[17:00:00] <= ~T[17:00:00]), Time)
false

# Complex expressions
iex> compare?(%{a: ~T[16:00:00]}.a <= ~T[17:00:00], Time)
true
```

<!--  -->

> ![TIP]
> See [CompareChain on HexDocs](https://hexdocs.pm/compare_chain) for more.

## Acknowledgements

Thanks to [Ben Wilson](https://github.com/benwilson512) and [Michael Crumm](https://github.com/mcrumm) for the helpful discussions and their guidance!

Thanks as well to the folks who participated in the [elixir-lang-core](https://groups.google.com/g/elixir-lang-core) discussion, particularly Cliff whose [idea](https://groups.google.com/g/elixir-lang-core/c/W2TeQm5r1H4/m/ctVuN_woBgAJ) I shamelessly built off.

## License

CompareChain is freely available under the [MIT License](https://opensource.org/licenses/MIT).
