import argv
import days/day.{type Day}
import days/day_01
import days/day_02
import days/day_03
import days/day_04
import days/day_05
import days/day_06
import days/day_07
import days/day_08
import days/day_09
import days/day_10
import days/day_11
import days/day_12
import days/day_13
import days/day_14
import days/day_15
import days/day_16
import days/day_17
import days/day_18
import days/day_19
import days/day_20
import days/day_21
import days/day_22
import days/day_23
import days/day_24
import days/day_25
import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/io
import gleam/result
import gleam/string
import simplifile

fn usage_error(message: String) -> Result(_, String) {
  let message = case message {
    "" -> ""
    _ -> "Error: " <> message <> "\n"
  }

  Error(message <> "Usage: aoc_2024_gleam <day> <part>
  day: the day to run
  part: the part to run")
}

pub fn main() {
  case argv.load().arguments {
    [day, part] -> run(day, part)
    _ -> usage_error("")
  }
  |> result.unwrap_both
  |> io.println
}

fn run(day day_str: String, part part_str: String) -> Result(String, String) {
  use #(day_int, day) <- result.try(get_day(day_str))
  use part: Part <- result.try(get_part(part_str))
  use input: String <- result.try(get_input(day_int, part_str))

  day(part, input)
}

fn get_day(day: String) -> Result(#(Int, Day), String) {
  use day_int <- result.try(case int.parse(day) {
    Ok(x) -> Ok(x)
    Error(_) -> usage_error("Day should be a number between 1 & 25")
  })

  use day_fn <- result.try(case day_int {
    1 -> Ok(day_01.day)
    2 -> Ok(day_02.day)
    3 -> Ok(day_03.day)
    4 -> Ok(day_04.day)
    5 -> Ok(day_05.day)
    6 -> Ok(day_06.day)
    7 -> Ok(day_07.day)
    8 -> Ok(day_08.day)
    9 -> Ok(day_09.day)
    10 -> Ok(day_10.day)
    11 -> Ok(day_11.day)
    12 -> Ok(day_12.day)
    13 -> Ok(day_13.day)
    14 -> Ok(day_14.day)
    15 -> Ok(day_15.day)
    16 -> Ok(day_16.day)
    17 -> Ok(day_17.day)
    18 -> Ok(day_18.day)
    19 -> Ok(day_19.day)
    20 -> Ok(day_20.day)
    21 -> Ok(day_21.day)
    22 -> Ok(day_22.day)
    23 -> Ok(day_23.day)
    24 -> Ok(day_24.day)
    25 -> Ok(day_25.day)
    _ -> usage_error("Day should be between 1 & 25")
  })

  Ok(#(day_int, day_fn))
}

fn get_part(part: String) -> Result(Part, String) {
  case part {
    "1" -> Ok(PartOne)
    "2" -> Ok(PartTwo)
    _ -> usage_error("Part should be 1 or 2")
  }
}

fn get_input(day: Int, part: String) -> Result(String, String) {
  let base_path =
    "./res/day_" <> { int.to_string(day) |> string.pad_start(2, "0") }

  simplifile.read(from: base_path <> ".txt")
  |> result.lazy_or(fn() {
    simplifile.read(from: base_path <> "_" <> part <> ".txt")
  })
  |> result.replace_error(
    "Could not find file for day " <> int.to_string(day) <> " part " <> part,
  )
}
