defmodule Sashite.Cell.Parser do
  @moduledoc """
  Secure parser for CELL coordinate strings.

  Designed for untrusted input: validates bounds first, parses character
  by character, and enforces strict constraints at every step.

  ## Letter Encoding

  CELL uses a bijective base-26 encoding for letter dimensions:

  - Single letter: `a-z` = 0-25
  - Double letter: `aa-iv` = 26-255 (offset of 26)

  This means `aa` is 26, not 0, ensuring each index maps to exactly one string.
  """

  alias Sashite.Cell.Coordinate

  @max_string_length Coordinate.max_string_length()
  @max_index_value Coordinate.max_index_value()
  @max_dimensions Coordinate.max_dimensions()

  @doc """
  Parses a CELL string into a coordinate tuple.

  Performs validation in order of computational cost:

  1. Type and length check (O(1) - immediate rejection of oversized input)
  2. First character check (O(1))
  3. Character-by-character parsing with bounds checking

  ## Examples

      iex> Sashite.Cell.Parser.parse("e4")
      {:ok, {4, 3}}

      iex> Sashite.Cell.Parser.parse("a1A")
      {:ok, {0, 0, 0}}

      iex> Sashite.Cell.Parser.parse("aa1")
      {:ok, {26, 0}}

      iex> Sashite.Cell.Parser.parse("iv256IV")
      {:ok, {255, 255, 255}}

      iex> Sashite.Cell.Parser.parse("")
      {:error, "empty input"}

      iex> Sashite.Cell.Parser.parse("a0")
      {:error, "leading zero"}
  """
  @spec parse(String.t()) :: {:ok, Coordinate.t()} | {:error, String.t()}
  def parse(input) when is_binary(input) do
    byte_size = byte_size(input)

    cond do
      byte_size == 0 ->
        {:error, "empty input"}

      byte_size > @max_string_length ->
        {:error, "input exceeds 7 characters"}

      true ->
        parse_first_char(input)
    end
  end

  def parse(_), do: {:error, "invalid input type"}

  @doc """
  Parses a CELL string, raising on error.

  ## Examples

      iex> Sashite.Cell.Parser.parse!("e4")
      {4, 3}

      iex> Sashite.Cell.Parser.parse!("aa1")
      {26, 0}
  """
  @spec parse!(String.t()) :: Coordinate.t()
  def parse!(input) do
    case parse(input) do
      {:ok, coordinate} -> coordinate
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  # --- Private Functions ---

  # Entry point: validate first character is lowercase
  defp parse_first_char(<<byte, rest::binary>>) do
    if lowercase?(byte) do
      parse_lowercase(rest, byte - ?a, 1, 1)
    else
      {:error, "must start with lowercase letter"}
    end
  end

  # --- Lowercase Letter Parsing (Dimensions 1, 4, 7, ...) ---

  # End of input while parsing lowercase letters
  defp parse_lowercase(<<>>, acc, letter_count, dims) when dims <= @max_dimensions do
    case finalize_letter_index(acc, letter_count) do
      {:ok, index} -> build_coordinate(dims, index, nil, nil)
      {:error, _} = error -> error
    end
  end

  # Continue parsing lowercase letters
  defp parse_lowercase(<<byte, rest::binary>>, acc, letter_count, dims)
       when dims <= @max_dimensions do
    cond do
      lowercase?(byte) ->
        continue_lowercase(rest, acc, byte, letter_count, dims)

      digit?(byte) ->
        transition_to_integer(rest, acc, byte, letter_count, dims)

      true ->
        {:error, "unexpected character"}
    end
  end

  defp parse_lowercase(_, _, _, _), do: {:error, "exceeds 3 dimensions"}

  # Accumulate another lowercase letter
  defp continue_lowercase(rest, acc, byte, letter_count, dims) do
    new_acc = acc * 26 + (byte - ?a)
    new_count = letter_count + 1

    # 3+ letters always exceed 255 (minimum 3-letter value is 702)
    if new_count > 2 do
      {:error, "index exceeds 255"}
    else
      parse_lowercase(rest, new_acc, new_count, dims)
    end
  end

  # Transition from lowercase letters to integer
  defp transition_to_integer(rest, acc, byte, letter_count, dims) do
    case finalize_letter_index(acc, letter_count) do
      {:ok, index} ->
        if byte == ?0 do
          {:error, "leading zero"}
        else
          parse_integer(rest, byte - ?0, dims + 1, index)
        end

      {:error, _} = error ->
        error
    end
  end

  # --- Integer Parsing (Dimensions 2, 5, 8, ...) ---

  # End of input while parsing integer
  defp parse_integer(<<>>, num_acc, dims, dim1_val) when dims <= @max_dimensions do
    rank_index = num_acc - 1

    if rank_index > @max_index_value do
      {:error, "index exceeds 255"}
    else
      build_coordinate(dims, dim1_val, rank_index, nil)
    end
  end

  # Continue parsing integer
  defp parse_integer(<<byte, rest::binary>>, num_acc, dims, dim1_val)
       when dims <= @max_dimensions do
    cond do
      digit?(byte) ->
        continue_integer(rest, num_acc, byte, dims, dim1_val)

      uppercase?(byte) ->
        transition_to_uppercase(rest, num_acc, byte, dims, dim1_val)

      true ->
        {:error, "unexpected character"}
    end
  end

  defp parse_integer(_, _, _, _), do: {:error, "exceeds 3 dimensions"}

  # Accumulate another digit
  defp continue_integer(rest, num_acc, byte, dims, dim1_val) do
    new_acc = num_acc * 10 + (byte - ?0)

    # Max valid rank is 256 (index 255), reject early if exceeded
    if new_acc > @max_index_value + 1 do
      {:error, "index exceeds 255"}
    else
      parse_integer(rest, new_acc, dims, dim1_val)
    end
  end

  # Transition from integer to uppercase letters
  defp transition_to_uppercase(rest, num_acc, byte, dims, dim1_val) do
    rank_index = num_acc - 1

    if rank_index > @max_index_value do
      {:error, "index exceeds 255"}
    else
      parse_uppercase(rest, byte - ?A, 1, dims + 1, dim1_val, rank_index)
    end
  end

  # --- Uppercase Letter Parsing (Dimensions 3, 6, 9, ...) ---

  # End of input while parsing uppercase letters
  defp parse_uppercase(<<>>, acc, letter_count, dims, dim1_val, dim2_val)
       when dims <= @max_dimensions do
    case finalize_letter_index(acc, letter_count) do
      {:ok, index} -> build_coordinate(dims, dim1_val, dim2_val, index)
      {:error, _} = error -> error
    end
  end

  # Continue parsing uppercase letters
  defp parse_uppercase(<<byte, rest::binary>>, acc, letter_count, dims, dim1_val, dim2_val)
       when dims <= @max_dimensions do
    cond do
      uppercase?(byte) ->
        continue_uppercase(rest, acc, byte, letter_count, dims, dim1_val, dim2_val)

      lowercase?(byte) ->
        # Would start dimension 4, which exceeds our limit
        {:error, "exceeds 3 dimensions"}

      true ->
        {:error, "unexpected character"}
    end
  end

  defp parse_uppercase(_, _, _, _, _, _), do: {:error, "exceeds 3 dimensions"}

  # Accumulate another uppercase letter
  defp continue_uppercase(rest, acc, byte, letter_count, dims, dim1_val, dim2_val) do
    new_acc = acc * 26 + (byte - ?A)
    new_count = letter_count + 1

    # 3+ letters always exceed 255
    if new_count > 2 do
      {:error, "index exceeds 255"}
    else
      parse_uppercase(rest, new_acc, new_count, dims, dim1_val, dim2_val)
    end
  end

  # --- Helper Functions ---

  # Convert accumulated letter value to final index with offset
  # Single letter: a=0, b=1, ..., z=25 (always valid, max is 25)
  # Double letter: aa=26, ab=27, ..., iv=255 (need to check bounds)
  defp finalize_letter_index(acc, 1), do: {:ok, acc}

  defp finalize_letter_index(acc, 2) do
    index = 26 + acc

    if index > @max_index_value do
      {:error, "index exceeds 255"}
    else
      {:ok, index}
    end
  end

  # Build the final coordinate tuple
  defp build_coordinate(1, dim1, nil, nil), do: {:ok, {dim1}}
  defp build_coordinate(2, dim1, dim2, nil), do: {:ok, {dim1, dim2}}
  defp build_coordinate(3, dim1, dim2, dim3), do: {:ok, {dim1, dim2, dim3}}

  # Character class predicates (inlined for performance)
  defp lowercase?(byte), do: byte >= ?a and byte <= ?z
  defp uppercase?(byte), do: byte >= ?A and byte <= ?Z
  defp digit?(byte), do: byte >= ?0 and byte <= ?9
end
