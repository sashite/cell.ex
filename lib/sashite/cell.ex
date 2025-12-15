defmodule Sashite.Cell do
  @moduledoc """
  CELL (Coordinate Encoding for Layered Locations) implementation for Elixir.

  CELL is a standardized format for representing coordinates on multi-dimensional
  game boards using a cyclical ASCII character system.

  ## Format

  CELL uses a cyclical three-character-set system:

  | Dimension | Condition | Character Set |
  |-----------|-----------|---------------|
  | 1st, 4th, 7th… | n % 3 = 1 | Latin lowercase (`a`–`z`) |
  | 2nd, 5th, 8th… | n % 3 = 2 | Positive integers |
  | 3rd, 6th, 9th… | n % 3 = 0 | Latin uppercase (`A`–`Z`) |

  ## Examples

      iex> Sashite.Cell.valid?("a1")
      true

      iex> Sashite.Cell.valid?("a1A")
      true

      iex> Sashite.Cell.parse!("e4")
      ["e", "4"]

      iex> Sashite.Cell.to_indices!("e4")
      {4, 3}

      iex> Sashite.Cell.from_indices!({4, 3})
      "e4"

  See the [CELL Specification](https://sashite.dev/specs/cell/1.0.0/) for details.
  """

  @typedoc "Dimension type in the cyclical system"
  @type dimension_type :: :lowercase | :numeric | :uppercase

  # Regular expression from CELL Specification v1.0.0
  # Note: Line breaks must be rejected separately (see valid?/1)
  @cell_regex ~r/^[a-z]+(?:[1-9][0-9]*[A-Z]+[a-z]+)*(?:[1-9][0-9]*[A-Z]*)?$/

  # --- Validation ---

  @doc """
  Checks if a string represents a valid CELL coordinate.

  Implements full-string matching as required by the CELL specification.
  Rejects any input containing line breaks (`\\r` or `\\n`).

  ## Examples

      iex> Sashite.Cell.valid?("a1")
      true

      iex> Sashite.Cell.valid?("a1A")
      true

      iex> Sashite.Cell.valid?("e4")
      true

      iex> Sashite.Cell.valid?("a0")
      false

      iex> Sashite.Cell.valid?("")
      false

      iex> Sashite.Cell.valid?("1a")
      false

      iex> Sashite.Cell.valid?("a1\\n")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(string) when is_binary(string) and byte_size(string) > 0 do
    not String.contains?(string, ["\r", "\n"]) and Regex.match?(@cell_regex, string)
  end

  def valid?(_), do: false

  @doc """
  Returns the validation regular expression from CELL specification v1.0.0.

  Note: This regex alone does not guarantee full compliance. The `valid?/1`
  function additionally rejects strings containing line breaks, as required
  by the specification's anchoring requirements.

  ## Examples

      iex> Sashite.Cell.regex() |> Regex.source()
      "^[a-z]+(?:[1-9][0-9]*[A-Z]+[a-z]+)*(?:[1-9][0-9]*[A-Z]*)?$"

  """
  @spec regex() :: Regex.t()
  def regex, do: @cell_regex

  # --- Parsing ---

  @doc """
  Parses a CELL coordinate string into dimensional components.

  Returns `{:ok, components}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Cell.parse("a1")
      {:ok, ["a", "1"]}

      iex> Sashite.Cell.parse("a1A")
      {:ok, ["a", "1", "A"]}

      iex> Sashite.Cell.parse("h8Hh8")
      {:ok, ["h", "8", "H", "h", "8"]}

      iex> Sashite.Cell.parse("foobar")
      {:ok, ["foobar"]}

      iex> Sashite.Cell.parse("invalid!")
      {:error, "Invalid CELL coordinate: invalid!"}

  """
  @spec parse(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def parse(string) when is_binary(string) do
    if valid?(string) do
      {:ok, parse_recursive(string, 1)}
    else
      {:error, "Invalid CELL coordinate: #{string}"}
    end
  end

  def parse(value) do
    {:error, "Invalid CELL coordinate: #{inspect(value)}"}
  end

  @doc """
  Parses a CELL coordinate string into dimensional components.

  Returns the components on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Cell.parse!("a1A")
      ["a", "1", "A"]

      iex> Sashite.Cell.parse!("1nvalid")
      ** (ArgumentError) Invalid CELL coordinate: 1nvalid

  """
  @spec parse!(String.t()) :: [String.t()]
  def parse!(string) do
    case parse(string) do
      {:ok, components} -> components
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  # --- Dimensional Analysis ---

  @doc """
  Returns the number of dimensions in a CELL coordinate.

  Returns 0 for invalid coordinates.

  ## Examples

      iex> Sashite.Cell.dimensions("a")
      1

      iex> Sashite.Cell.dimensions("a1")
      2

      iex> Sashite.Cell.dimensions("a1A")
      3

      iex> Sashite.Cell.dimensions("h8Hh8")
      5

      iex> Sashite.Cell.dimensions("1nvalid")
      0

  """
  @spec dimensions(String.t()) :: non_neg_integer()
  def dimensions(string) when is_binary(string) do
    case parse(string) do
      {:ok, components} -> length(components)
      {:error, _} -> 0
    end
  end

  def dimensions(_), do: 0

  # --- Coordinate Conversion ---

  @doc """
  Converts a CELL coordinate to a tuple of 0-indexed integers.

  Returns `{:ok, tuple}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Cell.to_indices("a1")
      {:ok, {0, 0}}

      iex> Sashite.Cell.to_indices("e4")
      {:ok, {4, 3}}

      iex> Sashite.Cell.to_indices("a1A")
      {:ok, {0, 0, 0}}

      iex> Sashite.Cell.to_indices("z26Z")
      {:ok, {25, 25, 25}}

      iex> Sashite.Cell.to_indices("aa1AA")
      {:ok, {26, 0, 26}}

      iex> Sashite.Cell.to_indices("1nvalid")
      {:error, "Invalid CELL coordinate: 1nvalid"}

  """
  @spec to_indices(String.t()) :: {:ok, tuple()} | {:error, String.t()}
  def to_indices(string) when is_binary(string) do
    case parse(string) do
      {:ok, components} ->
        indices =
          components
          |> Enum.with_index(1)
          |> Enum.map(fn {component, dimension} ->
            dim_type = dimension_type(dimension)
            component_to_index(component, dim_type)
          end)
          |> List.to_tuple()

        {:ok, indices}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def to_indices(value) do
    {:error, "Invalid CELL coordinate: #{inspect(value)}"}
  end

  @doc """
  Converts a CELL coordinate to a tuple of 0-indexed integers.

  Returns the tuple on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Cell.to_indices!("e4")
      {4, 3}

      iex> Sashite.Cell.to_indices!("a1A")
      {0, 0, 0}

      iex> Sashite.Cell.to_indices!("1nvalid")
      ** (ArgumentError) Invalid CELL coordinate: 1nvalid

  """
  @spec to_indices!(String.t()) :: tuple()
  def to_indices!(string) do
    case to_indices(string) do
      {:ok, indices} -> indices
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Converts a tuple of 0-indexed integers to a CELL coordinate.

  Returns `{:ok, coordinate}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Cell.from_indices({0, 0})
      {:ok, "a1"}

      iex> Sashite.Cell.from_indices({4, 3})
      {:ok, "e4"}

      iex> Sashite.Cell.from_indices({0, 0, 0})
      {:ok, "a1A"}

      iex> Sashite.Cell.from_indices({25, 25, 25})
      {:ok, "z26Z"}

      iex> Sashite.Cell.from_indices({26, 0, 26})
      {:ok, "aa1AA"}

      iex> Sashite.Cell.from_indices({})
      {:error, "Cannot convert empty tuple to CELL coordinate"}

  """
  @spec from_indices(tuple()) :: {:ok, String.t()} | {:error, String.t()}
  def from_indices(indices) when is_tuple(indices) and tuple_size(indices) > 0 do
    result =
      indices
      |> Tuple.to_list()
      |> Enum.with_index(1)
      |> Enum.map(fn {index, dimension} ->
        dim_type = dimension_type(dimension)
        index_to_component(index, dim_type)
      end)
      |> Enum.join()

    if valid?(result) do
      {:ok, result}
    else
      {:error, "Generated invalid CELL coordinate: #{result}"}
    end
  end

  def from_indices(tuple) when is_tuple(tuple) and tuple_size(tuple) == 0 do
    {:error, "Cannot convert empty tuple to CELL coordinate"}
  end

  def from_indices(value) do
    {:error, "Expected tuple, got: #{inspect(value)}"}
  end

  @doc """
  Converts a tuple of 0-indexed integers to a CELL coordinate.

  Returns the coordinate on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Cell.from_indices!({4, 3})
      "e4"

      iex> Sashite.Cell.from_indices!({0, 0, 0})
      "a1A"

      iex> Sashite.Cell.from_indices!({})
      ** (ArgumentError) Cannot convert empty tuple to CELL coordinate

  """
  @spec from_indices!(tuple()) :: String.t()
  def from_indices!(indices) do
    case from_indices(indices) do
      {:ok, coordinate} -> coordinate
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  # --- Private Functions ---

  # Recursively parse a coordinate string into components
  # following the strict CELL specification cyclical pattern
  @spec parse_recursive(String.t(), pos_integer()) :: [String.t()]
  defp parse_recursive("", _dimension), do: []

  defp parse_recursive(string, dimension) do
    dim_type = dimension_type(dimension)

    case extract_component(string, dim_type) do
      {component, remaining} ->
        [component | parse_recursive(remaining, dimension + 1)]

      nil ->
        []
    end
  end

  # Determine the character set type for a given dimension
  # Following CELL specification cyclical system: dimension n % 3 determines character set
  @spec dimension_type(pos_integer()) :: dimension_type()
  defp dimension_type(dimension) do
    case rem(dimension, 3) do
      1 -> :lowercase
      2 -> :numeric
      0 -> :uppercase
    end
  end

  # Extract the next component from a string based on expected type
  @spec extract_component(String.t(), dimension_type()) :: {String.t(), String.t()} | nil
  defp extract_component(string, :lowercase) do
    case Regex.run(~r/^([a-z]+)/, string, capture: :all_but_first) do
      [match] -> {match, String.slice(string, String.length(match)..-1//1)}
      nil -> nil
    end
  end

  defp extract_component(string, :numeric) do
    case Regex.run(~r/^([1-9][0-9]*)/, string, capture: :all_but_first) do
      [match] -> {match, String.slice(string, String.length(match)..-1//1)}
      nil -> nil
    end
  end

  defp extract_component(string, :uppercase) do
    case Regex.run(~r/^([A-Z]+)/, string, capture: :all_but_first) do
      [match] -> {match, String.slice(string, String.length(match)..-1//1)}
      nil -> nil
    end
  end

  # Convert a component to its 0-indexed position
  @spec component_to_index(String.t(), dimension_type()) :: non_neg_integer()
  defp component_to_index(component, :lowercase) do
    letters_to_index(component)
  end

  defp component_to_index(component, :numeric) do
    String.to_integer(component) - 1
  end

  defp component_to_index(component, :uppercase) do
    component
    |> String.downcase()
    |> letters_to_index()
  end

  # Convert a 0-indexed position to a component
  @spec index_to_component(non_neg_integer(), dimension_type()) :: String.t()
  defp index_to_component(index, :lowercase) do
    index_to_letters(index)
  end

  defp index_to_component(index, :numeric) do
    Integer.to_string(index + 1)
  end

  defp index_to_component(index, :uppercase) do
    index
    |> index_to_letters()
    |> String.upcase()
  end

  # Convert letter sequence to 0-indexed position
  # Extended alphabet per CELL specification:
  # a=0, b=1, ..., z=25, aa=26, ab=27, ..., zz=701, aaa=702, etc.
  @spec letters_to_index(String.t()) :: non_neg_integer()
  defp letters_to_index(letters) do
    length = String.length(letters)

    # Add positions from shorter sequences
    base_offset =
      1..(length - 1)//1
      |> Enum.reduce(0, fn len, acc -> acc + pow(26, len) end)

    # Add position within current length
    position_in_length =
      letters
      |> String.to_charlist()
      |> Enum.with_index()
      |> Enum.reduce(0, fn {char, pos}, acc ->
        char_value = char - ?a
        place_value = pow(26, length - pos - 1)
        acc + char_value * place_value
      end)

    base_offset + position_in_length
  end

  # Convert 0-indexed position to letter sequence
  # Extended alphabet per CELL specification:
  # 0=a, 1=b, ..., 25=z, 26=aa, 27=ab, ..., 701=zz, 702=aaa, etc.
  @spec index_to_letters(non_neg_integer()) :: String.t()
  defp index_to_letters(index) do
    # Find the length of the result
    {length, base} = find_length_and_base(index, 1, 0)

    # Convert within the found length
    adjusted_index = index - base
    build_letters(adjusted_index, length, [])
  end

  # Find the length and base offset for a given index
  @spec find_length_and_base(non_neg_integer(), pos_integer(), non_neg_integer()) ::
          {pos_integer(), non_neg_integer()}
  defp find_length_and_base(index, length, base) do
    range_size = pow(26, length)

    if index < base + range_size do
      {length, base}
    else
      find_length_and_base(index, length + 1, base + range_size)
    end
  end

  # Build the letter string from adjusted index
  @spec build_letters(non_neg_integer(), non_neg_integer(), [char()]) :: String.t()
  defp build_letters(_index, 0, acc), do: List.to_string(acc)

  defp build_letters(index, remaining, acc) do
    place_value = pow(26, remaining - 1)
    char_index = div(index, place_value)
    char = ?a + char_index
    new_index = rem(index, place_value)
    build_letters(new_index, remaining - 1, acc ++ [char])
  end

  # Simple integer power function
  @spec pow(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp pow(_base, 0), do: 1
  defp pow(base, exp), do: base * pow(base, exp - 1)
end
