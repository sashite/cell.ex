defmodule Sashite.Cell.CoordinateTest do
  use ExUnit.Case, async: true

  alias Sashite.Cell.Coordinate

  describe "constants" do
    test "max_dimensions is 3" do
      assert Coordinate.max_dimensions() == 3
    end

    test "max_index_value is 255" do
      assert Coordinate.max_index_value() == 255
    end

    test "max_string_length is 7" do
      assert Coordinate.max_string_length() == 7
    end
  end

  describe "new/1" do
    test "creates 1D coordinate" do
      assert Coordinate.new({0}) == {:ok, {0}}
      assert Coordinate.new({255}) == {:ok, {255}}
    end

    test "creates 2D coordinate" do
      assert Coordinate.new({0, 0}) == {:ok, {0, 0}}
      assert Coordinate.new({255, 255}) == {:ok, {255, 255}}
    end

    test "creates 3D coordinate" do
      assert Coordinate.new({0, 0, 0}) == {:ok, {0, 0, 0}}
      assert Coordinate.new({255, 255, 255}) == {:ok, {255, 255, 255}}
    end

    test "rejects index exceeding 255" do
      assert Coordinate.new({256}) == {:error, "index exceeds 255"}
      assert Coordinate.new({0, 256}) == {:error, "index exceeds 255"}
      assert Coordinate.new({0, 0, 256}) == {:error, "index exceeds 255"}
    end

    test "rejects negative index" do
      assert Coordinate.new({-1}) == {:error, "index exceeds 255"}
    end

    test "rejects empty tuple" do
      assert Coordinate.new({}) == {:error, "invalid dimensions"}
    end

    test "rejects tuple with more than 3 elements" do
      assert Coordinate.new({0, 0, 0, 0}) == {:error, "invalid dimensions"}
    end

    test "rejects non-tuple input" do
      assert Coordinate.new([0, 0]) == {:error, "invalid coordinate"}
      assert Coordinate.new(nil) == {:error, "invalid coordinate"}
    end
  end

  describe "new!/1" do
    test "returns coordinate on valid input" do
      assert Coordinate.new!({4, 3}) == {4, 3}
    end

    test "raises ArgumentError on invalid input" do
      assert_raise ArgumentError, "index exceeds 255", fn ->
        Coordinate.new!({256, 0})
      end
    end
  end

  describe "is_valid_index/1 guard" do
    test "accepts valid indices" do
      require Coordinate

      assert Coordinate.is_valid_index(0)
      assert Coordinate.is_valid_index(127)
      assert Coordinate.is_valid_index(255)
    end

    test "rejects invalid indices" do
      require Coordinate

      refute Coordinate.is_valid_index(-1)
      refute Coordinate.is_valid_index(256)
      refute Coordinate.is_valid_index(1000)
    end
  end
end
