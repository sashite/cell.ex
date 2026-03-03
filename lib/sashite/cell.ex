defmodule Sashite.Cell do
  @moduledoc """
  CELL (Coordinate Encoding for Layered Locations) implementation for Elixir.

  This library provides parsing, formatting, and validation of CELL coordinates
  as specified in the [CELL Specification v1.0.0](https://sashite.dev/specs/cell/1.0.0/).

  CELL coordinates encode positions on multi-dimensional boards using a cyclical
  ASCII character system:

  - **Dimension 1** (file): lowercase letters `a-z`, `aa-iv` (indices 0-255)
  - **Dimension 2** (rank): positive integers `1-256` (indices 0-255)
  - **Dimension 3** (layer): uppercase letters `A-Z`, `AA-IV` (indices 0-255)

  ## Security

  This implementation is designed for untrusted input:

  - Input length is validated first (DoS protection)
  - Parsing is done character-by-character with strict bounds checking
  - All indices are constrained to 0-255
  - Maximum 3 dimensions enforced

  ## Examples

      iex> Sashite.Cell.to_indices("e4")
      {:ok, {4, 3}}

      iex> Sashite.Cell.from_indices({4, 3})
      {:ok, "e4"}

      iex> Sashite.Cell.valid?("e4")
      true
  """

  alias Sashite.Cell.{Formatter, Parser}

  # ── Constants ─────────────────────────────────────────────────────────

  @doc """
  Returns the maximum number of dimensions (3).

  ## Examples

      iex> Sashite.Cell.max_dimensions()
      3
  """
  @spec max_dimensions() :: pos_integer()
  def max_dimensions, do: 3

  @doc """
  Returns the maximum index value per dimension (255).

  ## Examples

      iex> Sashite.Cell.max_index_value()
      255
  """
  @spec max_index_value() :: non_neg_integer()
  def max_index_value, do: 255

  @doc """
  Returns the maximum string length for a CELL coordinate (7).

  The longest valid coordinate is `"iv256IV"` (indices 255, 255, 255).

  ## Examples

      iex> Sashite.Cell.max_string_length()
      7
  """
  @spec max_string_length() :: pos_integer()
  def max_string_length, do: 7

  # ── Parsing ───────────────────────────────────────────────────────────

  @doc """
  Parses a CELL string into a tuple of 0-indexed integers.

  Returns `{:ok, tuple}` on success, or `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Cell.to_indices("a1")
      {:ok, {0, 0}}

      iex> Sashite.Cell.to_indices("e4")
      {:ok, {4, 3}}

      iex> Sashite.Cell.to_indices("a1A")
      {:ok, {0, 0, 0}}

      iex> Sashite.Cell.to_indices("aa1")
      {:ok, {26, 0}}

      iex> Sashite.Cell.to_indices("iv256IV")
      {:ok, {255, 255, 255}}

      iex> Sashite.Cell.to_indices("")
      {:error, :empty_input}

      iex> Sashite.Cell.to_indices("a0")
      {:error, :leading_zero}

      iex> Sashite.Cell.to_indices("A1")
      {:error, :must_start_with_lowercase}
  """
  @spec to_indices(String.t()) :: {:ok, tuple()} | {:error, atom()}
  defdelegate to_indices(string), to: Parser, as: :parse

  @doc """
  Parses a CELL string, raising `ArgumentError` on invalid input.

  ## Examples

      iex> Sashite.Cell.to_indices!("e4")
      {4, 3}

      iex> Sashite.Cell.to_indices!("aa1")
      {26, 0}

      iex> Sashite.Cell.to_indices!("iv256IV")
      {255, 255, 255}
  """
  @spec to_indices!(String.t()) :: tuple()
  defdelegate to_indices!(string), to: Parser, as: :parse!

  # ── Formatting ────────────────────────────────────────────────────────

  @doc """
  Formats a tuple of 0-indexed integers into a CELL string.

  Returns `{:ok, string}` on success, or `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Cell.from_indices({0, 0})
      {:ok, "a1"}

      iex> Sashite.Cell.from_indices({4, 3})
      {:ok, "e4"}

      iex> Sashite.Cell.from_indices({0, 0, 0})
      {:ok, "a1A"}

      iex> Sashite.Cell.from_indices({26, 0})
      {:ok, "aa1"}

      iex> Sashite.Cell.from_indices({255, 255, 255})
      {:ok, "iv256IV"}

      iex> Sashite.Cell.from_indices({256, 0})
      {:error, :index_out_of_range}

      iex> Sashite.Cell.from_indices({})
      {:error, :invalid_dimensions}
  """
  @spec from_indices(tuple()) :: {:ok, String.t()} | {:error, atom()}
  defdelegate from_indices(indices), to: Formatter, as: :format

  @doc """
  Formats a tuple of indices, raising `ArgumentError` on invalid input.

  ## Examples

      iex> Sashite.Cell.from_indices!({4, 3})
      "e4"

      iex> Sashite.Cell.from_indices!({26, 0})
      "aa1"

      iex> Sashite.Cell.from_indices!({255, 255, 255})
      "iv256IV"
  """
  @spec from_indices!(tuple()) :: String.t()
  defdelegate from_indices!(indices), to: Formatter, as: :format!

  # ── Validation ────────────────────────────────────────────────────────

  @doc """
  Returns `true` if the string is a valid CELL coordinate.

  This function never raises; it returns `false` for any invalid input,
  including non-string values.

  ## Examples

      iex> Sashite.Cell.valid?("e4")
      true

      iex> Sashite.Cell.valid?("a1A")
      true

      iex> Sashite.Cell.valid?("iv256IV")
      true

      iex> Sashite.Cell.valid?("")
      false

      iex> Sashite.Cell.valid?("a0")
      false

      iex> Sashite.Cell.valid?("A1")
      false

      iex> Sashite.Cell.valid?(nil)
      false
  """
  @spec valid?(any()) :: boolean()
  def valid?(string) when is_binary(string) do
    match?({:ok, _}, Parser.parse(string))
  end

  def valid?(_), do: false
end
