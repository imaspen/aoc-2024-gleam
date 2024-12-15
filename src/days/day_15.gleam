import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import utils/lines

type Direction {
  North
  South
  East
  West
}

type Instructions =
  List(Direction)

type Position {
  Box
  Empty
  Wall
}

type Point {
  Point(x: Int, y: Int)
}

type Map =
  Dict(Point, Position)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(map, start_point, instructions) <- result.map(
    parse_input(input) |> result.replace_error("Couldn't parse input."),
  )

  move(map, start_point, instructions)
  |> dict.to_list
  |> list.map(get_gps_coordinate)
  |> int.sum
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn parse_input(input: String) -> Result(#(Map, Point, Instructions), Nil) {
  case lines.blocks(input) {
    [map_str, instructions_str] -> {
      use #(map, start_point) <- result.try(parse_map(map_str))
      use instructions <- result.map(parse_instructions(instructions_str))
      #(map, start_point, instructions)
    }
    _ -> Error(Nil)
  }
}

fn parse_map(input: String) -> Result(#(Map, Point), Nil) {
  input
  |> lines.lines
  |> yielder.from_list
  |> yielder.index
  |> yielder.try_fold(#(dict.new(), Point(0, 0)), parse_map_row)
}

fn parse_map_row(
  acc: #(Map, Point),
  row: #(String, Int),
) -> Result(#(Map, Point), Nil) {
  let #(row_str, y) = row

  row_str
  |> string.to_graphemes
  |> yielder.from_list
  |> yielder.index
  |> yielder.try_fold(acc, fn(map, point) { parse_map_char(y, map, point) })
}

fn parse_map_char(
  y: Int,
  acc: #(Map, Point),
  point: #(String, Int),
) -> Result(#(Map, Point), Nil) {
  let #(char, x) = point
  let #(map, start_point) = acc

  use #(position, is_start_point) <- result.map(parse_position(char))

  let point = Point(x, y)
  let new_map = dict.insert(map, point, position)

  case is_start_point {
    False -> #(new_map, start_point)
    True -> #(new_map, point)
  }
}

fn parse_position(input: String) -> Result(#(Position, Bool), Nil) {
  case input {
    "O" -> Ok(#(Box, False))
    "#" -> Ok(#(Wall, False))
    "." -> Ok(#(Empty, False))
    "@" -> Ok(#(Empty, True))
    _ -> Error(Nil)
  }
}

fn parse_instructions(input: String) -> Result(Instructions, Nil) {
  input
  |> string.to_graphemes
  |> list.filter(fn(g) { g != "\n" })
  |> list.try_map(parse_instruction)
}

fn parse_instruction(input: String) -> Result(Direction, Nil) {
  case input {
    "^" -> Ok(North)
    "v" -> Ok(South)
    ">" -> Ok(East)
    "<" -> Ok(West)
    _ -> Error(Nil)
  }
}

fn move(map: Map, point: Point, instructions: Instructions) -> Map {
  case instructions {
    [] -> map
    [dir, ..rest] -> {
      let dest = move_point(point, dir)
      case check_move(map, dest, dir) {
        Ok(first_empty) if first_empty == dest -> move(map, dest, rest)
        Error(_) -> move(map, point, rest)
        Ok(first_empty) -> {
          move(
            map |> dict.insert(first_empty, Box) |> dict.insert(dest, Empty),
            dest,
            rest,
          )
        }
      }
    }
  }
}

fn check_move(map: Map, at: Point, dir: Direction) -> Result(Point, Nil) {
  case dict.get(map, at) {
    Error(_) -> Error(Nil)
    Ok(Wall) -> Error(Nil)
    Ok(Empty) -> Ok(at)
    Ok(Box) -> check_move(map, move_point(at, dir), dir)
  }
}

fn move_point(point: Point, dir: Direction) {
  let Point(x:, y:) = point
  case dir {
    North -> Point(x, y - 1)
    South -> Point(x, y + 1)
    East -> Point(x + 1, y)
    West -> Point(x - 1, y)
  }
}

fn get_gps_coordinate(pair: #(Point, Position)) -> Int {
  let #(Point(x:, y:), pos) = pair

  case pos {
    Empty -> 0
    Wall -> 0
    Box -> y * 100 + x
  }
}
