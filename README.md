# cell.ex

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_cell.svg)](https://hex.pm/packages/sashite_cell)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_cell)
[![License](https://img.shields.io/hexpm/l/sashite_cell.svg)](https://github.com/sashite/cell.ex/blob/main/LICENSE)

> **CELL** (Coordinate Encoding for Layered Locations) implementation for Elixir.

## Overview

This library implements the [CELL Specification v1.0.0](https://sashite.dev/specs/cell/1.0.0/).

### Implementation Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Max dimensions | 3 | Sufficient for 1D, 2D, 3D boards |
| Max index value | 255 | Covers 256×256×256 boards |
| Max string length | 7 | `"iv256IV"` (max for all dimensions at 255) |

These constraints enable bounded memory usage and safe parsing.

## Installation

Add `sashite_cell` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sashite_cell, "~> 2.0"}
  ]
end
```

## Usage

### Parsing (String → Indices)

Convert a CELL string into a tuple of indices.

```elixir
# Standard parsing (returns {:ok, tuple} or {:error, message})
{:ok, indices} = Sashite.Cell.to_indices("e4")
indices  # => {4, 3}

# 3D coordinate
{:ok, indices} = Sashite.Cell.to_indices("a1A")
indices  # => {0, 0, 0}

# Bang version (raises on error)
Sashite.Cell.to_indices!("e4")  # => {4, 3}
```

### Formatting (Indices → String)

Convert a tuple of indices back to a CELL string.

```elixir
# Standard formatting (returns {:ok, string} or {:error, message})
{:ok, coord} = Sashite.Cell.from_indices({4, 3})
coord  # => "e4"

# Bang version
Sashite.Cell.from_indices!({0, 0, 0})  # => "a1A"
Sashite.Cell.from_indices!({2, 2, 2})  # => "c3C"
```

### Validation

```elixir
# Boolean check
Sashite.Cell.valid?("e4")   # => true
Sashite.Cell.valid?("a0")   # => false
```

### Accessing Coordinate Data

```elixir
indices = Sashite.Cell.to_indices!("e4")

# Get dimensions count
tuple_size(indices)  # => 2

# Access individual index
elem(indices, 0)  # => 4
elem(indices, 1)  # => 3

# Round-trip conversion
"e4" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()  # => "e4"
```

## API Reference

### Constants

```elixir
Sashite.Cell.Coordinate.max_dimensions()    # => 3
Sashite.Cell.Coordinate.max_index_value()   # => 255
Sashite.Cell.Coordinate.max_string_length() # => 7
```

### Parsing

```elixir
@spec to_indices(String.t()) :: {:ok, tuple()} | {:error, String.t()}
def to_indices(string)

@spec to_indices!(String.t()) :: tuple()
def to_indices!(string)
```

Converts a CELL string to a tuple of 0-indexed integers.
The bang version raises `ArgumentError` on invalid input.

### Formatting

```elixir
@spec from_indices(tuple()) :: {:ok, String.t()} | {:error, String.t()}
def from_indices(indices)

@spec from_indices!(tuple()) :: String.t()
def from_indices!(indices)
```

Converts a tuple of 0-indexed integers to a CELL string.
The bang version raises `ArgumentError` on invalid input.

### Validation

```elixir
@spec valid?(String.t()) :: boolean()
def valid?(string)
```

Reports whether the string is a valid CELL coordinate.

### Errors

All parsing and validation errors return `{:error, message}` tuples or raise `ArgumentError` for bang versions:

| Message | Cause |
|---------|-------|
| `"empty input"` | String length is 0 |
| `"input exceeds 7 characters"` | String too long |
| `"must start with lowercase letter"` | Invalid first character |
| `"unexpected character"` | Character violates the cyclic sequence |
| `"leading zero"` | Numeric part starts with '0' |
| `"exceeds 3 dimensions"` | More than 3 dimensions |
| `"index exceeds 255"` | Decoded value out of range |

## Design Principles

- **Elixir idioms**: `{:ok, value}` / `{:error, reason}` tuples with bang variants
- **Tuple-based coordinates**: Native Elixir tuples for indices
- **Predicate functions**: `valid?/1` follows Elixir naming conventions
- **Immutable by default**: All functions return new values
- **No dependencies**: Pure Elixir standard library only

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [CELL Specification](https://sashite.dev/specs/cell/1.0.0/) — Official specification
- [CELL Examples](https://sashite.dev/specs/cell/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
