defmodule CompareChain.ErrorMessage do
  # This module is public for testing.
  @moduledoc false

  @doc false
  def invalid_expression(ast) do
    """
    The following expression is an invalid argument to `compare?/{1,2}`:

        #{Macro.to_string(ast)}

    There are three ways this might happen:

      * No comparison operators found - at least one of these must be included:

          `<`, `>`, `<=`, `>=`, `==`, `!=`, `===`, or `!===`

      * An operator that isn't a comparison or a combination was found at the
        root of the expression. For example:

          compare?(my_function(a < b), Date)

        This expression is invalid because `compare?/2` cannot guarantee the
        return of `my_function` will be a boolean. This expression can be
        refactored to be valid like so:

          my_function(compare?(a < b, Date))

      * One branch of a combination failed to contain a comparison. For example,
        this is valid:

          compare(1 < 2 < 3 and 4 < 5)

        but this is not:

          compare?(1 < 2 < 3 and true)

        because the right side of `and` fails to contain a comparison. This
        expression can be refactored to be valid like so:

          compare?(1 < 2 < 3) and true
    """
  end

  def strict_operator_warning do
    """
    Performing semantic comparison using either: `===` or `!===`.
    This is reinterpreted as `==` or `!=`, respectively.
    """
  end

  @doc false
  def struct_warning(operator, %match{} = left, %match{} = right) do
    """
    Performing structural comparison on matching structs.

    Did you mean to use `compare?/2`?

      compare?(#{inspect(left)} #{operator} #{inspect(right)}, #{struct_string(left)})
    """
  end

  @doc false
  def struct_warning(_operator, left, right) do
    """
    Performing structural comparison on one or more mismatched structs.

    Left#{if(is_struct(left), do: " (%#{struct_string(left)}{} struct)", else: "")}:

      #{inspect(left)}

    Right#{if(is_struct(right), do: " (%#{struct_string(right)}{} struct)", else: "")}:

      #{inspect(right)}
    """
  end

  defp struct_string(%s{}), do: s |> Atom.to_string() |> String.replace_leading("Elixir.", "")
end
