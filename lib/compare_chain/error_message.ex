defmodule CompareChain.ErrorMessage do
  # This module is public for testing.
  @moduledoc false

  @doc false
  def comparison_required do
    """
    No comparison operators found.
    Expression must include at least one of `<`, `>`, `<=`, `>=`, `==`, or `!=`.
    """
  end

  @doc false
  def nested_not_allowed do
    "Cannot use `compare?` within a call to `compare?`."
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
