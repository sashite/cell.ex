defmodule SashiteCell do
  @moduledoc """
  Top-level entry point for the sashite_cell library.

  All functionality is provided by `Sashite.Cell`. This module exists
  for discoverability and to follow Elixir naming conventions.

  See `Sashite.Cell` for documentation and examples.
  """

  defdelegate to_indices(string), to: Sashite.Cell
  defdelegate to_indices!(string), to: Sashite.Cell
  defdelegate from_indices(indices), to: Sashite.Cell
  defdelegate from_indices!(indices), to: Sashite.Cell
  defdelegate valid?(string), to: Sashite.Cell
  defdelegate max_dimensions(), to: Sashite.Cell
  defdelegate max_index_value(), to: Sashite.Cell
  defdelegate max_string_length(), to: Sashite.Cell
end
