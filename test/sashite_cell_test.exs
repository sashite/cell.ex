defmodule SashiteCellTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # Constants
  # ===========================================================================

  describe "max_dimensions/0" do
    test "returns 3" do
      assert Sashite.Cell.max_dimensions() == 3
    end
  end

  describe "max_index_value/0" do
    test "returns 255" do
      assert Sashite.Cell.max_index_value() == 255
    end
  end

  describe "max_string_length/0" do
    test "returns 7" do
      assert Sashite.Cell.max_string_length() == 7
    end

    test "matches the length of the maximum coordinate" do
      {:ok, max_coord} = Sashite.Cell.from_indices({255, 255, 255})
      assert byte_size(max_coord) == Sashite.Cell.max_string_length()
    end
  end

  # ===========================================================================
  # Round-trip: parse then format
  # ===========================================================================

  describe "round-trip to_indices then from_indices" do
    test "1D single letter" do
      assert "e" == "e" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end

    test "1D double letter" do
      assert "aa" == "aa" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end

    test "1D maximum" do
      assert "iv" == "iv" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end

    test "2D typical" do
      assert "e4" == "e4" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end

    test "2D double letter file" do
      assert "aa10" == "aa10" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end

    test "3D minimum" do
      assert "a1A" == "a1A" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end

    test "3D maximum" do
      assert "iv256IV" == "iv256IV" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
    end
  end

  # ===========================================================================
  # Round-trip: format then parse
  # ===========================================================================

  describe "round-trip from_indices then to_indices" do
    test "1D minimum" do
      assert {0} == {0} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
    end

    test "1D maximum" do
      assert {255} == {255} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
    end

    test "2D typical" do
      assert {4, 3} == {4, 3} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
    end

    test "2D boundaries" do
      assert {255, 255} ==
               {255, 255} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
    end

    test "3D minimum" do
      assert {0, 0, 0} == {0, 0, 0} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
    end

    test "3D maximum" do
      assert {255, 255, 255} ==
               {255, 255, 255} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
    end
  end

  # ===========================================================================
  # Consistency: valid? agrees with to_indices
  # ===========================================================================

  describe "valid?/1 consistency with to_indices/1" do
    test "valid? returns true for all parseable coordinates" do
      coordinates = ["a", "z", "aa", "iv", "a1", "e4", "a256", "a1A", "iv256IV"]

      for coord <- coordinates do
        assert Sashite.Cell.valid?(coord), "expected valid?(#{inspect(coord)}) to be true"
        assert {:ok, _} = Sashite.Cell.to_indices(coord)
      end
    end

    test "valid? returns false for all unparseable inputs" do
      inputs = ["", "A1", "a0", "a01", "1a", "aA", "a1a", "a1A1", "a1Ab", "iw", "a1IW"]

      for input <- inputs do
        refute Sashite.Cell.valid?(input), "expected valid?(#{inspect(input)}) to be false"
        assert {:error, _} = Sashite.Cell.to_indices(input)
      end
    end
  end

  # ===========================================================================
  # Entry point: SashiteCell delegates correctly
  # ===========================================================================

  describe "SashiteCell entry point delegation" do
    test "to_indices/1 delegates" do
      assert SashiteCell.to_indices("e4") == Sashite.Cell.to_indices("e4")
    end

    test "to_indices!/1 delegates" do
      assert SashiteCell.to_indices!("e4") == Sashite.Cell.to_indices!("e4")
    end

    test "from_indices/1 delegates" do
      assert SashiteCell.from_indices({4, 3}) == Sashite.Cell.from_indices({4, 3})
    end

    test "from_indices!/1 delegates" do
      assert SashiteCell.from_indices!({4, 3}) == Sashite.Cell.from_indices!({4, 3})
    end

    test "valid?/1 delegates" do
      assert SashiteCell.valid?("e4") == Sashite.Cell.valid?("e4")
      assert SashiteCell.valid?("") == Sashite.Cell.valid?("")
    end

    test "max_dimensions/0 delegates" do
      assert SashiteCell.max_dimensions() == Sashite.Cell.max_dimensions()
    end

    test "max_index_value/0 delegates" do
      assert SashiteCell.max_index_value() == Sashite.Cell.max_index_value()
    end

    test "max_string_length/0 delegates" do
      assert SashiteCell.max_string_length() == Sashite.Cell.max_string_length()
    end
  end

  # ===========================================================================
  # Spec examples: §8 invalid coordinate examples
  # ===========================================================================

  describe "CELL spec §8 invalid coordinate examples" do
    test "empty string" do
      refute Sashite.Cell.valid?("")
    end

    test "starts with digit" do
      refute Sashite.Cell.valid?("1")
    end

    test "starts with uppercase" do
      refute Sashite.Cell.valid?("A")
    end

    test "zero is not a valid positive integer" do
      refute Sashite.Cell.valid?("a0")
    end

    test "leading zero in numeric dimension" do
      refute Sashite.Cell.valid?("a01")
    end

    test "missing numeric dimension between lowercase and uppercase" do
      refute Sashite.Cell.valid?("aA")
    end

    test "missing uppercase dimension between numeric and lowercase" do
      refute Sashite.Cell.valid?("a1a")
    end

    test "numeric after uppercase without restarting cycle" do
      refute Sashite.Cell.valid?("a1A1")
    end

    test "starts with digit instead of lowercase" do
      refute Sashite.Cell.valid?("1a")
    end
  end
end
