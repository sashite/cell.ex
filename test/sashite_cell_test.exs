defmodule Sashite.CellTest do
  use ExUnit.Case, async: true

  doctest Sashite.Cell

  describe "to_indices/1" do
    test "parses common chess coordinates" do
      assert Sashite.Cell.to_indices("a1") == {:ok, {0, 0}}
      assert Sashite.Cell.to_indices("e4") == {:ok, {4, 3}}
      assert Sashite.Cell.to_indices("h8") == {:ok, {7, 7}}
    end

    test "returns error tuple on invalid input" do
      assert Sashite.Cell.to_indices("") == {:error, "empty input"}
      assert Sashite.Cell.to_indices("a0") == {:error, "leading zero"}
    end
  end

  describe "to_indices!/1" do
    test "returns coordinate on valid input" do
      assert Sashite.Cell.to_indices!("e4") == {4, 3}
    end

    test "raises on invalid input" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.to_indices!("")
      end
    end
  end

  describe "from_indices/1" do
    test "formats common chess coordinates" do
      assert Sashite.Cell.from_indices({0, 0}) == {:ok, "a1"}
      assert Sashite.Cell.from_indices({4, 3}) == {:ok, "e4"}
      assert Sashite.Cell.from_indices({7, 7}) == {:ok, "h8"}
    end

    test "returns error tuple on invalid input" do
      assert Sashite.Cell.from_indices({256, 0}) == {:error, "index exceeds 255"}
      assert Sashite.Cell.from_indices({}) == {:error, "invalid dimensions"}
    end
  end

  describe "from_indices!/1" do
    test "returns string on valid input" do
      assert Sashite.Cell.from_indices!({4, 3}) == "e4"
    end

    test "raises on invalid input" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.from_indices!({256, 0})
      end
    end
  end

  describe "valid?/1" do
    test "returns true for valid coordinates" do
      assert Sashite.Cell.valid?("a1")
      assert Sashite.Cell.valid?("e4")
      assert Sashite.Cell.valid?("a1A")
      assert Sashite.Cell.valid?("iv256IV")
    end

    test "returns false for invalid coordinates" do
      refute Sashite.Cell.valid?("")
      refute Sashite.Cell.valid?("a0")
      refute Sashite.Cell.valid?("1a")
      refute Sashite.Cell.valid?("invalid")
    end

    test "returns false for non-string input" do
      refute Sashite.Cell.valid?(nil)
      refute Sashite.Cell.valid?(123)
      refute Sashite.Cell.valid?([])
    end
  end

  describe "round-trip conversion" do
    test "string -> indices -> string preserves value" do
      coordinates = ["a1", "e4", "h8", "a1A", "b2B", "aa1", "a10", "iv256IV"]

      for coord <- coordinates do
        assert coord
               |> Sashite.Cell.to_indices!()
               |> Sashite.Cell.from_indices!() == coord
      end
    end

    test "indices -> string -> indices preserves value" do
      indices = [
        {0, 0},
        {4, 3},
        {7, 7},
        {0, 0, 0},
        {1, 1, 1},
        {26, 0},
        {0, 9},
        {255, 255, 255}
      ]

      for idx <- indices do
        assert idx
               |> Sashite.Cell.from_indices!()
               |> Sashite.Cell.to_indices!() == idx
      end
    end

    test "all valid 2D chess coordinates round-trip" do
      for file <- 0..7, rank <- 0..7 do
        indices = {file, rank}

        assert indices
               |> Sashite.Cell.from_indices!()
               |> Sashite.Cell.to_indices!() == indices
      end
    end

    test "all valid 2D shogi coordinates round-trip" do
      for file <- 0..8, rank <- 0..8 do
        indices = {file, rank}

        assert indices
               |> Sashite.Cell.from_indices!()
               |> Sashite.Cell.to_indices!() == indices
      end
    end
  end

  describe "game-specific coordinates" do
    test "chess coordinates" do
      # Standard chess squares
      assert Sashite.Cell.to_indices!("a1") == {0, 0}
      assert Sashite.Cell.to_indices!("e4") == {4, 3}
      assert Sashite.Cell.to_indices!("d4") == {3, 3}
      assert Sashite.Cell.to_indices!("h8") == {7, 7}
    end

    test "shogi coordinates" do
      # 9x9 board
      assert Sashite.Cell.to_indices!("e5") == {4, 4}
      assert Sashite.Cell.to_indices!("i9") == {8, 8}
    end

    test "3D tic-tac-toe coordinates" do
      assert Sashite.Cell.to_indices!("a1A") == {0, 0, 0}
      assert Sashite.Cell.to_indices!("b2B") == {1, 1, 1}
      assert Sashite.Cell.to_indices!("c3C") == {2, 2, 2}
    end
  end
end
