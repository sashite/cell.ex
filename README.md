# Sashite.Cell

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_cell.svg)](https://hex.pm/packages/sashite_cell)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_cell)
[![License](https://img.shields.io/hexpm/l/sashite_cell.svg)](https://github.com/sashite/cell.ex/blob/main/LICENSE.md)

> **CELL** (Coordinate Encoding for Layered Locations) implementation for Elixir.

## What is CELL?

CELL (Coordinate Encoding for Layered Locations) is a standardized format for representing coordinates on multi-dimensional game boards using a cyclical ASCII character system. CELL supports unlimited dimensional coordinate systems through the systematic repetition of three distinct character sets.

This library implements the [CELL Specification v1.0.0](https://sashite.dev/specs/cell/1.0.0/).

## Installation

Add `sashite_cell` to your list of dependencies in `mix.exs`:
```elixir
def deps do
  [
    {:sashite_cell, "~> 1.0"}
  ]
end
```

## CELL Format

CELL uses a cyclical three-character-set system that repeats indefinitely based on dimensional position:

| Dimension | Condition | Character Set | Examples |
|-----------|-----------|---------------|----------|
| 1st, 4th, 7th… | n % 3 = 1 | Latin lowercase (`a`–`z`) | `a`, `e`, `aa`, `file` |
| 2nd, 5th, 8th… | n % 3 = 2 | Positive integers | `1`, `8`, `10`, `256` |
| 3rd, 6th, 9th… | n % 3 = 0 | Latin uppercase (`A`–`Z`) | `A`, `C`, `AA`, `LAYER` |

## Usage
```elixir
alias Sashite.Cell

# Validation
Cell.valid?("a1")       # => true (2D coordinate)
Cell.valid?("a1A")      # => true (3D coordinate)
Cell.valid?("e4")       # => true (2D coordinate)
Cell.valid?("h8Hh8")    # => true (5D coordinate)
Cell.valid?("*")        # => false (not a CELL coordinate)
Cell.valid?("a0")       # => false (invalid numeral)
Cell.valid?("")         # => false (empty string)

# Dimensional analysis
Cell.dimensions("a1")     # => 2
Cell.dimensions("a1A")    # => 3
Cell.dimensions("h8Hh8")  # => 5
Cell.dimensions("foobar") # => 1

# Parse coordinate into dimensional components
Cell.parse("a1A")      # => {:ok, ["a", "1", "A"]}
Cell.parse("h8Hh8")    # => {:ok, ["h", "8", "H", "h", "8"]}
Cell.parse("foobar")   # => {:ok, ["foobar"]}
Cell.parse("1nvalid")  # => {:error, "Invalid CELL coordinate: 1nvalid"}

# Bang version for direct access
Cell.parse!("a1A")     # => ["a", "1", "A"]

# Convert coordinates to 0-indexed integer tuples
Cell.to_indices("a1")    # => {:ok, {0, 0}}
Cell.to_indices("e4")    # => {:ok, {4, 3}}
Cell.to_indices("a1A")   # => {:ok, {0, 0, 0}}
Cell.to_indices("b2B")   # => {:ok, {1, 1, 1}}

# Bang version
Cell.to_indices!("e4")   # => {4, 3}

# Convert 0-indexed integer tuples back to CELL coordinates
Cell.from_indices({0, 0})      # => {:ok, "a1"}
Cell.from_indices({4, 3})      # => {:ok, "e4"}
Cell.from_indices({0, 0, 0})   # => {:ok, "a1A"}

# Bang version
Cell.from_indices!({1, 1, 1})  # => "b2B"

# Round-trip conversion
"e4" |> Cell.to_indices!() |> Cell.from_indices!()  # => "e4"
```

## Format Specification

### Dimensional Patterns

| Dimensions | Pattern | Examples |
|------------|---------|----------|
| 1D | `<lower>` | `a`, `e`, `file` |
| 2D | `<lower><integer>` | `a1`, `e4`, `aa10` |
| 3D | `<lower><integer><upper>` | `a1A`, `e4B` |
| 4D | `<lower><integer><upper><lower>` | `a1Ab`, `e4Bc` |
| 5D | `<lower><integer><upper><lower><integer>` | `a1Ab2` |

### Regular Expression
```regex
^[a-z]+(?:[1-9][0-9]*[A-Z]+[a-z]+)*(?:[1-9][0-9]*[A-Z]*)?$
```

### Valid Examples

| Coordinate | Dimensions | Description |
|------------|------------|-------------|
| `a` | 1D | Single file |
| `a1` | 2D | Standard chess-style |
| `e4` | 2D | Chess center |
| `a1A` | 3D | 3D tic-tac-toe |
| `h8Hh8` | 5D | Multi-dimensional |
| `aa1AA` | 3D | Extended alphabet |

### Invalid Examples

| String | Reason |
|--------|--------|
| `""` | Empty string |
| `1` | Starts with digit |
| `A` | Starts with uppercase |
| `a0` | Zero is not a valid positive integer |
| `a01` | Leading zero in numeric dimension |
| `aA` | Missing numeric dimension |
| `a1a` | Missing uppercase dimension |
| `a1A1` | Numeric after uppercase without lowercase |

## API Reference

### Validation
```elixir
Cell.valid?(string)  # => boolean
```

### Parsing
```elixir
Cell.parse(string)   # => {:ok, [String.t()]} | {:error, String.t()}
Cell.parse!(string)  # => [String.t()] | raises ArgumentError
```

### Dimensional Analysis
```elixir
Cell.dimensions(string)  # => non_neg_integer()
```

### Coordinate Conversion
```elixir
Cell.to_indices(string)   # => {:ok, tuple()} | {:error, String.t()}
Cell.to_indices!(string)  # => tuple() | raises ArgumentError

Cell.from_indices(tuple)  # => {:ok, String.t()} | {:error, String.t()}
Cell.from_indices!(tuple) # => String.t() | raises ArgumentError
```

## Game Examples

### Chess (8×8)
```elixir
# Standard chess coordinates
chess_squares = for file <- ?a..?h, rank <- 1..8 do
  "#{<<file>>}#{rank}"
end

Enum.all?(chess_squares, &Cell.valid?/1)  # => true

# Convert position
Cell.to_indices!("e4")  # => {4, 3}
Cell.to_indices!("h8")  # => {7, 7}
```

### Shōgi (9×9)
```elixir
# Shōgi board positions
Cell.valid?("e5")  # => true (center)
Cell.valid?("i9")  # => true (corner)

Cell.to_indices!("e5")  # => {4, 4}
```

### 3D Tic-Tac-Toe (3×3×3)
```elixir
# Three-dimensional coordinates
Cell.valid?("a1A")  # => true
Cell.valid?("b2B")  # => true
Cell.valid?("c3C")  # => true

# Winning diagonal
diagonal = ["a1A", "b2B", "c3C"]
Enum.map(diagonal, &Cell.to_indices!/1)
# => [{0, 0, 0}, {1, 1, 1}, {2, 2, 2}]
```

## Extended Alphabet

CELL supports extended alphabet notation for large boards:
```elixir
# Single letters: a-z (positions 0-25)
Cell.to_indices!("z1")   # => {25, 0}

# Double letters: aa-zz (positions 26-701)
Cell.to_indices!("aa1")  # => {26, 0}
Cell.to_indices!("ab1")  # => {27, 0}
Cell.to_indices!("zz1")  # => {701, 0}

# And so on...
Cell.from_indices!({702, 0})  # => "aaa1"
```

## Properties

- **Multi-dimensional**: Supports unlimited dimensional coordinate systems
- **Cyclical**: Uses systematic three-character-set repetition
- **ASCII-based**: Pure ASCII characters for universal compatibility
- **Unambiguous**: Each coordinate maps to exactly one location
- **Scalable**: Extends naturally from 1D to unlimited dimensions
- **Rule-agnostic**: Independent of specific game mechanics

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PIN](https://sashite.dev/specs/pin/) — Piece Identifier Notation
- [CELL Specification](https://sashite.dev/specs/cell/1.0.0/) — Official specification

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
