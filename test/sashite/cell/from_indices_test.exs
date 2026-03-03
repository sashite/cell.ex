defmodule Sashite.Cell.FromIndicesTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # from_indices/1 — happy paths: 1D coordinates
  # ===========================================================================

  describe "from_indices/1 1D coordinates" do
    test "single letter minimum (index 0)" do
      assert {:ok, "a"} = Sashite.Cell.from_indices({0})
    end

    test "single letter maximum (index 25)" do
      assert {:ok, "z"} = Sashite.Cell.from_indices({25})
    end

    test "single letter middle (index 4)" do
      assert {:ok, "e"} = Sashite.Cell.from_indices({4})
    end

    test "double letter minimum (index 26)" do
      assert {:ok, "aa"} = Sashite.Cell.from_indices({26})
    end

    test "double letter maximum (index 255)" do
      assert {:ok, "iv"} = Sashite.Cell.from_indices({255})
    end

    test "double letter boundary az (index 51)" do
      assert {:ok, "az"} = Sashite.Cell.from_indices({51})
    end

    test "double letter ba (index 52)" do
      assert {:ok, "ba"} = Sashite.Cell.from_indices({52})
    end
  end

  # ===========================================================================
  # from_indices/1 — happy paths: 2D coordinates
  # ===========================================================================

  describe "from_indices/1 2D coordinates" do
    test "minimum coordinate" do
      assert {:ok, "a1"} = Sashite.Cell.from_indices({0, 0})
    end

    test "typical chess coordinate" do
      assert {:ok, "e4"} = Sashite.Cell.from_indices({4, 3})
    end

    test "single-digit rank boundary (index 8 → rank 9)" do
      assert {:ok, "a9"} = Sashite.Cell.from_indices({0, 8})
    end

    test "two-digit rank minimum (index 9 → rank 10)" do
      assert {:ok, "a10"} = Sashite.Cell.from_indices({0, 9})
    end

    test "two-digit rank maximum (index 98 → rank 99)" do
      assert {:ok, "a99"} = Sashite.Cell.from_indices({0, 98})
    end

    test "three-digit rank minimum (index 99 → rank 100)" do
      assert {:ok, "a100"} = Sashite.Cell.from_indices({0, 99})
    end

    test "three-digit rank maximum (index 255 → rank 256)" do
      assert {:ok, "a256"} = Sashite.Cell.from_indices({0, 255})
    end

    test "double letter file with rank" do
      assert {:ok, "aa1"} = Sashite.Cell.from_indices({26, 0})
    end
  end

  # ===========================================================================
  # from_indices/1 — happy paths: 3D coordinates
  # ===========================================================================

  describe "from_indices/1 3D coordinates" do
    test "minimum 3D coordinate" do
      assert {:ok, "a1A"} = Sashite.Cell.from_indices({0, 0, 0})
    end

    test "single letters all dimensions" do
      assert {:ok, "e4B"} = Sashite.Cell.from_indices({4, 3, 1})
    end

    test "single uppercase letter maximum (index 25)" do
      assert {:ok, "a1Z"} = Sashite.Cell.from_indices({0, 0, 25})
    end

    test "double uppercase letter minimum (index 26)" do
      assert {:ok, "a1AA"} = Sashite.Cell.from_indices({0, 0, 26})
    end

    test "double uppercase letter maximum (index 255)" do
      assert {:ok, "iv256IV"} = Sashite.Cell.from_indices({255, 255, 255})
    end

    test "mixed dimensions" do
      assert {:ok, "c3C"} = Sashite.Cell.from_indices({2, 2, 2})
    end
  end

  # ===========================================================================
  # from_indices/1 — error paths: index out of range
  # ===========================================================================

  describe "from_indices/1 index out of range errors" do
    test "1D index exceeds 255" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({256})
    end

    test "1D negative index" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({-1})
    end

    test "2D first index exceeds 255" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({256, 0})
    end

    test "2D second index exceeds 255" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({0, 256})
    end

    test "2D negative second index" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({0, -1})
    end

    test "3D third index exceeds 255" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({0, 0, 256})
    end

    test "3D negative third index" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({0, 0, -1})
    end

    test "non-integer element" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({"a"})
    end

    test "float element" do
      assert {:error, :index_out_of_range} = Sashite.Cell.from_indices({1.5})
    end
  end

  # ===========================================================================
  # from_indices/1 — error paths: invalid dimensions
  # ===========================================================================

  describe "from_indices/1 invalid dimensions errors" do
    test "empty tuple" do
      assert {:error, :invalid_dimensions} = Sashite.Cell.from_indices({})
    end

    test "4-element tuple" do
      assert {:error, :invalid_dimensions} = Sashite.Cell.from_indices({0, 0, 0, 0})
    end

    test "5-element tuple" do
      assert {:error, :invalid_dimensions} = Sashite.Cell.from_indices({0, 0, 0, 0, 0})
    end
  end

  # ===========================================================================
  # from_indices/1 — error paths: not a tuple
  # ===========================================================================

  describe "from_indices/1 not a tuple errors" do
    test "list input" do
      assert {:error, :not_a_tuple} = Sashite.Cell.from_indices([0, 0])
    end

    test "string input" do
      assert {:error, :not_a_tuple} = Sashite.Cell.from_indices("a1")
    end

    test "nil input" do
      assert {:error, :not_a_tuple} = Sashite.Cell.from_indices(nil)
    end

    test "integer input" do
      assert {:error, :not_a_tuple} = Sashite.Cell.from_indices(42)
    end
  end

  # ===========================================================================
  # from_indices!/1 — bang variant
  # ===========================================================================

  describe "from_indices!/1 bang variant" do
    test "returns string on valid input" do
      assert "e4" = Sashite.Cell.from_indices!({4, 3})
    end

    test "raises ArgumentError on out of range" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.from_indices!({256, 0})
      end
    end

    test "raises ArgumentError on invalid dimensions" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.from_indices!({})
      end
    end

    test "raises ArgumentError on non-tuple" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.from_indices!(nil)
      end
    end
  end
end
