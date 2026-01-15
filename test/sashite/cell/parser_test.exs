defmodule Sashite.Cell.ParserTest do
  use ExUnit.Case, async: true

  alias Sashite.Cell.Parser

  doctest Parser

  describe "parse/1 with valid inputs" do
    test "parses 1D coordinates" do
      assert Parser.parse("a") == {:ok, {0}}
      assert Parser.parse("e") == {:ok, {4}}
      assert Parser.parse("z") == {:ok, {25}}
    end

    test "parses 2D coordinates" do
      assert Parser.parse("a1") == {:ok, {0, 0}}
      assert Parser.parse("e4") == {:ok, {4, 3}}
      assert Parser.parse("h8") == {:ok, {7, 7}}
    end

    test "parses 3D coordinates" do
      assert Parser.parse("a1A") == {:ok, {0, 0, 0}}
      assert Parser.parse("b2B") == {:ok, {1, 1, 1}}
      assert Parser.parse("c3C") == {:ok, {2, 2, 2}}
    end

    test "parses multi-letter file coordinates" do
      assert Parser.parse("aa1") == {:ok, {26, 0}}
      assert Parser.parse("ab1") == {:ok, {27, 0}}
      assert Parser.parse("az1") == {:ok, {51, 0}}
      assert Parser.parse("ba1") == {:ok, {52, 0}}
    end

    test "parses multi-digit rank coordinates" do
      assert Parser.parse("a10") == {:ok, {0, 9}}
      assert Parser.parse("a99") == {:ok, {0, 98}}
      assert Parser.parse("a256") == {:ok, {0, 255}}
    end

    test "parses multi-letter layer coordinates" do
      assert Parser.parse("a1AA") == {:ok, {0, 0, 26}}
      assert Parser.parse("a1AB") == {:ok, {0, 0, 27}}
    end

    test "parses maximum valid coordinate" do
      # iv256IV = {255, 255, 255}
      assert Parser.parse("iv256IV") == {:ok, {255, 255, 255}}
    end
  end

  describe "parse/1 with invalid inputs" do
    test "rejects empty string" do
      assert Parser.parse("") == {:error, "empty input"}
    end

    test "rejects input exceeding max length" do
      assert Parser.parse("aaaaaaaa") == {:error, "input exceeds 7 characters"}
      assert Parser.parse("a1234567") == {:error, "input exceeds 7 characters"}
    end

    test "rejects input starting with digit" do
      assert Parser.parse("1") == {:error, "must start with lowercase letter"}
      assert Parser.parse("1a") == {:error, "must start with lowercase letter"}
      assert Parser.parse("9e4") == {:error, "must start with lowercase letter"}
    end

    test "rejects input starting with uppercase" do
      assert Parser.parse("A") == {:error, "must start with lowercase letter"}
      assert Parser.parse("A1") == {:error, "must start with lowercase letter"}
    end

    test "rejects leading zero in rank" do
      assert Parser.parse("a0") == {:error, "leading zero"}
      assert Parser.parse("a01") == {:error, "leading zero"}
      assert Parser.parse("e00") == {:error, "leading zero"}
    end

    test "rejects missing numeric dimension" do
      assert Parser.parse("aA") == {:error, "unexpected character"}
    end

    test "rejects missing uppercase dimension before lowercase" do
      assert Parser.parse("a1a") == {:error, "unexpected character"}
    end

    test "rejects exceeding 3 dimensions" do
      assert Parser.parse("a1Aa") == {:error, "exceeds 3 dimensions"}
    end

    test "rejects index exceeding 255 in file" do
      # "ja" would be index 26*9 + 0 = 234, still valid
      # We need something > 255
      # iv = 26*8 + 21 = 229, still under
      # jj = 26*9 + 9 = 243, still under
      # Let's compute: we need x where x > 255
      # For two letters: value = 26 + first*26 + second
      # Max with valid = 26 + 8*26 + 21 = 255 (iv)
      # iw = 26 + 8*26 + 22 = 256 > 255
      assert Parser.parse("iw1") == {:error, "index exceeds 255"}
    end

    test "rejects index exceeding 255 in rank" do
      assert Parser.parse("a257") == {:error, "index exceeds 255"}
      assert Parser.parse("a999") == {:error, "index exceeds 255"}
    end

    test "rejects index exceeding 255 in layer" do
      assert Parser.parse("a1IW") == {:error, "index exceeds 255"}
    end

    test "rejects unexpected characters" do
      assert Parser.parse("a-1") == {:error, "unexpected character"}
      assert Parser.parse("a_1") == {:error, "unexpected character"}
      assert Parser.parse("a 1") == {:error, "unexpected character"}
      assert Parser.parse("a1!") == {:error, "unexpected character"}
    end

    test "rejects non-ASCII characters" do
      assert Parser.parse("é1") == {:error, "must start with lowercase letter"}
      assert Parser.parse("a①") == {:error, "unexpected character"}
    end

    test "rejects non-string input" do
      assert Parser.parse(nil) == {:error, "invalid input type"}
      assert Parser.parse(123) == {:error, "invalid input type"}
      assert Parser.parse([]) == {:error, "invalid input type"}
      assert Parser.parse(%{}) == {:error, "invalid input type"}
    end
  end

  describe "parse/1 security cases" do
    test "handles very long strings efficiently" do
      # Should reject immediately without parsing
      long_string = String.duplicate("a", 1000)
      assert Parser.parse(long_string) == {:error, "input exceeds 7 characters"}
    end

    test "handles binary with null bytes" do
      assert Parser.parse("a\0001") == {:error, "unexpected character"}
      assert Parser.parse("\000a1") == {:error, "must start with lowercase letter"}
    end

    test "handles strings with control characters" do
      assert Parser.parse("a\n1") == {:error, "unexpected character"}
      assert Parser.parse("a\t1") == {:error, "unexpected character"}
      assert Parser.parse("a\r1") == {:error, "unexpected character"}
    end

    test "handles unicode edge cases" do
      # UTF-8 multi-byte sequences
      assert Parser.parse("a1Ω") == {:error, "unexpected character"}
      assert Parser.parse("αβγ") == {:error, "must start with lowercase letter"}
    end
  end

  describe "parse!/1" do
    test "returns coordinate on valid input" do
      assert Parser.parse!("e4") == {4, 3}
      assert Parser.parse!("a1A") == {0, 0, 0}
    end

    test "raises ArgumentError on invalid input" do
      assert_raise ArgumentError, "empty input", fn ->
        Parser.parse!("")
      end

      assert_raise ArgumentError, "leading zero", fn ->
        Parser.parse!("a0")
      end
    end
  end
end
