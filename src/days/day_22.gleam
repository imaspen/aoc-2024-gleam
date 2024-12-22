import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import utils/lines

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use numbers <- result.map(parse_input(input))
  numbers |> list.map(do_iterations(_, 2000)) |> int.sum |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn do_iterations(n: Int, count: Int) -> Int {
  use <- bool.guard(when: count == 0, return: n)
  do_iterations(iterate(n), count - 1)
}

fn iterate(n: Int) {
  let n = mix_and_prune(n * 64, n)
  let n = mix_and_prune(n / 32, n)
  mix_and_prune(n * 2048, n)
}

fn mix_and_prune(n: Int, secret: Int) -> Int {
  let n = int.bitwise_exclusive_or(n, secret)
  n % 16_777_216
}

fn parse_input(input: String) -> Result(List(Int), String) {
  use lines <- result.try(lines.csv_int_lines(input))
  list.try_map(lines, list.first)
  |> result.replace_error("Couldn't parse input.")
}
