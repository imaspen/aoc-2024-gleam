import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/pair
import gleam/string
import utils/lines

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2()
  }
}

fn part_1(input: String) -> Result(String, String) {
  let #(keys, locks) = parse_input(input)

  list.map(keys, fn(key) {
    list.count(locks, fn(lock) {
      list.zip(key, lock)
      |> list.all(fn(p) { pair.first(p) + pair.second(p) <= 5 })
    })
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn part_2() -> Result(String, String) {
  Ok("Merry Christmas!")
}

fn parse_input(input: String) {
  lines.blocks(input)
  |> list.fold(#([], []), parse_block)
}

fn parse_block(acc: #(List(List(Int)), List(List(Int))), input: String) {
  let #(keys, locks) = acc
  let parts =
    lines.lines(input)
    |> list.map(string.to_graphemes)
    |> list.transpose

  case parts {
    [["#", ..], ..] -> {
      #(keys, [parse_part(parts), ..locks])
    }
    _ -> {
      #([parse_part(parts), ..keys], locks)
    }
  }
}

fn parse_part(input: List(List(String))) {
  list.map(input, fn(l) { list.count(l, string.contains(_, "#")) - 1 })
}
