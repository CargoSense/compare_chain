# CompareChain

## Description

Provides convenience macros for comparisons which do:

  * chained comparisons like: `a < b < c`
  * semantic comparisons using the structural operators: `<`, `>`, `<=`, `>=`, `==`, `!=`, `===`, and `!==`
  * combinations using: `and`, `or`, and `not`

### Examples

```elixir
iex> import CompareChain

# Chained comparisons
iex> compare?(1 < 2 < 3)
true

# Semantic comparisons
iex> compare?(~D[2017-03-31] < ~D[2017-04-01], Date)
true

# Chained, semantic comparisons
iex> compare?(~D[2017-03-31] < ~D[2017-04-01] < ~D[2017-04-02], Date)
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
    {:compare_chain, "~> 0.5"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/compare_chain>.

## Usage

Once installed, you can add:

```elixir
import CompareChain
```

to your `defmodule` and you will have access to `CompareChain.compare?/1` and `CompareChain.compare?/2`.

## Background and motivation

`CompareChain` was originally motivated by the following situation:

> You have an interval of time bounded by a two `%Date{}` structs: `start_date` and `end_date`.
> You want to know if some third `date` falls in that interval.
> How do you write this?

In Elixir, we'd write this as follows:

```elixir
Date.compare(start_date, date) == :lt and
  Date.compare(date, end_date) == :lt
```

This is verbose and therefore a little hard to read.
It's also potentially incorrect, though not obviously so.
What if `date` is considered "within" the interval even if it equals `start_date` or `end_date`?
To include the bounds in our comparison, we'd instead write the expression like this:

```elixir
Date.compare(start_date, date) != :gt and
  Date.compare(date, end_date) != :gt
```

(We could have written `Date.compare(start_date, date) in [:lt, :eq]`, but `!= :gt` is faster.)

In order to spot the difference between these two cases, you have to keep several things in mind:

  * The order of the arguments passed to `Date.compare/2`
  * The specific comparison operators for each clause: `==` vs. `!=`
  * The specific comparison atoms for each clause: `:lt` vs. `:gt`

Since this is hard to read, it's easy to introduce bugs.
Contrast this with how you'd write the equivalent code in Python:

```
start_date <  date <  end_date # excluding bounds
start_date <= date <= end_date # including bounds
```

This is much easier to read.
So why can't we write this in Elixir?
Two reasons:

  * Structural comparison operators
  * Chained vs. nested comparisons

### Structural comparison operators

Operators like `<` do _structural_ comparison instead of _semantic_ comparison.
From the [`Kernel` docs](https://hexdocs.pm/elixir/Kernel.html#module-structural-comparison):

> ... **comparisons in Elixir are structural**, as it has the goal
  of comparing data types as efficiently as possible to create flexible
  and performant data structures. This distinction is specially important
  for functions that provide ordering, such as `>/2`, `</2`, `>=/2`,
  `<=/2`, `min/2`, and `max/2`. For example:
>
> ```elixir
> ~D[2017-03-31] > ~D[2017-04-01]
> ```
>
> will return `true` because structural comparison compares the `:day`
  field before `:month` or `:year`. In order to perform semantic comparisons,
  the relevant data-types provide a `compare/2` function, such as
  `Date.compare/2`:
>
> ```elixir
> iex> Date.compare(~D[2017-03-31], ~D[2017-04-01])
> :lt
> ```

In other words, although `~D[2017-03-31] > ~D[2017-04-01]` is perfectly valid code, it does _not_ tell you if `~D[2017-03-31]` is a later date than `~D[2017-04-01]` like you might expect.
Instead, you need to use `Date.compare/2`.

### Chained vs. nested comparisons

Additionally, even if `~D[2017-03-31] > ~D[2017-04-01]` did do semantic comparison, you still couldn't write the interval check like you do in Python.
This is because in Python, an expression like `1 < 2 < 3` is syntactic sugar for `(1 < 2) and (2 < 3)`, aka a series of "chained" expressions.

Elixir does not provide an equivalent syntactic sugar.
Instead, `1 < 2 < 3` is evaluated as `(1 < 2) < 3`, aka a series of "nested" expressions.
Since `(1 < 2) < 3` simplifies to `true < 3`, that's probably not what you want!

Elixir will even warn you when you attempt an expression like that:

> warning: Elixir does not support nested comparisons. Something like
>
>      x < y < z
>
> is equivalent to
>
>      (x < y) < z
>
> which ultimately compares z with the boolean result of (x < y). Instead, consider joining together each comparison segment with an "and", for example,
>
>      x < y and y < z

### CompareChain

`CompareChain` attempts to address both of these issues with the macro `CompareChain.compare?/2`.
Its job is to take code similar to how you'd like to write it and rewriting it to be semantically correct.

For our motivating example, we'd write this:

```elixir
import CompareChain
compare?(start_date <  date <  end_date, Date) # excluding bounds
compare?(start_date <= date <= end_date, Date) # including bounds
```

And at compile time, `CompareChain.compare?/2` rewrites those to be:

```elixir
# excluding bounds
Date.compare(start_date, date) == :lt and
  Date.compare(date, end_date) == :lt

# including bounds
Date.compare(start_date, date) != :gt and
  Date.compare(date, end_date) != :gt
```

This way your code is more readable while still remaining correct.

`CompareChain.compare?/1` is also available in case you only need chained comparison using the structural operators:

```elixir
compare?(1 < 2 < 3)
```

Though I find this case comes up less often.

### One last selling point

As a happy accident, `CompareChain.compare?/2` always uses fewer characters than its `compare/2` counterpart:

```elixir
compare?(a <= b, Date)
# vs.
Date.compare(a, b) != :gt
```

(Assuming you've already included `import CompareChain`, of course!)

Because it's shorter _and_ more readable, these days I always use `CompareChain` for any semantic comparison, chained or not.