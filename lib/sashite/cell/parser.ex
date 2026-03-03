defmodule Sashite.Cell.Parser do
  @moduledoc false

  # Secure parser for CELL coordinate strings.
  #
  # Designed for untrusted input: validates bounds first, then parses
  # character by character using binary pattern matching with guards.
  #
  # Letter dimensions use bijective base-26 encoding:
  #   - Single letter: a=0, b=1, ..., z=25
  #   - Double letter: aa=26, ab=27, ..., iv=255
  #
  # Integer dimensions are 1-indexed: "1"=0, "2"=1, ..., "256"=255.
  #
  # Time complexity: O(n) where n ≤ 7 (bounded by max_string_length).
  # Space complexity: O(1) — integer accumulators only, no intermediate allocations.

  @max_string_length 7
  @max_index_value 255

  # ── Public API ────────────────────────────────────────────────────────

  @doc false
  @spec parse(String.t()) :: {:ok, tuple()} | {:error, atom()}
  def parse(<<>>), do: {:error, :empty_input}

  def parse(input) when is_binary(input) do
    if byte_size(input) > @max_string_length do
      {:error, :input_too_long}
    else
      parse_lowercase_first(input)
    end
  end

  def parse(_), do: {:error, :not_a_string}

  @doc false
  @spec parse!(String.t()) :: tuple()
  def parse!(input) do
    case parse(input) do
      {:ok, coordinate} -> coordinate
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  # ── Dimension 1: lowercase letters ────────────────────────────────────
  #
  # Entry point. The first byte must be a lowercase letter.
  # Accumulates a bijective base-26 value across 1 or 2 letters.

  defp parse_lowercase_first(<<byte, rest::binary>>) when byte in ?a..?z do
    parse_lowercase_cont(rest, byte - ?a, 1)
  end

  defp parse_lowercase_first(_), do: {:error, :must_start_with_lowercase}

  # End of input after lowercase letters → 1D coordinate
  defp parse_lowercase_cont(<<>>, acc, letter_count) do
    finalize_letter_index(acc, letter_count, &finish_1d/1)
  end

  # Second lowercase letter
  defp parse_lowercase_cont(<<byte, rest::binary>>, acc, 1) when byte in ?a..?z do
    parse_lowercase_cont(rest, acc * 26 + (byte - ?a), 2)
  end

  # Third lowercase letter → always exceeds 255 (minimum 3-letter value is 702)
  defp parse_lowercase_cont(<<byte, _::binary>>, _acc, 2) when byte in ?a..?z do
    {:error, :index_out_of_range}
  end

  # Transition to dimension 2: digit after lowercase letters
  defp parse_lowercase_cont(<<byte, rest::binary>>, acc, letter_count) when byte in ?1..?9 do
    finalize_letter_index(acc, letter_count, fn dim1 ->
      parse_integer(rest, byte - ?0, dim1)
    end)
  end

  # Leading zero
  defp parse_lowercase_cont(<<?0, _::binary>>, _acc, _letter_count) do
    {:error, :leading_zero}
  end

  # Any other character
  defp parse_lowercase_cont(_, _acc, _letter_count) do
    {:error, :unexpected_character}
  end

  # ── Dimension 2: positive integer ─────────────────────────────────────
  #
  # Accumulates a base-10 value. The first digit (guaranteed non-zero)
  # was consumed by the transition clause above.

  # End of input → 2D coordinate
  defp parse_integer(<<>>, num_acc, dim1) do
    rank_index = num_acc - 1

    if rank_index > @max_index_value do
      {:error, :index_out_of_range}
    else
      {:ok, {dim1, rank_index}}
    end
  end

  # Accumulate another digit
  defp parse_integer(<<byte, rest::binary>>, num_acc, dim1) when byte in ?0..?9 do
    new_acc = num_acc * 10 + (byte - ?0)

    # Max valid value is 256 (index 255), reject early
    if new_acc > @max_index_value + 1 do
      {:error, :index_out_of_range}
    else
      parse_integer(rest, new_acc, dim1)
    end
  end

  # Transition to dimension 3: uppercase letter after integer
  defp parse_integer(<<byte, rest::binary>>, num_acc, dim1) when byte in ?A..?Z do
    rank_index = num_acc - 1

    if rank_index > @max_index_value do
      {:error, :index_out_of_range}
    else
      parse_uppercase(rest, byte - ?A, 1, dim1, rank_index)
    end
  end

  # Any other character
  defp parse_integer(_, _num_acc, _dim1) do
    {:error, :unexpected_character}
  end

  # ── Dimension 3: uppercase letters ────────────────────────────────────
  #
  # Accumulates a bijective base-26 value across 1 or 2 letters.
  # No further dimensions are allowed (max 3).

  # End of input → 3D coordinate
  defp parse_uppercase(<<>>, acc, letter_count, dim1, dim2) do
    finalize_letter_index(acc, letter_count, fn dim3 ->
      {:ok, {dim1, dim2, dim3}}
    end)
  end

  # Second uppercase letter
  defp parse_uppercase(<<byte, rest::binary>>, acc, 1, dim1, dim2) when byte in ?A..?Z do
    parse_uppercase(rest, acc * 26 + (byte - ?A), 2, dim1, dim2)
  end

  # Third uppercase letter → always exceeds 255
  defp parse_uppercase(<<byte, _::binary>>, _acc, 2, _dim1, _dim2) when byte in ?A..?Z do
    {:error, :index_out_of_range}
  end

  # Lowercase after uppercase → would start dimension 4
  defp parse_uppercase(<<byte, _::binary>>, _acc, _lc, _dim1, _dim2) when byte in ?a..?z do
    {:error, :exceeds_max_dimensions}
  end

  # Any other character
  defp parse_uppercase(_, _acc, _lc, _dim1, _dim2) do
    {:error, :unexpected_character}
  end

  # ── Helpers ───────────────────────────────────────────────────────────

  # Finalize a letter accumulator into a 0-based index.
  # Single letter: value is already 0-25 (always valid).
  # Double letter: offset by 26, then check bounds.
  defp finalize_letter_index(acc, 1, continuation), do: continuation.(acc)

  defp finalize_letter_index(acc, 2, continuation) do
    index = 26 + acc

    if index > @max_index_value do
      {:error, :index_out_of_range}
    else
      continuation.(index)
    end
  end

  defp finish_1d(dim1), do: {:ok, {dim1}}
end
