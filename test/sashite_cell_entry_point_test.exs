defmodule SashiteCellEntryPointTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Tests for the top-level SashiteCell module.

  Verifies that all delegations to Sashite.Cell work correctly.
  """

  describe "to_indices/1" do
    test "delegates to Sashite.Cell.to_indices/1" do
      assert SashiteCell.to_indices("e4") == {:ok, {4, 3}}
      assert SashiteCell.to_indices("a1A") == {:ok, {0, 0, 0}}
      assert SashiteCell.to_indices("") == {:error, "empty input"}
    end
  end

  describe "to_indices!/1" do
    test "delegates to Sashite.Cell.to_indices!/1" do
      assert SashiteCell.to_indices!("e4") == {4, 3}

      assert_raise ArgumentError, "empty input", fn ->
        SashiteCell.to_indices!("")
      end
    end
  end

  describe "from_indices/1" do
    test "delegates to Sashite.Cell.from_indices/1" do
      assert SashiteCell.from_indices({4, 3}) == {:ok, "e4"}
      assert SashiteCell.from_indices({0, 0, 0}) == {:ok, "a1A"}
      assert SashiteCell.from_indices({256, 0}) == {:error, "index exceeds 255"}
    end
  end

  describe "from_indices!/1" do
    test "delegates to Sashite.Cell.from_indices!/1" do
      assert SashiteCell.from_indices!({4, 3}) == "e4"

      assert_raise ArgumentError, "index exceeds 255", fn ->
        SashiteCell.from_indices!({256, 0})
      end
    end
  end

  describe "valid?/1" do
    test "delegates to Sashite.Cell.valid?/1" do
      assert SashiteCell.valid?("e4") == true
      assert SashiteCell.valid?("a1A") == true
      assert SashiteCell.valid?("") == false
      assert SashiteCell.valid?(nil) == false
    end
  end

  describe "round-trip via entry point" do
    test "maintains consistency with Sashite.Cell" do
      coordinates = ["a1", "e4", "h8", "a1A", "aa1", "iv256IV"]

      for coord <- coordinates do
        # Verify both modules return identical results
        assert SashiteCell.to_indices(coord) == Sashite.Cell.to_indices(coord)

        {:ok, indices} = SashiteCell.to_indices(coord)
        assert SashiteCell.from_indices(indices) == Sashite.Cell.from_indices(indices)
      end
    end
  end
end
