# cell.ex

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_cell.svg)](https://hex.pm/packages/sashite_cell)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_cell)
[![CI](https://github.com/sashite/cell.ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/sashite/cell.ex/actions)
[![License](https://img.shields.io/hexpm/l/sashite_cell.svg)](https://github.com/sashite/cell.ex/blob/main/LICENSE)

> **CELL** (Coordinate Encoding for Layered Locations) implementation for Elixir.

## Overview

This library implements the [CELL Specification v1.0.0](https://sashite.dev/specs/cell/1.0.0/).

CELL defines a standardized ASCII format for encoding protocol-level Location identifiers on multi-dimensional Boards. A CELL string is a concatenation of dimensions, each using a specific character set in a fixed cycle:

| Dimension | Character set | Index range | Examples |
|-----------|---------------|-------------|----------|
| 1st (file) | Lowercase letters `a`–`z`, `aa`–`iv` | 0–255 | `a`, `e`, `aa` |
| 2nd (rank) | Positive integers `1`–`256` | 0–255 | `1`, `8`, `256` |
| 3rd (layer) | Uppercase letters `A`–`Z`, `AA`–`IV` | 0–255 | `A`, `C`, `IV` |

Letter dimensions use bijective base-26 encoding: single letters (`a`–`z`) map to indices 0–25, double letters (`aa`–`iv`) map to indices 26–255. Integer dimensions are 1-indexed: `1` maps to index 0, `256` maps to index 255.

### Implementation Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Max dimensions | 3 | Sufficient for 1D, 2D, 3D boards |
| Max index value | 255 | Covers 256×256×256 boards |
| Max string length | 7 | `"iv256IV"` (max for all dimensions at 255) |

These constraints enable bounded memory usage and safe parsing of untrusted input.

## Installation

```elixir
# In your mix.exs
def deps do
  [
    {:sashite_cell, "~> 3.0"}
  ]
end
```

## Usage

### Parsing (String → Indices)

Convert a CELL string into a tuple of 0-indexed integers.

```elixir
# Standard parsing (returns {:ok, tuple} or {:error, atom})
{:ok, indices} = Sashite.Cell.to_indices("e4")
indices  # => {4, 3}

# 1D coordinate
{:ok, indices} = Sashite.Cell.to_indices("e")
indices  # => {4}

# 3D coordinate
{:ok, indices} = Sashite.Cell.to_indices("a1A")
indices  # => {0, 0, 0}

# Multi-letter dimensions
{:ok, indices} = Sashite.Cell.to_indices("aa1")
indices  # => {26, 0}

# Maximum coordinate
{:ok, indices} = Sashite.Cell.to_indices("iv256IV")
indices  # => {255, 255, 255}

# Bang version (raises on error)
Sashite.Cell.to_indices!("e4")  # => {4, 3}

# Invalid input returns error tuple
{:error, :empty_input} = Sashite.Cell.to_indices("")
{:error, :must_start_with_lowercase} = Sashite.Cell.to_indices("A1")
{:error, :leading_zero} = Sashite.Cell.to_indices("a0")
```

### Formatting (Indices → String)

Convert a tuple of 0-indexed integers back to a CELL string.

```elixir
# Standard formatting (returns {:ok, string} or {:error, atom})
{:ok, coord} = Sashite.Cell.from_indices({4, 3})
coord  # => "e4"

# 1D coordinate
{:ok, coord} = Sashite.Cell.from_indices({4})
coord  # => "e"

# 3D coordinate
{:ok, coord} = Sashite.Cell.from_indices({0, 0, 0})
coord  # => "a1A"

# Multi-letter encoding
{:ok, coord} = Sashite.Cell.from_indices({26, 0})
coord  # => "aa1"

# Maximum coordinate
{:ok, coord} = Sashite.Cell.from_indices({255, 255, 255})
coord  # => "iv256IV"

# Bang version (raises on error)
Sashite.Cell.from_indices!({4, 3})  # => "e4"

# Invalid input returns error tuple
{:error, :index_out_of_range} = Sashite.Cell.from_indices({256, 0})
{:error, :invalid_dimensions} = Sashite.Cell.from_indices({})
```

### Validation

```elixir
# Boolean check (never raises)
Sashite.Cell.valid?("e4")       # => true
Sashite.Cell.valid?("a1A")      # => true
Sashite.Cell.valid?("iv256IV")  # => true
Sashite.Cell.valid?("")         # => false
Sashite.Cell.valid?("a0")       # => false
Sashite.Cell.valid?("A1")       # => false
Sashite.Cell.valid?(nil)        # => false
```

### Round-trip

```elixir
"e4" |> Sashite.Cell.to_indices!() |> Sashite.Cell.from_indices!()
# => "e4"

{4, 3} |> Sashite.Cell.from_indices!() |> Sashite.Cell.to_indices!()
# => {4, 3}
```

## API Reference

### Constants

```elixir
Sashite.Cell.max_dimensions()    # => 3
Sashite.Cell.max_index_value()   # => 255
Sashite.Cell.max_string_length() # => 7
```

### Parsing

```elixir
@spec Sashite.Cell.to_indices(String.t()) :: {:ok, tuple()} | {:error, atom()}
@spec Sashite.Cell.to_indices!(String.t()) :: tuple()
```

Converts a CELL string to a tuple of 0-indexed integers. The bang version raises `ArgumentError` on invalid input.

### Formatting

```elixir
@spec Sashite.Cell.from_indices(tuple()) :: {:ok, String.t()} | {:error, atom()}
@spec Sashite.Cell.from_indices!(tuple()) :: String.t()
```

Converts a tuple of 0-indexed integers to a CELL string. The bang version raises `ArgumentError` on invalid input.

### Validation

```elixir
@spec Sashite.Cell.valid?(any()) :: boolean()
```

Reports whether the string is a valid CELL coordinate. Never raises.

### Errors

Parsing and formatting errors are returned as atoms in `{:error, reason}` tuples:

| Atom | Cause |
|------|-------|
| `:not_a_string` | Input is not a binary |
| `:empty_input` | String length is 0 |
| `:input_too_long` | String exceeds 7 bytes |
| `:must_start_with_lowercase` | First character is not `a`–`z` |
| `:unexpected_character` | Character violates the cyclic dimension sequence |
| `:leading_zero` | Numeric dimension starts with `0` |
| `:exceeds_max_dimensions` | More than 3 dimensions detected |
| `:index_out_of_range` | Decoded index exceeds 255 |
| `:invalid_dimensions` | Tuple has 0 or more than 3 elements |
| `:not_a_tuple` | Input to `from_indices` is not a tuple |

## Security

This library is designed for backend use where inputs may come from untrusted clients.

### Bounded resource consumption

All inputs are rejected at the byte level before any processing occurs:

- **Length check first**: Inputs longer than 7 bytes are rejected in O(1) before any character inspection, preventing denial-of-service through oversized input.
- **No regex engine**: Parsing uses raw binary pattern matching, eliminating ReDoS as an attack vector.
- **No intermediate allocations**: Parsing accumulates integer values directly, without building intermediate lists, strings, or atoms.
- **Bounded recursion**: The parser processes at most 7 bytes across at most 3 dimensions. No input can trigger unbounded recursion or memory consumption.

### Rejection guarantees

Any input that is not a valid CELL coordinate is rejected with an `{:error, reason}` tuple. The rejection path does not raise exceptions (no backtrace capture cost), does not allocate atoms (all error atoms are compile-time literals), and executes in bounded time proportional to at most 7 bytes.

## Design Principles

- **Spec conformance**: Strict adherence to CELL v1.0.0, restricted to 3 dimensions with documented bounds
- **Binary pattern matching on the hot path**: Character dispatch uses guards in function clause heads, resolved at native speed by the BEAM's pattern matching engine
- **Zero intermediate allocations**: Parsing accumulates dimension values as integers on the stack; formatting constructs the result binary in a single pass
- **Elixir idioms**: `{:ok, _}` / `{:error, _}` tuples with bang variants, atom-based error reasons, tuple-based coordinates
- **Immutable by default**: All functions return new values
- **No dependencies**: Pure Elixir standard library only

### Performance Architecture

CELL coordinates are short (1–7 bytes) with a small output space (tuples of 1–3 integers, each 0–255). The implementation exploits these constraints through two complementary strategies.

**Guard-based dispatch** — The parser uses binary pattern matching with guards (`when byte in ?a..?z`) in function clause heads rather than runtime predicate calls or `cond` branches. The BEAM compiles these guards into optimized jump tables, eliminating function call overhead on the hot path. Each byte is classified and accumulated in a single pattern match step.

**Direct binary construction** — The formatter encodes each dimension directly into binary fragments without intermediate string allocations. Letter indices are converted to bytes via arithmetic (`?a + value`), integer indices via digit extraction (`div`/`rem`). The final string is assembled once from an iodata list, avoiding repeated `<>` concatenation.

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [CELL Specification](https://sashite.dev/specs/cell/1.0.0/) — Official specification
- [CELL Examples](https://sashite.dev/specs/cell/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
