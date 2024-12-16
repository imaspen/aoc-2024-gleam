import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import utils/lines
import utils/map.{type Direction, type Point, East, North, Point, South, West}

type State {
  State(pos: Point, dir: Direction)
}

type Scores =
  Dict(Point, Int)

type CameFrom =
  Dict(Point, Point)

type Queue =
  Dict(Point, Direction)

type Map =
  map.Map(Nil)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(map, start, end) <- result.try(
    parse_input(input) |> result.replace_error("Couldn't parse input."),
  )

  use score <- result.map(
    a_star(map, start, end) |> result.replace_error("Couldn't find target."),
  )

  int.to_string(score)
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn parse_input(input: String) -> Result(#(Map, Point, Point), Nil) {
  let #(map, start_result, end_result) =
    input
    |> lines.lines
    |> yielder.from_list
    |> yielder.index
    |> yielder.fold(#(map.new(), Error(Nil), Error(Nil)), parse_row)

  use start <- result.try(start_result)
  use end <- result.map(end_result)

  #(map, start, end)
}

fn parse_row(
  acc: #(Map, Result(Point, Nil), Result(Point, Nil)),
  input: #(String, Int),
) -> #(Map, Result(Point, Nil), Result(Point, Nil)) {
  let #(row, y) = input

  row
  |> string.to_graphemes
  |> yielder.from_list
  |> yielder.index
  |> yielder.fold(acc, fn(a, b) { parse_cell(y, a, b) })
}

fn parse_cell(
  y: Int,
  acc: #(Map, Result(Point, Nil), Result(Point, Nil)),
  input: #(String, Int),
) -> #(Map, Result(Point, Nil), Result(Point, Nil)) {
  let #(map, start, end) = acc
  let #(char, x) = input
  let at = Point(x:, y:)

  case char {
    "." -> #(dict.insert(map, at, Nil), start, end)
    "S" -> #(dict.insert(map, at, Nil), Ok(at), end)
    "E" -> #(dict.insert(map, at, Nil), start, Ok(at))
    _ -> acc
  }
}

fn a_star(map: Map, start_point: Point, end_point: Point) -> Result(Int, Nil) {
  let queue = dict.from_list([#(start_point, East)])
  let g_scores = dict.from_list([#(start_point, 0)])
  let f_scores = dict.from_list([#(start_point, h(start_point, end_point))])

  a_star_loop(map, end_point, queue, f_scores, g_scores, dict.new())
  |> dict.get(end_point)
}

fn a_star_loop(
  map: Map,
  target: Point,
  queue: Queue,
  f_scores: Scores,
  g_scores: Scores,
  came_from: CameFrom,
) -> Scores {
  case get_current(queue, f_scores) {
    Error(_) -> g_scores
    Ok(#(curr, rest)) -> {
      use <- bool.guard(curr.pos == target, g_scores)

      let #(new_queue, new_f_scores, new_g_scores, new_came_from) =
        get_neighbors(map, curr.pos)
        |> list.fold(#(rest, f_scores, g_scores, came_from), fn(acc, n) {
          update_for_neighbor(acc, curr, target, n)
        })

      a_star_loop(
        map,
        target,
        new_queue,
        new_f_scores,
        new_g_scores,
        new_came_from,
      )
    }
  }
}

fn h(at: Point, target: Point) -> Int {
  int.absolute_value(target.x - at.x) + int.absolute_value(target.y - at.y)
}

fn get_score(scores: Scores, at: Point) -> Int {
  dict.get(scores, at) |> result.unwrap(1_000_000_000_000)
}

fn get_current(queue: Queue, f_scores: Scores) -> Result(#(State, Queue), Nil) {
  use #(pos, dir) <- result.map(
    queue
    |> dict.to_list
    |> list.sort(fn(a, b) {
      int.compare(
        get_score(f_scores, pair.first(a)),
        get_score(f_scores, pair.first(b)),
      )
    })
    |> list.first,
  )

  #(State(pos:, dir:), dict.delete(queue, pos))
}

fn get_neighbors(map: Map, at: Point) -> List(State) {
  [North, South, East, West]
  |> list.map(fn(dir) {
    let pos = map.move(at, dir)
    use _ <- result.map(map.get_at(map, pos))
    State(pos:, dir:)
  })
  |> result.values
}

fn get_tentative_g_score(at: State, neighbor: State, g_scores: Scores) -> Int {
  1
  + get_score(g_scores, at.pos)
  + case int.absolute_value(turn_price(at.dir) - turn_price(neighbor.dir)) {
    3000 -> 1000
    x -> x
  }
}

fn turn_price(dir: Direction) -> Int {
  case dir {
    North -> 0
    East -> 1000
    South -> 2000
    West -> 3000
  }
}

fn update_for_neighbor(
  acc: #(Queue, Scores, Scores, CameFrom),
  curr: State,
  target: Point,
  neighbor: State,
) {
  let #(queue, f_scores, g_scores, came_from) = acc
  let tentative_g = get_tentative_g_score(curr, neighbor, g_scores)
  use <- bool.guard(tentative_g >= get_score(g_scores, neighbor.pos), acc)

  #(
    dict.insert(queue, neighbor.pos, neighbor.dir),
    dict.insert(f_scores, neighbor.pos, tentative_g + h(neighbor.pos, target)),
    dict.insert(g_scores, neighbor.pos, tentative_g),
    dict.insert(came_from, neighbor.pos, curr.pos),
  )
}
