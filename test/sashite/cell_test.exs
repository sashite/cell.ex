defmodule Sashite.CellTest do
  use ExUnit.Case, async: true

  alias Sashite.Cell

  doctest Sashite.Cell

  # ============================================================================
  # SPECIFICATION COMPLIANCE TESTS
  # ============================================================================

  describe "specification compliance" do
    test "regex matches CELL specification v1.0.0" do
      # Exact regex from CELL Specification v1.0.0
      spec_regex = ~r/^[a-z]+(?:[1-9][0-9]*[A-Z]+[a-z]+)*(?:[1-9][0-9]*[A-Z]*)?$/

      assert Cell.regex().source == spec_regex.source
    end

    test "all specification valid examples are accepted" do
      # Valid examples directly from CELL Specification v1.0.0
      spec_valid_examples = [
        # Basic Examples
        "a",
        "a1",
        "a1A",
        "a1Aa",
        "a1Aa1",
        "a1Aa1A",
        # Extended Alphabet Examples
        "aa1AA",
        "z26Z",
        "abc123XYZ",
        # Game-Specific Examples
        "e4",
        "h8",
        "a1",
        "e1",
        "i9",
        "a1A",
        "b2B",
        "c3C"
      ]

      for coord <- spec_valid_examples do
        assert Cell.valid?(coord), "Specification example '#{coord}' should be valid"
      end
    end

    test "all specification invalid examples are rejected" do
      # Invalid examples directly from CELL Specification v1.0.0
      spec_invalid_examples = [
        "",
        "1",
        "A",
        "a0",
        "a1a",
        "1a",
        "aA",
        "a1A1"
      ]

      for coord <- spec_invalid_examples do
        refute Cell.valid?(coord), "Specification invalid example '#{coord}' should be rejected"
      end
    end

    test "cyclical dimension system follows specification" do
      # Test the n % 3 cyclical system from specification
      test_cases = [
        {"a", 1},
        {"a1", 2},
        {"a1A", 3},
        {"a1Aa", 4},
        {"a1Aa1", 5},
        {"a1Aa1A", 6}
      ]

      for {coord, expected_dims} <- test_cases do
        assert Cell.dimensions(coord) == expected_dims,
               "#{coord} should have #{expected_dims} dimensions"

        assert Cell.valid?(coord), "#{coord} should be valid according to cyclical system"
      end
    end
  end

  # ============================================================================
  # VALIDATION TESTS
  # ============================================================================

  describe "valid?/1" do
    test "accepts valid coordinates" do
      valid_coordinates = [
        # Single dimension
        "a",
        "z",
        "aa",
        "zz",
        "abc",
        "foobar",
        # Two dimensions
        "a1",
        "z26",
        "aa1",
        "zz701",
        # Three dimensions
        "a1A",
        "z26Z",
        "aa1AA",
        "zz701ZZ",
        # Multi-cycle coordinates
        "a1Aa1A",
        "b2Bb2B",
        "h8Hh8H",
        # Extended alphabet cases
        "abc123XYZ",
        "foo999BAR"
      ]

      for coord <- valid_coordinates do
        assert Cell.valid?(coord), "#{inspect(coord)} should be valid"
      end
    end

    test "rejects invalid coordinates" do
      invalid_coordinates = [
        # Empty
        "",
        # Wrong starting character
        "1",
        "A",
        "1a",
        "Aa",
        # Contains zero
        "a0",
        "a0A",
        "a01A",
        "aa0AA",
        # Wrong cyclical order
        "a1a",
        "A1A",
        "aA",
        "a1A1",
        # Invalid characters
        "*",
        "a*",
        "1*",
        "A*",
        "a-1",
        "a1-A",
        # Whitespace issues
        " a1",
        "a1 ",
        "a 1",
        "a1 A"
      ]

      for coord <- invalid_coordinates do
        refute Cell.valid?(coord), "#{inspect(coord)} should be invalid"
      end
    end

    test "rejects strings containing line breaks" do
      line_break_cases = [
        "a1\n",
        "a1\r",
        "a1\r\n",
        "\na1",
        "a\n1",
        "a1A\n",
        "\r\na1A"
      ]

      for coord <- line_break_cases do
        refute Cell.valid?(coord), "#{inspect(coord)} should be invalid (contains line break)"
      end
    end

    test "handles non-string input" do
      non_strings = [nil, 123, :a1, [], %{}, true, false, 1.5]

      for input <- non_strings do
        refute Cell.valid?(input), "#{inspect(input)} should be invalid"
      end
    end
  end

  # ============================================================================
  # PARSING TESTS
  # ============================================================================

  describe "parse/1" do
    test "parses coordinates into components correctly" do
      parse_cases = [
        # Single dimension
        {"a", ["a"]},
        {"abc", ["abc"]},
        {"foobar", ["foobar"]},
        # Multiple dimensions
        {"a1", ["a", "1"]},
        {"a1A", ["a", "1", "A"]},
        {"a1Aa", ["a", "1", "A", "a"]},
        {"a1Aa1", ["a", "1", "A", "a", "1"]},
        {"a1Aa1A", ["a", "1", "A", "a", "1", "A"]},
        # Extended alphabet
        {"aa1AA", ["aa", "1", "AA"]},
        {"bb25BB", ["bb", "25", "BB"]},
        {"abc123XYZ", ["abc", "123", "XYZ"]},
        # Game examples
        {"h8Hh8", ["h", "8", "H", "h", "8"]},
        {"e4", ["e", "4"]}
      ]

      for {coord, expected_components} <- parse_cases do
        assert {:ok, ^expected_components} = Cell.parse(coord)
      end
    end

    test "returns error for invalid coordinates" do
      invalid_inputs = ["", "1a", "A1a", "a0", "*", "a1\n"]

      for input <- invalid_inputs do
        assert {:error, _reason} = Cell.parse(input)
      end
    end

    test "returns error for non-string input" do
      assert {:error, _reason} = Cell.parse(nil)
      assert {:error, _reason} = Cell.parse(123)
    end
  end

  describe "parse!/1" do
    test "returns components for valid coordinate" do
      assert ["a", "1", "A"] = Cell.parse!("a1A")
    end

    test "raises ArgumentError for invalid coordinate" do
      assert_raise ArgumentError, fn ->
        Cell.parse!("invalid!")
      end
    end
  end

  # ============================================================================
  # DIMENSIONAL ANALYSIS TESTS
  # ============================================================================

  describe "dimensions/1" do
    test "returns correct dimension count" do
      dimension_cases = [
        {"a", 1},
        {"a1", 2},
        {"a1A", 3},
        {"a1Aa", 4},
        {"a1Aa1", 5},
        {"a1Aa1A", 6},
        {"a1Aa1Aa1A", 9},
        {"abc", 1},
        {"h8Hh8H", 6},
        {"z999ZZZ", 3}
      ]

      for {coord, expected_dimensions} <- dimension_cases do
        assert Cell.dimensions(coord) == expected_dimensions,
               "#{inspect(coord)} should have #{expected_dimensions} dimensions"
      end
    end

    test "returns 0 for invalid input" do
      invalid_inputs = [nil, "", 123, [], "1a", "A1a", "a0", "*"]

      for input <- invalid_inputs do
        assert Cell.dimensions(input) == 0,
               "#{inspect(input)} should return 0 dimensions"
      end
    end
  end

  # ============================================================================
  # COORDINATE CONVERSION TESTS
  # ============================================================================

  describe "to_indices/1" do
    test "converts coordinates to indices correctly" do
      conversion_cases = [
        # Basic cases
        {"a1", {0, 0}},
        {"b2", {1, 1}},
        {"e4", {4, 3}},
        {"h8", {7, 7}},
        # 3D cases
        {"a1A", {0, 0, 0}},
        {"b2B", {1, 1, 1}},
        {"c3C", {2, 2, 2}},
        # Extended alphabet
        {"z26Z", {25, 25, 25}},
        {"aa1AA", {26, 0, 26}},
        {"ab2AB", {27, 1, 27}},
        # Single dimension
        {"a", {0}},
        {"z", {25}},
        {"aa", {26}},
        {"zz", {701}}
      ]

      for {coord, expected_indices} <- conversion_cases do
        assert {:ok, ^expected_indices} = Cell.to_indices(coord)
      end
    end

    test "returns error for invalid coordinates" do
      invalid_coords = ["", "a0", "1a", "*", "a1a"]

      for coord <- invalid_coords do
        assert {:error, _reason} = Cell.to_indices(coord)
      end
    end
  end

  describe "to_indices!/1" do
    test "returns indices for valid coordinate" do
      assert {4, 3} = Cell.to_indices!("e4")
      assert {0, 0, 0} = Cell.to_indices!("a1A")
    end

    test "raises ArgumentError for invalid coordinate" do
      assert_raise ArgumentError, fn ->
        Cell.to_indices!("1nvalid")
      end
    end
  end

  describe "from_indices/1" do
    test "converts indices to coordinates correctly" do
      conversion_cases = [
        # Basic cases
        {{0, 0}, "a1"},
        {{1, 1}, "b2"},
        {{4, 3}, "e4"},
        {{7, 7}, "h8"},
        # 3D cases
        {{0, 0, 0}, "a1A"},
        {{1, 1, 1}, "b2B"},
        {{2, 2, 2}, "c3C"},
        # Extended alphabet
        {{25, 25, 25}, "z26Z"},
        {{26, 0, 26}, "aa1AA"},
        {{27, 1, 27}, "ab2AB"},
        # Single dimension
        {{0}, "a"},
        {{25}, "z"},
        {{26}, "aa"},
        {{701}, "zz"}
      ]

      for {indices, expected_coord} <- conversion_cases do
        assert {:ok, ^expected_coord} = Cell.from_indices(indices)
      end
    end

    test "returns error for empty tuple" do
      assert {:error, "Cannot convert empty tuple to CELL coordinate"} = Cell.from_indices({})
    end

    test "returns error for non-tuple input" do
      assert {:error, _reason} = Cell.from_indices([0, 0])
      assert {:error, _reason} = Cell.from_indices(nil)
    end
  end

  describe "from_indices!/1" do
    test "returns coordinate for valid indices" do
      assert "e4" = Cell.from_indices!({4, 3})
      assert "a1A" = Cell.from_indices!({0, 0, 0})
    end

    test "raises ArgumentError for empty tuple" do
      assert_raise ArgumentError, fn ->
        Cell.from_indices!({})
      end
    end
  end

  # ============================================================================
  # ROUND-TRIP TESTS
  # ============================================================================

  describe "round-trip conversion" do
    test "coordinate -> indices -> coordinate preserves values" do
      test_coordinates = [
        # Specification examples
        "a",
        "a1",
        "a1A",
        "a1Aa",
        "a1Aa1",
        "a1Aa1A",
        "aa1AA",
        "z26Z",
        "abc123XYZ",
        "e4",
        "h8",
        "a1A",
        "b2B",
        "c3C",
        # Extended cases
        "zz701ZZ",
        "abc999XYZ"
      ]

      for coord <- test_coordinates do
        indices = Cell.to_indices!(coord)
        converted_back = Cell.from_indices!(indices)

        assert converted_back == coord,
               "Round-trip failed for #{inspect(coord)}: got #{inspect(converted_back)}"
      end
    end

    test "indices -> coordinate -> indices preserves values" do
      test_indices = [
        # 1D
        {0},
        {25},
        {26},
        {701},
        # 2D
        {0, 0},
        {4, 3},
        {7, 7},
        {25, 25},
        # 3D
        {0, 0, 0},
        {1, 1, 1},
        {25, 25, 25},
        # 4D
        {0, 0, 0, 0},
        {1, 1, 1, 1}
      ]

      for indices <- test_indices do
        coord = Cell.from_indices!(indices)
        converted_back = Cell.to_indices!(coord)

        assert converted_back == indices,
               "Round-trip failed for #{inspect(indices)}: got #{inspect(converted_back)}"
      end
    end
  end

  # ============================================================================
  # EXTENDED ALPHABET TESTS
  # ============================================================================

  describe "extended alphabet encoding" do
    test "single letters encode correctly" do
      single_letter_cases = [
        {0, "a"},
        {1, "b"},
        {25, "z"}
      ]

      for {index, expected_letter} <- single_letter_cases do
        assert {:ok, ^expected_letter} = Cell.from_indices({index})
        assert {:ok, {^index}} = Cell.to_indices(expected_letter)
      end
    end

    test "double letters encode correctly" do
      # aa = 26, ab = 27, ..., az = 51, ba = 52, ..., zz = 701
      double_letter_cases = [
        {26, "aa"},
        {27, "ab"},
        {51, "az"},
        {52, "ba"},
        {701, "zz"}
      ]

      for {index, expected_letters} <- double_letter_cases do
        assert {:ok, ^expected_letters} = Cell.from_indices({index})
        assert {:ok, {^index}} = Cell.to_indices(expected_letters)
      end
    end

    test "triple letters encode correctly" do
      # aaa = 702
      assert {:ok, "aaa"} = Cell.from_indices({702})
      assert {:ok, {702}} = Cell.to_indices("aaa")
    end
  end

  # ============================================================================
  # GAME-SPECIFIC TESTS
  # ============================================================================

  describe "chess board (8×8)" do
    test "all chess squares are valid" do
      chess_squares =
        for file <- ?a..?h, rank <- 1..8 do
          "#{<<file>>}#{rank}"
        end

      assert Enum.all?(chess_squares, &Cell.valid?/1)
    end

    test "specific chess positions convert correctly" do
      assert {:ok, {4, 3}} = Cell.to_indices("e4")
      assert {:ok, {7, 7}} = Cell.to_indices("h8")
      assert {:ok, {0, 0}} = Cell.to_indices("a1")

      assert {:ok, "e4"} = Cell.from_indices({4, 3})
      assert {:ok, "h8"} = Cell.from_indices({7, 7})
    end
  end

  describe "shogi board (9×9)" do
    test "shogi positions are valid" do
      assert Cell.valid?("e5")
      assert Cell.valid?("i9")
      assert Cell.valid?("a1")
    end

    test "shogi center position converts correctly" do
      assert {:ok, {4, 4}} = Cell.to_indices("e5")
    end
  end

  describe "3D tic-tac-toe (3×3×3)" do
    test "3D positions are valid and have correct dimensions" do
      positions_3d = ["a1A", "b2B", "c3C", "a3A", "c1C"]

      for coord <- positions_3d do
        assert Cell.valid?(coord), "3D coordinate #{inspect(coord)} should be valid"
        assert Cell.dimensions(coord) == 3, "3D coordinate should have 3 dimensions"

        # Ensure indices are in valid range for 3×3×3
        {:ok, indices} = Cell.to_indices(coord)

        indices
        |> Tuple.to_list()
        |> Enum.each(fn index ->
          assert index in 0..2, "Index #{index} should be 0-2 for #{inspect(coord)}"
        end)
      end
    end

    test "3D diagonal win converts correctly" do
      diagonal_positions = ["a1A", "b2B", "c3C"]
      expected_diagonal = [{0, 0, 0}, {1, 1, 1}, {2, 2, 2}]

      actual_diagonal = Enum.map(diagonal_positions, &Cell.to_indices!/1)

      assert actual_diagonal == expected_diagonal
    end
  end

  # ============================================================================
  # EDGE CASES AND BOUNDARY CONDITIONS
  # ============================================================================

  describe "edge cases" do
    test "large coordinate values are handled correctly" do
      large_coords = ["z26Z", "aa27AA", "zz702ZZ", "abc999XYZ"]

      for coord <- large_coords do
        assert Cell.valid?(coord), "Large coordinate #{inspect(coord)} should be valid"

        indices = Cell.to_indices!(coord)
        converted_back = Cell.from_indices!(indices)

        assert converted_back == coord,
               "Round-trip failed for large coordinate #{inspect(coord)}"
      end
    end

    test "high-dimensional coordinates are handled correctly" do
      high_dim_coords = ["a1Aa1Aa1A", "b2Bb2Bb2B"]

      for coord <- high_dim_coords do
        assert Cell.valid?(coord), "High-dimensional coordinate #{inspect(coord)} should be valid"

        components = Cell.parse!(coord)
        assert Cell.dimensions(coord) == length(components)
      end
    end

    test "numeric boundary conditions are respected" do
      # Various numeric components
      numeric_coords = ["a1", "a10", "a100", "a999"]

      for coord <- numeric_coords do
        assert Cell.valid?(coord), "Numeric coordinate #{inspect(coord)} should be valid"

        [_letters, numeric_str] = Cell.parse!(coord)
        expected_index = String.to_integer(numeric_str) - 1

        {:ok, {_letter_index, actual_numeric_index}} = Cell.to_indices(coord)

        assert actual_numeric_index == expected_index,
               "Numeric component #{numeric_str} should convert to #{expected_index}"
      end

      # Verify zero is rejected
      zero_coords = ["a0", "a0A", "a01A", "aa0AA", "a1Aa0"]

      for coord <- zero_coords do
        refute Cell.valid?(coord),
               "Zero-containing coordinate #{inspect(coord)} should be invalid"
      end
    end

    test "leading zeros in numeric dimension are rejected" do
      leading_zero_coords = ["a01", "a001", "a01A", "a001A"]

      for coord <- leading_zero_coords do
        refute Cell.valid?(coord),
               "Leading zero coordinate #{inspect(coord)} should be invalid"
      end
    end
  end

  describe "API consistency" do
    test "methods are stateless and consistent" do
      test_coord = "e4"

      # Test that repeated calls give consistent results
      for _ <- 1..5 do
        assert Cell.valid?(test_coord) == true
        assert Cell.dimensions(test_coord) == 2
        assert Cell.parse(test_coord) == {:ok, ["e", "4"]}
        assert Cell.to_indices(test_coord) == {:ok, {4, 3}}
      end

      for _ <- 1..5 do
        assert Cell.from_indices({4, 3}) == {:ok, "e4"}
      end
    end
  end

  # ============================================================================
  # SPECIFICATION CONSTRAINTS VERIFICATION
  # ============================================================================

  describe "specification constraints" do
    test "only ASCII characters are valid" do
      assert Cell.valid?("abc123XYZ")
      refute Cell.valid?("café")
      refute Cell.valid?("αβγ")
    end

    test "must start with dimension 1 (lowercase)" do
      refute Cell.valid?("1a")
      refute Cell.valid?("A1a")
    end

    test "must follow cyclical progression" do
      refute Cell.valid?("aA")
      refute Cell.valid?("a1a")
      refute Cell.valid?("a1A1")
    end

    test "partial completion is allowed" do
      assert Cell.valid?("a")
      assert Cell.valid?("a1")
      assert Cell.valid?("a1A")
      assert Cell.valid?("a1Aa")
      assert Cell.valid?("a1Aa1")
    end

    test "mixed case is invalid" do
      refute Cell.valid?("aBc")
      refute Cell.valid?("AbC")
    end
  end
end
