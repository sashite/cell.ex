defmodule Sashite.Cell.FormatterTest do
  use ExUnit.Case, async: true

  alias Sashite.Cell.Formatter

  doctest Formatter

  describe "format/1 with valid inputs" do
    test "formats 1D coordinates" do
      assert Formatter.format({0}) == {:ok, "a"}
      assert Formatter.format({4}) == {:ok, "e"}
      assert Formatter.format({25}) == {:ok, "z"}
    end

    test "formats 2D coordinates" do
      assert Formatter.format({0, 0}) == {:ok, "a1"}
      assert Formatter.format({4, 3}) == {:ok, "e4"}
      assert Formatter.format({7, 7}) == {:ok, "h8"}
    end

    test "formats 3D coordinates" do
      assert Formatter.format({0, 0, 0}) == {:ok, "a1A"}
      assert Formatter.format({1, 1, 1}) == {:ok, "b2B"}
      assert Formatter.format({2, 2, 2}) == {:ok, "c3C"}
    end

    test "formats multi-letter file coordinates" do
      assert Formatter.format({26, 0}) == {:ok, "aa1"}
      assert Formatter.format({27, 0}) == {:ok, "ab1"}
      assert Formatter.format({51, 0}) == {:ok, "az1"}
      assert Formatter.format({52, 0}) == {:ok, "ba1"}
    end

    test "formats multi-digit rank coordinates" do
      assert Formatter.format({0, 9}) == {:ok, "a10"}
      assert Formatter.format({0, 98}) == {:ok, "a99"}
      assert Formatter.format({0, 255}) == {:ok, "a256"}
    end

    test "formats multi-letter layer coordinates" do
      assert Formatter.format({0, 0, 26}) == {:ok, "a1AA"}
      assert Formatter.format({0, 0, 27}) == {:ok, "a1AB"}
    end

    test "formats maximum valid coordinate" do
      assert Formatter.format({255, 255, 255}) == {:ok, "iv256IV"}
    end

    test "formats boundary values correctly" do
      # Single to double letter boundary
      assert Formatter.format({25, 0}) == {:ok, "z1"}
      assert Formatter.format({26, 0}) == {:ok, "aa1"}

      # Max single letter index
      assert Formatter.format({255, 0}) == {:ok, "iv1"}
    end
  end

  describe "format/1 with invalid inputs" do
    test "rejects index exceeding 255" do
      assert Formatter.format({256, 0}) == {:error, "index exceeds 255"}
      assert Formatter.format({0, 256}) == {:error, "index exceeds 255"}
      assert Formatter.format({0, 0, 256}) == {:error, "index exceeds 255"}
    end

    test "rejects negative indices" do
      assert Formatter.format({-1, 0}) == {:error, "index exceeds 255"}
    end

    test "rejects empty tuple" do
      assert Formatter.format({}) == {:error, "invalid dimensions"}
    end

    test "rejects tuple with more than 3 dimensions" do
      assert Formatter.format({0, 0, 0, 0}) == {:error, "invalid dimensions"}
    end

    test "rejects non-tuple input" do
      assert Formatter.format([0, 0]) == {:error, "invalid coordinate"}
      assert Formatter.format(%{x: 0, y: 0}) == {:error, "invalid coordinate"}
      assert Formatter.format("a1") == {:error, "invalid coordinate"}
      assert Formatter.format(nil) == {:error, "invalid coordinate"}
    end

    test "rejects non-integer tuple elements" do
      assert Formatter.format({0.5, 0}) == {:error, "index exceeds 255"}
      assert Formatter.format({"a", 0}) == {:error, "index exceeds 255"}
      assert Formatter.format({nil, 0}) == {:error, "index exceeds 255"}
    end
  end

  describe "format!/1" do
    test "returns string on valid input" do
      assert Formatter.format!({4, 3}) == "e4"
      assert Formatter.format!({0, 0, 0}) == "a1A"
    end

    test "raises ArgumentError on invalid input" do
      assert_raise ArgumentError, "index exceeds 255", fn ->
        Formatter.format!({256, 0})
      end

      assert_raise ArgumentError, "invalid dimensions", fn ->
        Formatter.format!({})
      end
    end
  end
end
