import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import rememo/memo
import utils/lines

type Towel =
  List(Int)

type Towels =
  List(Towel)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(patterns, towels) <- result.map(
    parse_input(input) |> result.replace_error("Couldn't parse input."),
  )

  patterns |> list.count(is_towel_valid(_, towels)) |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use #(patterns, towels) <- result.map(
    parse_input(input) |> result.replace_error("Couldn't parse input."),
  )

  use cache <- memo.create()

  patterns
  |> list.map(is_towel_valid_2(_, towels, cache))
  |> int.sum
  |> int.to_string
}

// Part 1

fn is_towel_valid(pattern: Towel, towels: Towels) {
  is_towel_valid_loop([pattern], towels, set.from_list([pattern]))
}

fn is_towel_valid_loop(
  remaining_patterns: Towels,
  towels: Towels,
  seen: Set(Towel),
) -> Bool {
  case remaining_patterns {
    [] -> False
    [pattern, ..patterns] -> {
      case pattern {
        [] -> True
        _ -> {
          let new_patterns =
            towels
            |> list.filter_map(does_towel_match(pattern, _))
            |> list.filter(fn(t) { !set.contains(seen, t) })

          let seen = list.fold(new_patterns, seen, set.insert)

          list.fold(new_patterns, patterns, list.prepend)
          |> is_towel_valid_loop(towels, seen)
        }
      }
    }
  }
}

fn does_towel_match(pattern: Towel, towel: Towel) -> Result(Towel, Nil) {
  case pattern, towel {
    remaining_pattern, [] -> Ok(remaining_pattern)
    [], [_, ..] -> Error(Nil)
    [p, ..], [t, ..] if t != p -> Error(Nil)
    [_, ..p], [_, ..t] -> does_towel_match(p, t)
  }
}

// Part 2

fn is_towel_valid_2(pattern: Towel, towels: Towels, cache) -> Int {
  use <- memo.memoize(cache, pattern)

  case pattern {
    [] -> 1
    _ -> {
      towels
      |> list.filter_map(does_towel_match(pattern, _))
      |> list.map(is_towel_valid_2(_, towels, cache))
      |> int.sum
    }
  }
}

// Parsing

fn parse_input(input: String) -> Result(#(Towels, Towels), Nil) {
  case lines.blocks(input) {
    [towels_str, patterns_str] -> {
      use patterns <- result.try(parse_patterns(patterns_str))
      use towels <- result.map(parse_towels(towels_str))
      #(patterns, towels)
    }
    _ -> Error(Nil)
  }
}

fn parse_patterns(input: String) {
  lines.lines(input) |> list.try_map(parse_towel)
}

fn parse_towels(input: String) -> Result(Towels, Nil) {
  string.split(input, ", ") |> list.try_map(parse_towel)
}

fn parse_towel(input: String) -> Result(Towel, Nil) {
  string.to_graphemes(input) |> list.try_map(parse_color)
}

fn parse_color(input: String) -> Result(Int, Nil) {
  string.to_utf_codepoints(input)
  |> list.map(string.utf_codepoint_to_int)
  |> list.first()
}
