defmodule Sashite.Cell.Coordinate do
  @moduledoc """
  Represents a validated CELL coordinate with up to 3 dimensions.

  A Coordinate is a tuple of 0-indexed integer values, where each value
  is constrained to the range 0-255.

  ## Constraints

  | Constraint | Value | Rationale |
  |------------|-------|-----------|
  | Max dimensions | 3 | Sufficient for 1D, 2D, 3D boards |
  | Max index value | 255 | Covers 256×256×256 boards |
  | Max string length | 7 | `"iv256IV"` (max for all dimensions at 255) |

  ## Types

  Coordinates are represented as tuples:

  - 1D: `{file}`
  - 2D: `{file, rank}`
  - 3D: `{file, rank, layer}`
  """

  # --- Constants ---

  @max_dimensions 3
  @max_index_value 255
  @max_string_length 7

  # --- Types ---

  @typedoc "A validated CELL coordinate as a tuple of 1 to 3 indices."
  @type t :: {index()} | {index(), index()} | {index(), index(), index()}

  @typedoc "A single coordinate index (0-255)."
  @type index :: 0..255

  # --- Guards ---

  @doc """
  Guard that checks if a value is a valid coordinate index (0-255).

  ## Examples

      iex> require Sashite.Cell.Coordinate
      iex> Sashite.Cell.Coordinate.is_valid_index(0)
      true

      iex> require Sashite.Cell.Coordinate
      iex> Sashite.Cell.Coordinate.is_valid_index(255)
      true

      iex> require Sashite.Cell.Coordinate
      iex> Sashite.Cell.Coordinate.is_valid_index(256)
      false

      iex> require Sashite.Cell.Coordinate
      iex> Sashite.Cell.Coordinate.is_valid_index(-1)
      false
  """
  defguard is_valid_index(value)
           when is_integer(value) and value >= 0 and value <= @max_index_value

  # --- Constants Accessors ---

  @doc """
  Returns the maximum number of dimensions (3).

  ## Examples

      iex> Sashite.Cell.Coordinate.max_dimensions()
      3
  """
  @spec max_dimensions() :: pos_integer()
  def max_dimensions, do: @max_dimensions

  @doc """
  Returns the maximum index value per dimension (255).

  ## Examples

      iex> Sashite.Cell.Coordinate.max_index_value()
      255
  """
  @spec max_index_value() :: non_neg_integer()
  def max_index_value, do: @max_index_value

  @doc """
  Returns the maximum string length for a CELL coordinate (7).

  The longest valid coordinate is `"iv256IV"` (255, 255, 255).

  ## Examples

      iex> Sashite.Cell.Coordinate.max_string_length()
      7
  """
  @spec max_string_length() :: pos_integer()
  def max_string_length, do: @max_string_length

  # --- Constructor ---

  @doc """
  Creates a new Coordinate from a tuple of indices.

  Returns `{:ok, coordinate}` if all indices are valid (0-255),
  or `{:error, reason}` otherwise.

  ## Examples

      iex> Sashite.Cell.Coordinate.new({0})
      {:ok, {0}}

      iex> Sashite.Cell.Coordinate.new({4, 3})
      {:ok, {4, 3}}

      iex> Sashite.Cell.Coordinate.new({0, 0, 0})
      {:ok, {0, 0, 0}}

      iex> Sashite.Cell.Coordinate.new({255, 255, 255})
      {:ok, {255, 255, 255}}

      iex> Sashite.Cell.Coordinate.new({256, 0})
      {:error, "index exceeds 255"}

      iex> Sashite.Cell.Coordinate.new({-1})
      {:error, "index exceeds 255"}

      iex> Sashite.Cell.Coordinate.new({})
      {:error, "invalid dimensions"}

      iex> Sashite.Cell.Coordinate.new({0, 0, 0, 0})
      {:error, "invalid dimensions"}

      iex> Sashite.Cell.Coordinate.new("a1")
      {:error, "invalid coordinate"}
  """
  @spec new(tuple()) :: {:ok, t()} | {:error, String.t()}
  def new({a}) when is_valid_index(a), do: {:ok, {a}}

  def new({a, b}) when is_valid_index(a) and is_valid_index(b), do: {:ok, {a, b}}

  def new({a, b, c}) when is_valid_index(a) and is_valid_index(b) and is_valid_index(c) do
    {:ok, {a, b, c}}
  end

  def new(tuple) when is_tuple(tuple) and tuple_size(tuple) >= 1 and tuple_size(tuple) <= 3 do
    {:error, "index exceeds 255"}
  end

  def new(tuple) when is_tuple(tuple), do: {:error, "invalid dimensions"}

  def new(_), do: {:error, "invalid coordinate"}

  @doc """
  Creates a new Coordinate, raising `ArgumentError` on invalid input.

  ## Examples

      iex> Sashite.Cell.Coordinate.new!({4, 3})
      {4, 3}

      iex> Sashite.Cell.Coordinate.new!({255, 255, 255})
      {255, 255, 255}
  """
  @spec new!(tuple()) :: t()
  def new!(tuple) do
    case new(tuple) do
      {:ok, coordinate} -> coordinate
      {:error, reason} -> raise ArgumentError, reason
    end
  end
end
