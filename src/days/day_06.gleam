import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import glearray.{type Array} as array
import utils/lines

type Location {
  Wall
  Empty
}

type Direction {
  North
  South
  East
  West
}

type Position {
  Position(x: Int, y: Int)
}

type Guard {
  Guard(position: Position, facing: Direction)
}

type Map =
  Array(Array(Location))

type Visited =
  Set(Position)

type Visited2 =
  Set(#(Position, Direction))

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  let rows = lines.lines(input)
  let map = rows |> list.map(parse_row) |> array.from_list
  use start_pos <- result.try(
    get_start_pos(rows) |> result.replace_error("Could not find start location"),
  )

  loop(map, Guard(start_pos, North), set.new())
  |> set.size
  |> int.to_string
  |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  let rows = lines.lines(input)
  let map = rows |> list.map(parse_row) |> array.from_list
  use start_pos <- result.try(
    get_start_pos(rows) |> result.replace_error("Could not find start location"),
  )

  loop(map, Guard(start_pos, North), set.new())
  |> set.to_list
  |> list.count(check_obstruction(_, map, start_pos))
  |> int.to_string
  |> Ok
}

fn loop(map: Map, guard: Guard, visited: Visited) -> Visited {
  let new_visited = set.insert(visited, guard.position)
  let walked = walk(guard)
  let turned = turn(guard)
  case get_location(map, walked.position) {
    Error(_) -> new_visited
    Ok(Empty) -> loop(map, walked, new_visited)
    Ok(Wall) -> loop(map, turned, new_visited)
  }
}

fn check_obstruction(
  to_obstruct: Position,
  map: Map,
  start_pos: Position,
) -> Bool {
  loop2(obstruct(map, to_obstruct), Guard(start_pos, North), set.new())
}

fn obstruct(map: Map, pos: Position) -> Map {
  array.copy_set(
    map,
    pos.y,
    array.copy_set(
      array.get(map, pos.y) |> result.unwrap(array.new()),
      pos.x,
      Wall,
    )
      |> result.unwrap(array.new()),
  )
  |> result.unwrap(array.new())
}

fn loop2(map: Map, guard: Guard, visited: Visited2) -> Bool {
  let new_visited = set.insert(visited, #(guard.position, guard.facing))
  let walked = walk(guard)
  let turned = turn(guard)
  case
    get_location(map, walked.position),
    set.contains(visited, #(walked.position, walked.facing))
  {
    _, True -> True
    Error(_), _ -> False
    Ok(Empty), _ -> loop2(map, walked, new_visited)
    Ok(Wall), _ -> loop2(map, turned, new_visited)
  }
}

fn walk(guard: Guard) -> Guard {
  let Guard(facing:, position: Position(x:, y:)) = guard
  let position = case facing {
    North -> Position(x, y - 1)
    South -> Position(x, y + 1)
    East -> Position(x + 1, y)
    West -> Position(x - 1, y)
  }
  Guard(facing:, position:)
}

fn turn(guard: Guard) -> Guard {
  let Guard(facing:, position:) = guard
  let new_facing = case facing {
    North -> East
    East -> South
    South -> West
    West -> North
  }
  Guard(facing: new_facing, position:)
}

fn get_location(map: Map, pos: Position) -> Result(Location, Nil) {
  use row <- result.try(array.get(map, pos.y))
  array.get(row, pos.x)
}

fn get_start_pos(rows: List(String)) -> Result(Position, Nil) {
  use #(start_row, start_y) <- result.try(
    yielder.from_list(rows)
    |> yielder.index
    |> yielder.find(fn(row) { string.contains(pair.first(row), "^") }),
  )
  use #(start, _) <- result.try(string.split_once(start_row, "^"))
  let start_x = string.length(start)

  Ok(Position(start_x, start_y))
}

fn parse_row(row: String) -> Array(Location) {
  row |> string.split("") |> list.map(parse_char) |> array.from_list
}

fn parse_char(char: String) -> Location {
  case char {
    "#" -> Wall
    _ -> Empty
  }
}
