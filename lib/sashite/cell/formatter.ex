defmodule Sashite.Cell.Formatter do
  @moduledoc """
  Formats coordinate tuples into CELL strings.

  Converts validated coordinate indices back to the canonical CELL
  string representation.

  ## Letter Encoding

  CELL uses a bijective base-26 encoding for letter dimensions:

  - Single letter: 0-25 → `a-z` (lowercase) or `A-Z` (uppercase)
  - Double letter: 26-255 → `aa-iv` (lowercase) or `AA-IV` (uppercase)

  This ensures each index maps to exactly one canonical string.
  """

  alias Sashite.Cell.Coordinate

  import Coordinate, only: [is_valid_index: 1]

  # --- Public API ---

  @doc """
  Formats a coordinate tuple into a CELL string.

  Returns `{:ok, string}` on success, or `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Cell.Formatter.format({4, 3})
      {:ok, "e4"}

      iex> Sashite.Cell.Formatter.format({0, 0, 0})
      {:ok, "a1A"}

      iex> Sashite.Cell.Formatter.format({26, 0})
      {:ok, "aa1"}

      iex> Sashite.Cell.Formatter.format({255, 255, 255})
      {:ok, "iv256IV"}

      iex> Sashite.Cell.Formatter.format({256, 0})
      {:error, "index exceeds 255"}

      iex> Sashite.Cell.Formatter.format({})
      {:error, "invalid dimensions"}
  """
  @spec format(tuple()) :: {:ok, String.t()} | {:error, String.t()}
  def format({dim1}) when is_valid_index(dim1) do
    {:ok, encode_lowercase(dim1)}
  end

  def format({dim1, dim2}) when is_valid_index(dim1) and is_valid_index(dim2) do
    {:ok, encode_lowercase(dim1) <> encode_integer(dim2)}
  end

  def format({dim1, dim2, dim3})
      when is_valid_index(dim1) and is_valid_index(dim2) and is_valid_index(dim3) do
    {:ok, encode_lowercase(dim1) <> encode_integer(dim2) <> encode_uppercase(dim3)}
  end

  def format(tuple) when is_tuple(tuple) and tuple_size(tuple) >= 1 and tuple_size(tuple) <= 3 do
    {:error, "index exceeds 255"}
  end

  def format(tuple) when is_tuple(tuple) do
    {:error, "invalid dimensions"}
  end

  def format(_), do: {:error, "invalid coordinate"}

  @doc """
  Formats a coordinate tuple, raising `ArgumentError` on error.

  ## Examples

      iex> Sashite.Cell.Formatter.format!({4, 3})
      "e4"

      iex> Sashite.Cell.Formatter.format!({26, 0})
      "aa1"

      iex> Sashite.Cell.Formatter.format!({255, 255, 255})
      "iv256IV"
  """
  @spec format!(tuple()) :: String.t()
  def format!(tuple) do
    case format(tuple) do
      {:ok, string} -> string
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  # --- Private Encoding Functions ---

  # Encode a 0-indexed value as lowercase letters
  # Single letter: a=0, b=1, ..., z=25
  # Double letter: aa=26, ab=27, ..., az=51, ba=52, ..., iv=255
  defp encode_lowercase(value) when value <= 25 do
    <<(?a + value)>>
  end

  defp encode_lowercase(value) do
    offset = value - 26
    first = div(offset, 26)
    second = rem(offset, 26)
    <<(?a + first), (?a + second)>>
  end

  # Encode a 0-indexed value as uppercase letters
  # Single letter: A=0, B=1, ..., Z=25
  # Double letter: AA=26, AB=27, ..., AZ=51, BA=52, ..., IV=255
  defp encode_uppercase(value) when value <= 25 do
    <<(?A + value)>>
  end

  defp encode_uppercase(value) do
    offset = value - 26
    first = div(offset, 26)
    second = rem(offset, 26)
    <<(?A + first), (?A + second)>>
  end

  # Encode a 0-indexed rank as a 1-indexed positive integer string
  # 0 → "1", 1 → "2", ..., 255 → "256"
  defp encode_integer(index) do
    Integer.to_string(index + 1)
  end
end
