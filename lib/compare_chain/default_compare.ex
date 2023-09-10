defmodule CompareChain.DefaultCompare do
  @moduledoc false
  require Logger

  def compare(left, right) do
    if is_struct(left) or is_struct(right) do
      message = struct_warning_message(left, right)

      Logger.warning(message)
    end

    cond do
      left < right -> :lt
      left > right -> :gt
      left == right -> :eq
    end
  end

  defp struct_warning_message(%match{} = left, %match{} = right) do
    """
    Performing structural comparison on matching structs.

    Did you mean to use `compare?/2`?

      compare?(#{inspect(left)} ??? #{inspect(right)}, #{struct_string(left)})
    """
  end

  defp struct_warning_message(left, right) do
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
