defmodule Sashite.Cell.ToIndicesTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # to_indices/1 — happy paths: 1D coordinates
  # ===========================================================================

  describe "to_indices/1 1D coordinates" do
    test "single letter minimum" do
      assert {:ok, {0}} = Sashite.Cell.to_indices("a")
    end

    test "single letter maximum" do
      assert {:ok, {25}} = Sashite.Cell.to_indices("z")
    end

    test "single letter middle" do
      assert {:ok, {4}} = Sashite.Cell.to_indices("e")
    end

    test "double letter minimum" do
      assert {:ok, {26}} = Sashite.Cell.to_indices("aa")
    end

    test "double letter maximum (iv = 255)" do
      assert {:ok, {255}} = Sashite.Cell.to_indices("iv")
    end

    test "double letter boundary (az = 51)" do
      assert {:ok, {51}} = Sashite.Cell.to_indices("az")
    end

    test "double letter ba = 52" do
      assert {:ok, {52}} = Sashite.Cell.to_indices("ba")
    end
  end

  # ===========================================================================
  # to_indices/1 — happy paths: 2D coordinates
  # ===========================================================================

  describe "to_indices/1 2D coordinates" do
    test "minimum coordinate a1" do
      assert {:ok, {0, 0}} = Sashite.Cell.to_indices("a1")
    end

    test "typical chess coordinate e4" do
      assert {:ok, {4, 3}} = Sashite.Cell.to_indices("e4")
    end

    test "rank boundary a9" do
      assert {:ok, {0, 8}} = Sashite.Cell.to_indices("a9")
    end

    test "two-digit rank a10" do
      assert {:ok, {0, 9}} = Sashite.Cell.to_indices("a10")
    end

    test "three-digit rank a256" do
      assert {:ok, {0, 255}} = Sashite.Cell.to_indices("a256")
    end

    test "double letter with rank aa1" do
      assert {:ok, {26, 0}} = Sashite.Cell.to_indices("aa1")
    end

    test "double letter with multi-digit rank aa10" do
      assert {:ok, {26, 9}} = Sashite.Cell.to_indices("aa10")
    end

    test "maximum file with minimum rank iv1" do
      assert {:ok, {255, 0}} = Sashite.Cell.to_indices("iv1")
    end
  end

  # ===========================================================================
  # to_indices/1 — happy paths: 3D coordinates
  # ===========================================================================

  describe "to_indices/1 3D coordinates" do
    test "minimum 3D coordinate a1A" do
      assert {:ok, {0, 0, 0}} = Sashite.Cell.to_indices("a1A")
    end

    test "single letters all dimensions e4B" do
      assert {:ok, {4, 3, 1}} = Sashite.Cell.to_indices("e4B")
    end

    test "maximum layer single letter a1Z" do
      assert {:ok, {0, 0, 25}} = Sashite.Cell.to_indices("a1Z")
    end

    test "double letter layer a1AA" do
      assert {:ok, {0, 0, 26}} = Sashite.Cell.to_indices("a1AA")
    end

    test "maximum 3D coordinate iv256IV" do
      assert {:ok, {255, 255, 255}} = Sashite.Cell.to_indices("iv256IV")
    end

    test "mixed dimensions c3C" do
      assert {:ok, {2, 2, 2}} = Sashite.Cell.to_indices("c3C")
    end
  end

  # ===========================================================================
  # to_indices/1 — error paths: input validation
  # ===========================================================================

  describe "to_indices/1 input validation errors" do
    test "empty string" do
      assert {:error, :empty_input} = Sashite.Cell.to_indices("")
    end

    test "exceeds max string length" do
      assert {:error, :input_too_long} = Sashite.Cell.to_indices("iv256IVx")
    end

    test "non-string input" do
      assert {:error, :not_a_string} = Sashite.Cell.to_indices(nil)
    end

    test "integer input" do
      assert {:error, :not_a_string} = Sashite.Cell.to_indices(42)
    end

    test "atom input" do
      assert {:error, :not_a_string} = Sashite.Cell.to_indices(:a1)
    end

    test "list input" do
      assert {:error, :not_a_string} = Sashite.Cell.to_indices([?a, ?1])
    end
  end

  # ===========================================================================
  # to_indices/1 — error paths: first character
  # ===========================================================================

  describe "to_indices/1 first character errors" do
    test "starts with uppercase" do
      assert {:error, :must_start_with_lowercase} = Sashite.Cell.to_indices("A1")
    end

    test "starts with digit" do
      assert {:error, :must_start_with_lowercase} = Sashite.Cell.to_indices("1a")
    end

    test "starts with special character" do
      assert {:error, :must_start_with_lowercase} = Sashite.Cell.to_indices("+a")
    end
  end

  # ===========================================================================
  # to_indices/1 — error paths: leading zero
  # ===========================================================================

  describe "to_indices/1 leading zero errors" do
    test "zero rank a0" do
      assert {:error, :leading_zero} = Sashite.Cell.to_indices("a0")
    end

    test "leading zero a01" do
      assert {:error, :leading_zero} = Sashite.Cell.to_indices("a01")
    end
  end

  # ===========================================================================
  # to_indices/1 — error paths: index out of range
  # ===========================================================================

  describe "to_indices/1 index out of range errors" do
    test "triple lowercase letter" do
      assert {:error, :index_out_of_range} = Sashite.Cell.to_indices("aaa")
    end

    test "double lowercase exceeding 255 (iw = 256)" do
      assert {:error, :index_out_of_range} = Sashite.Cell.to_indices("iw")
    end

    test "rank exceeding 256" do
      assert {:error, :input_too_long} = Sashite.Cell.to_indices("a1000000")
    end

    test "triple uppercase letter" do
      assert {:error, :index_out_of_range} = Sashite.Cell.to_indices("a1AAA")
    end

    test "double uppercase exceeding 255 (IW = 256)" do
      assert {:error, :index_out_of_range} = Sashite.Cell.to_indices("a1IW")
    end

    test "rank 257 (index 256)" do
      assert {:error, :index_out_of_range} = Sashite.Cell.to_indices("a257")
    end
  end

  # ===========================================================================
  # to_indices/1 — error paths: unexpected character
  # ===========================================================================

  describe "to_indices/1 unexpected character errors" do
    test "special character after lowercase" do
      assert {:error, :unexpected_character} = Sashite.Cell.to_indices("a-1")
    end

    test "uppercase directly after lowercase (skipped dimension)" do
      assert {:error, :unexpected_character} = Sashite.Cell.to_indices("aA")
    end

    test "special character after digit" do
      assert {:error, :unexpected_character} = Sashite.Cell.to_indices("a1-")
    end

    test "lowercase directly after digit (skipped dimension)" do
      assert {:error, :unexpected_character} = Sashite.Cell.to_indices("a1a")
    end

    test "special character after uppercase" do
      assert {:error, :unexpected_character} = Sashite.Cell.to_indices("a1A-")
    end

    test "digit after uppercase (skipped dimension)" do
      assert {:error, :unexpected_character} = Sashite.Cell.to_indices("a1A1")
    end
  end

  # ===========================================================================
  # to_indices/1 — error paths: exceeds max dimensions
  # ===========================================================================

  describe "to_indices/1 exceeds max dimensions" do
    test "lowercase after uppercase starts dimension 4" do
      assert {:error, :exceeds_max_dimensions} = Sashite.Cell.to_indices("a1Ab")
    end
  end

  # ===========================================================================
  # to_indices!/1 — bang variant
  # ===========================================================================

  describe "to_indices!/1 bang variant" do
    test "returns tuple on valid input" do
      assert {4, 3} = Sashite.Cell.to_indices!("e4")
    end

    test "raises ArgumentError on invalid input" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.to_indices!("")
      end
    end

    test "raises ArgumentError on non-string input" do
      assert_raise ArgumentError, fn ->
        Sashite.Cell.to_indices!(nil)
      end
    end
  end
end
