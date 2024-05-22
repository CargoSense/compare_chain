defmodule CompareChain.ErrorMessage do
  # This module is public for testing.
  @moduledoc false

  @doc false
  def invalid_expression(ast) do
    """
    The following expression is an invalid argument to `compare?/{1,2}`:

        #{Macro.to_string(ast)}

    Valid expressions follow these three rules:

      1. A comparison operator like `<` must be present.
      2. All arguments to boolean operators must also be valid expressions.
      3. The root operator of an expression must be a comparison or a boolean.

    So at least one of these rules is not satisfied by the expression. See the
    moduledoc for `CompareChain` for more details including refactoring hints.
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
