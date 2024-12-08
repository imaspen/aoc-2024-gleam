import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import utils/lines

type Vector {
  Vector(x: Int, y: Int)
}

type Antenna =
  Int

type Antennas =
  Dict(Antenna, List(Vector))

type Antinodes =
  Set(Vector)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use map_size <- result.try(
    map_size(input) |> result.replace_error("Failed to parse input"),
  )
  use antennas <- result.map(
    input
    |> lines.lines
    |> yielder.from_list
    |> yielder.index
    |> yielder.try_fold(dict.new(), parse_line)
    |> result.replace_error("Failed to parse input"),
  )

  antennas
  |> dict.values
  |> list.fold(set.new(), find_antinodes_for_antenna)
  |> set.filter(is_point_in_map(_, map_size))
  |> set.size
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use map_size <- result.try(
    map_size(input) |> result.replace_error("Failed to parse input"),
  )
  use antennas <- result.map(
    input
    |> lines.lines
    |> yielder.from_list
    |> yielder.index
    |> yielder.try_fold(dict.new(), parse_line)
    |> result.replace_error("Failed to parse input"),
  )

  antennas
  |> dict.values
  |> list.fold(set.new(), find_antinodes_for_antenna_2(map_size))
  |> set.size
  |> int.to_string
}

fn map_size(input: String) -> Result(Vector, Nil) {
  let l = lines.lines(input)
  let y = list.length(l)

  use first_line <- result.map(list.first(l))
  let x = string.length(first_line)

  Vector(x, y)
}

fn parse_line(
  antennas: Antennas,
  input: #(String, Int),
) -> Result(Antennas, Nil) {
  let #(line, y) = input

  line
  |> string.to_graphemes
  |> yielder.from_list
  |> yielder.index
  |> yielder.try_fold(antennas, parse_char(y))
}

fn parse_char(y: Int) -> fn(Antennas, #(String, Int)) -> Result(Antennas, Nil) {
  fn(antennas: Antennas, input: #(String, Int)) {
    let #(char, x) = input
    case char {
      "." -> Ok(antennas)
      _ ->
        result.map(parse_antenna(char), dict.upsert(
          antennas,
          _,
          upsert_position(Vector(x, y)),
        ))
    }
  }
}

fn parse_antenna(char: String) -> Result(Antenna, Nil) {
  char
  |> string.to_utf_codepoints
  |> list.first
  |> result.map(string.utf_codepoint_to_int)
}

fn upsert_position(position: Vector) -> fn(Option(List(Vector))) -> List(Vector) {
  fn(maybe_list: Option(List(Vector))) {
    case maybe_list {
      None -> [position]
      Some(l) -> [position, ..l]
    }
  }
}

fn find_antinodes_for_antenna(
  antinodes: Antinodes,
  positions: List(Vector),
) -> Antinodes {
  list.combination_pairs(positions)
  |> list.fold(antinodes, find_antinodes_for_pair)
}

fn find_antinodes_for_pair(
  antinodes: Antinodes,
  positions: #(Vector, Vector),
) -> Antinodes {
  let #(lhs, rhs) = positions

  antinodes
  |> set.insert(add_vectors(lhs, sub_vectors(lhs, rhs)))
  |> set.insert(add_vectors(rhs, sub_vectors(rhs, lhs)))
}

fn add_vectors(lhs: Vector, rhs: Vector) -> Vector {
  Vector(lhs.x + rhs.x, lhs.y + rhs.y)
}

fn sub_vectors(lhs: Vector, rhs: Vector) -> Vector {
  Vector(lhs.x - rhs.x, lhs.y - rhs.y)
}

fn is_point_in_map(point: Vector, map_size: Vector) -> Bool {
  let Vector(x:, y:) = point
  let Vector(x: max_x, y: max_y) = map_size

  x >= 0 && x < max_x && y >= 0 && y < max_y
}

fn find_antinodes_for_antenna_2(
  map_size: Vector,
) -> fn(Antinodes, List(Vector)) -> Antinodes {
  fn(antinodes: Antinodes, positions: List(Vector)) {
    list.combination_pairs(positions)
    |> list.fold(antinodes, find_antinodes_for_pair_2(map_size))
  }
}

fn find_antinodes_for_pair_2(
  map_size: Vector,
) -> fn(Antinodes, #(Vector, Vector)) -> Antinodes {
  fn(antinodes: Antinodes, positions: #(Vector, Vector)) {
    let #(lhs, rhs) = positions

    antinodes
    |> find_antinodes_for_pair_2_loop(rhs, sub_vectors(lhs, rhs), map_size)
    |> find_antinodes_for_pair_2_loop(lhs, sub_vectors(rhs, lhs), map_size)
  }
}

fn find_antinodes_for_pair_2_loop(
  antinodes: Antinodes,
  at: Vector,
  offset: Vector,
  map_size: Vector,
) -> Antinodes {
  case is_point_in_map(at, map_size) {
    True ->
      find_antinodes_for_pair_2_loop(
        set.insert(antinodes, at),
        add_vectors(at, offset),
        offset,
        map_size,
      )
    False -> antinodes
  }
}
