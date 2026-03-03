defmodule Sashite.Cell.Formatter do
  @moduledoc false

  # Formats coordinate tuples into CELL strings.
  #
  # Converts validated coordinate indices back to the canonical CELL
  # string representation using direct binary construction.
  #
  # Letter dimensions use bijective base-26 encoding:
  #   - 0-25  → single letter (a-z or A-Z)
  #   - 26-255 → double letter (aa-iv or AA-IV)
  #
  # Integer dimensions are 1-indexed: index 0 → "1", index 255 → "256".
  #
  # Time complexity: O(1) — bounded output size (max 7 bytes).
  # Space complexity: O(1) — single binary allocation via iodata.

  @max_index_value 255

  # ── Public API ────────────────────────────────────────────────────────

  @doc false
  @spec format(tuple()) :: {:ok, String.t()} | {:error, atom()}

  # 1D: lowercase only
  def format({dim1}) when is_integer(dim1) and dim1 >= 0 and dim1 <= @max_index_value do
    {:ok, encode_lowercase(dim1)}
  end

  # 2D: lowercase + integer
  def format({dim1, dim2})
      when is_integer(dim1) and dim1 >= 0 and dim1 <= @max_index_value and
             is_integer(dim2) and dim2 >= 0 and dim2 <= @max_index_value do
    {:ok, IO.iodata_to_binary([encode_lowercase(dim1), encode_integer(dim2)])}
  end

  # 3D: lowercase + integer + uppercase
  def format({dim1, dim2, dim3})
      when is_integer(dim1) and dim1 >= 0 and dim1 <= @max_index_value and
             is_integer(dim2) and dim2 >= 0 and dim2 <= @max_index_value and
             is_integer(dim3) and dim3 >= 0 and dim3 <= @max_index_value do
    {:ok,
     IO.iodata_to_binary([encode_lowercase(dim1), encode_integer(dim2), encode_uppercase(dim3)])}
  end

  # Tuple with 1-3 elements but invalid index values
  def format(tuple)
      when is_tuple(tuple) and tuple_size(tuple) >= 1 and tuple_size(tuple) <= 3 do
    {:error, :index_out_of_range}
  end

  # Tuple with wrong arity
  def format(tuple) when is_tuple(tuple) do
    {:error, :invalid_dimensions}
  end

  # Not a tuple
  def format(_), do: {:error, :not_a_tuple}

  @doc false
  @spec format!(tuple()) :: String.t()
  def format!(tuple) do
    case format(tuple) do
      {:ok, string} -> string
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  # ── Lowercase letter encoding (dimension 1) ──────────────────────────
  #
  # Single letter: 0-25 → "a"-"z"
  # Double letter: 26-255 → "aa"-"iv"

  defp encode_lowercase(value) when value <= 25 do
    <<value + ?a>>
  end

  defp encode_lowercase(value) do
    offset = value - 26
    <<div(offset, 26) + ?a, rem(offset, 26) + ?a>>
  end

  # ── Uppercase letter encoding (dimension 3) ──────────────────────────
  #
  # Single letter: 0-25 → "A"-"Z"
  # Double letter: 26-255 → "AA"-"IV"

  defp encode_uppercase(value) when value <= 25 do
    <<value + ?A>>
  end

  defp encode_uppercase(value) do
    offset = value - 26
    <<div(offset, 26) + ?A, rem(offset, 26) + ?A>>
  end

  # ── Integer encoding (dimension 2) ───────────────────────────────────
  #
  # Converts a 0-indexed value to a 1-indexed string: 0 → "1", 255 → "256".
  # Direct digit construction avoids Integer.to_string/1 overhead.

  defp encode_integer(index) when index < 9 do
    <<index + ?1>>
  end

  defp encode_integer(index) when index < 99 do
    value = index + 1
    <<div(value, 10) + ?0, rem(value, 10) + ?0>>
  end

  defp encode_integer(index) do
    value = index + 1
    <<div(value, 100) + ?0, rem(div(value, 10), 10) + ?0, rem(value, 10) + ?0>>
  end
end
