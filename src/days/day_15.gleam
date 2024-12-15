import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
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
  BoxLeft
  BoxRight
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
    parse_input(input, False) |> result.replace_error("Couldn't parse input."),
  )

  move(map, start_point, instructions)
  |> dict.to_list
  |> list.map(get_gps_coordinate)
  |> int.sum
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use #(map, start_point, instructions) <- result.map(
    parse_input(input, True) |> result.replace_error("Couldn't parse input."),
  )

  move_wide(map, start_point, instructions)
  |> dict.to_list
  |> list.map(get_gps_coordinate)
  |> int.sum
  |> int.to_string
}

fn parse_input(
  input: String,
  is_wide: Bool,
) -> Result(#(Map, Point, Instructions), Nil) {
  case lines.blocks(input) {
    [map_str, instructions_str] -> {
      use #(map, start_point) <- result.try(parse_map(map_str, is_wide))
      use instructions <- result.map(parse_instructions(instructions_str))
      #(map, start_point, instructions)
    }
    _ -> Error(Nil)
  }
}

fn parse_map(input: String, is_wide: Bool) -> Result(#(Map, Point), Nil) {
  input
  |> lines.lines
  |> yielder.from_list
  |> yielder.index
  |> yielder.try_fold(#(dict.new(), Point(0, 0)), fn(map, row) {
    parse_map_row(is_wide, map, row)
  })
}

fn parse_map_row(
  is_wide: Bool,
  acc: #(Map, Point),
  row: #(String, Int),
) -> Result(#(Map, Point), Nil) {
  let #(row_str, y) = row

  row_str
  |> string.to_graphemes
  |> yielder.from_list
  |> yielder.index
  |> yielder.try_fold(acc, fn(map, point) {
    parse_map_char(is_wide, y, map, point)
  })
}

fn parse_map_char(
  is_wide: Bool,
  y: Int,
  acc: #(Map, Point),
  point: #(String, Int),
) -> Result(#(Map, Point), Nil) {
  let #(char, x) = point
  let #(map, start_point) = acc

  use #(position, is_start_point) <- result.map(parse_position(char))

  let point = case is_wide {
    False -> Point(x, y)
    True -> Point(x * 2, y)
  }

  let new_map = case is_wide, dict.insert(map, point, position) {
    False, d -> d
    True, d -> {
      case position {
        BoxLeft -> dict.insert(d, Point(x * 2 + 1, y), BoxRight)
        other -> dict.insert(d, Point(x * 2 + 1, y), other)
      }
    }
  }

  case is_start_point {
    False -> #(new_map, start_point)
    True -> #(new_map, point)
  }
}

fn parse_position(input: String) -> Result(#(Position, Bool), Nil) {
  case input {
    "O" -> Ok(#(BoxLeft, False))
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
            map |> dict.insert(first_empty, BoxLeft) |> dict.insert(dest, Empty),
            dest,
            rest,
          )
        }
      }
    }
  }
}

fn move_wide(map: Map, point: Point, instructions: Instructions) -> Map {
  case instructions {
    [] -> map
    [dir, ..rest] -> {
      let dest = move_point(point, dir)
      case check_move_wide(map, [dest], dir, set.from_list([dest]), []) {
        Ok([]) -> move_wide(map, dest, rest)
        Error(_) -> move_wide(map, point, rest)
        Ok(moved) -> {
          let map_with_moved_empty =
            list.fold(moved, map, fn(n_map, moved) {
              dict.insert(n_map, pair.first(moved), Empty)
            })

          let new_map =
            list.fold(moved, map_with_moved_empty, fn(n_map, moved) {
              dict.insert(
                n_map,
                move_point(pair.first(moved), dir),
                pair.second(moved),
              )
            })

          move_wide(new_map, dest, rest)
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
    Ok(BoxLeft) -> check_move(map, move_point(at, dir), dir)
    Ok(BoxRight) -> check_move(map, move_point(at, dir), dir)
  }
}

fn check_move_wide(
  map: Map,
  queue: List(Point),
  dir: Direction,
  // seen only used for moving up and down
  seen: Set(Point),
  moved: List(#(Point, Position)),
) -> Result(List(#(Point, Position)), Nil) {
  case list.pop(queue, fn(_) { True }) {
    Error(_) -> Ok(moved)
    Ok(#(at, rest)) -> {
      case dict.get(map, at), rest {
        Error(_), _ -> Error(Nil)
        Ok(Wall), _ -> Error(Nil)
        Ok(Empty), [] -> Ok(moved)
        Ok(Empty), _ -> check_move_wide(map, rest, dir, seen, moved)
        Ok(box), _ -> {
          case dir {
            East | West -> {
              check_move_wide(map, [move_point(at, dir), ..rest], dir, seen, [
                #(at, box),
                ..moved
              ])
            }
            North | South -> {
              let other_side = get_box_pair(at, box)
              let moved_at = move_point(at, dir)
              let #(new_queue, new_seen) = case
                set.contains(seen, other_side),
                set.contains(seen, moved_at)
              {
                True, True -> #(rest, seen)
                False, True -> #(
                  [other_side, ..rest],
                  set.insert(seen, other_side),
                )
                True, False -> #([moved_at, ..rest], set.insert(seen, moved_at))
                False, False -> #(
                  [other_side, moved_at, ..rest],
                  seen |> set.insert(other_side) |> set.insert(moved_at),
                )
              }
              check_move_wide(map, new_queue, dir, new_seen, [
                #(at, box),
                ..moved
              ])
            }
          }
        }
      }
    }
  }
}

fn get_box_pair(at: Point, box: Position) -> Point {
  case box {
    BoxLeft -> move_point(at, East)
    BoxRight -> move_point(at, West)
    _ -> at
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
    BoxLeft -> y * 100 + x
    BoxRight -> 0
  }
}
