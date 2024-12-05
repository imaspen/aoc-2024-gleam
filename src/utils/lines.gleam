import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn lines(input: String) -> List(String) {
  input
  |> string.trim()
  |> string.split("\n")
}

pub fn space_separated_lines(input: String) -> List(List(String)) {
  input
  |> lines()
  |> list.map(string.split(_, " "))
}

pub fn space_separated_ints(input: String) -> List(List(Int)) {
  input
  |> space_separated_lines()
  |> list.map(fn(line) {
    list.map(line, fn(str) { int.parse(str) |> result.unwrap(0) })
  })
}

pub fn csv_lines(input: String) -> List(List(String)) {
  input |> lines |> list.map(string.split(_, ","))
}

pub fn csv_int_lines(input: String) -> Result(List(List(Int)), String) {
  input
  |> csv_lines
  |> list.try_map(fn(line) { list.try_map(line, fn(part) { int.parse(part) }) })
  |> result.replace_error("Couldn't parse input")
}

pub fn blocks(input: String) -> List(String) {
  input
  |> string.trim
  |> string.split("\n\n")
}
