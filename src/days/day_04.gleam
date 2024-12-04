import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string
import utils/lines

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  let lines = input |> lines.lines
  let rotated = input |> lines.lines |> rotate_lines
  let diagonal_right = get_diagonal(lines)
  let diagonal_left = lines |> list.map(string.reverse) |> get_diagonal

  let x_matches = get_xmases(lines)
  let y_matches = get_xmases(rotated)
  let right_matches = get_xmases(diagonal_right)
  let left_matches = get_xmases(diagonal_left)

  x_matches + y_matches + right_matches + left_matches |> int.to_string |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn rotate_lines(lines: List(String)) -> List(String) {
  lines
  |> list.map(string.split(_, ""))
  |> list.transpose
  |> list.map(string.join(_, ""))
}

fn get_diagonal(lines: List(String)) -> List(String) {
  list.flatten([
    get_right_diagonals(lines),
    diagonal_fill(list.drop(lines, 1), []),
  ])
}

fn diagonal_fill(lines: List(String), acc: List(String)) -> List(String) {
  case lines {
    [] -> acc
    [x, ..rest] ->
      diagonal_fill(rest, [
        get_right_diagonals([x, ..rest]) |> list.first |> result.unwrap(""),
        ..acc
      ])
  }
}

fn get_right_diagonals(lines: List(String)) -> List(String) {
  lines
  |> list.map(string.split(_, ""))
  |> list.index_map(list.drop)
  |> list.transpose
  |> list.map(string.join(_, ""))
}

fn get_xmases(lines: List(String)) -> Int {
  list.fold(lines, 0, fn(acc, val) { acc + get_xmases_in_line(val) })
}

fn get_xmases_in_line(line: String) -> Int {
  let assert Ok(forward) = regexp.from_string("XMAS")
  let assert Ok(backward) = regexp.from_string("SAMX")

  {
    regexp.scan(forward, line)
    |> list.length
  }
  + {
    regexp.scan(backward, line)
    |> list.length
  }
}
