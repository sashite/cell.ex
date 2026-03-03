defmodule Sashite.Cell.ValidTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # valid?/1 — acceptance: 1D coordinates
  # ===========================================================================

  describe "valid?/1 accepts 1D coordinates" do
    test "single letter minimum" do
      assert Sashite.Cell.valid?("a")
    end

    test "single letter maximum" do
      assert Sashite.Cell.valid?("z")
    end

    test "double letter minimum" do
      assert Sashite.Cell.valid?("aa")
    end

    test "double letter maximum" do
      assert Sashite.Cell.valid?("iv")
    end
  end

  # ===========================================================================
  # valid?/1 — acceptance: 2D coordinates
  # ===========================================================================

  describe "valid?/1 accepts 2D coordinates" do
    test "minimum coordinate" do
      assert Sashite.Cell.valid?("a1")
    end

    test "typical chess coordinate" do
      assert Sashite.Cell.valid?("e4")
    end

    test "double letter file with rank" do
      assert Sashite.Cell.valid?("aa1")
    end

    test "maximum rank" do
      assert Sashite.Cell.valid?("a256")
    end

    test "maximum file with rank" do
      assert Sashite.Cell.valid?("iv1")
    end
  end

  # ===========================================================================
  # valid?/1 — acceptance: 3D coordinates
  # ===========================================================================

  describe "valid?/1 accepts 3D coordinates" do
    test "minimum 3D coordinate" do
      assert Sashite.Cell.valid?("a1A")
    end

    test "double letter layer" do
      assert Sashite.Cell.valid?("a1AA")
    end

    test "maximum 3D coordinate" do
      assert Sashite.Cell.valid?("iv256IV")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: non-string input
  # ===========================================================================

  describe "valid?/1 rejects non-string input" do
    test "nil" do
      refute Sashite.Cell.valid?(nil)
    end

    test "integer" do
      refute Sashite.Cell.valid?(42)
    end

    test "atom" do
      refute Sashite.Cell.valid?(:a1)
    end

    test "list" do
      refute Sashite.Cell.valid?([?a, ?1])
    end

    test "tuple" do
      refute Sashite.Cell.valid?({0, 0})
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: empty and oversized
  # ===========================================================================

  describe "valid?/1 rejects empty and oversized input" do
    test "empty string" do
      refute Sashite.Cell.valid?("")
    end

    test "exceeds max string length" do
      refute Sashite.Cell.valid?("iv256IVx")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: wrong first character
  # ===========================================================================

  describe "valid?/1 rejects wrong first character" do
    test "starts with uppercase" do
      refute Sashite.Cell.valid?("A1")
    end

    test "starts with digit" do
      refute Sashite.Cell.valid?("1a")
    end

    test "starts with special character" do
      refute Sashite.Cell.valid?("+a")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: invalid numeric dimension
  # ===========================================================================

  describe "valid?/1 rejects invalid numeric dimension" do
    test "zero rank" do
      refute Sashite.Cell.valid?("a0")
    end

    test "leading zero" do
      refute Sashite.Cell.valid?("a01")
    end

    test "rank exceeds 256" do
      refute Sashite.Cell.valid?("a257")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: index out of range
  # ===========================================================================

  describe "valid?/1 rejects index out of range" do
    test "triple lowercase letter (index >= 702)" do
      refute Sashite.Cell.valid?("aaa")
    end

    test "double lowercase exceeding 255 (iw = 256)" do
      refute Sashite.Cell.valid?("iw")
    end

    test "triple uppercase letter" do
      refute Sashite.Cell.valid?("a1AAA")
    end

    test "double uppercase exceeding 255 (IW = 256)" do
      refute Sashite.Cell.valid?("a1IW")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: skipped dimensions
  # ===========================================================================

  describe "valid?/1 rejects skipped dimensions" do
    test "uppercase directly after lowercase" do
      refute Sashite.Cell.valid?("aA")
    end

    test "lowercase directly after digit" do
      refute Sashite.Cell.valid?("a1a")
    end

    test "digit directly after uppercase" do
      refute Sashite.Cell.valid?("a1A1")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: exceeds max dimensions
  # ===========================================================================

  describe "valid?/1 rejects exceeding max dimensions" do
    test "lowercase after uppercase starts dimension 4" do
      refute Sashite.Cell.valid?("a1Ab")
    end
  end

  # ===========================================================================
  # valid?/1 — rejection: unexpected characters
  # ===========================================================================

  describe "valid?/1 rejects unexpected characters" do
    test "space in coordinate" do
      refute Sashite.Cell.valid?("a 1")
    end

    test "hyphen in coordinate" do
      refute Sashite.Cell.valid?("a-1")
    end

    test "underscore in coordinate" do
      refute Sashite.Cell.valid?("a_1")
    end

    test "newline in coordinate" do
      refute Sashite.Cell.valid?("a1\n")
    end
  end
end
