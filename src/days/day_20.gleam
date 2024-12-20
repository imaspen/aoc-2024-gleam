import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import utils/lines
import utils/map.{type Point, Point}

type Map =
  map.Map(Int)

type Queue =
  Deque(#(Point, Int))

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  run(input, 2)
}

fn part_2(input: String) -> Result(String, String) {
  run(input, 20)
}

fn run(input: String, cheat_durr: Int) -> Result(String, String) {
  use #(threshold, map, start, end) <- result.map(parse_input(input))
  let distances_from_start = get_distances(map, start)
  let distances_to_end = get_distances(map, end)
  let assert Ok(non_cheat_time) = map.get_at(distances_from_start, end)

  dict.to_list(distances_from_start)
  |> list.map(fn(at) {
    let #(at, dist) = at
    get_cheats(
      distances_to_end,
      at,
      dist,
      non_cheat_time,
      cheat_durr,
      threshold,
    )
  })
  |> int.sum
  |> int.to_string
}

fn get_neighbors(map: Map, of: Point) -> List(Point) {
  [map.North, map.East, map.South, map.West]
  |> list.map(fn(dir) {
    let point = map.move(of, dir)
    case map.get_at(map, point) {
      Ok(_) -> Error(Nil)
      Error(_) -> Ok(point)
    }
  })
  |> result.values
}

fn get_distances(map: Map, start: Point) -> Map {
  let queue = deque.from_list([#(start, 0)])
  let seen = dict.from_list([#(start, 0)])

  get_distances_loop(map, queue, seen)
}

fn get_distances_loop(map: Map, queue: Queue, distances: Map) -> Map {
  case deque.pop_front(queue) {
    Error(_) -> distances
    Ok(#(#(at, dist), queue)) -> {
      let #(queue, distances) =
        get_neighbors(map, at)
        |> list.fold(#(queue, distances), fn(acc, neighbor) {
          use <- bool.guard(
            when: dict.has_key(distances, neighbor),
            return: acc,
          )

          let #(queue, distances) = acc
          #(
            deque.push_back(queue, #(neighbor, dist + 1)),
            map.insert(distances, neighbor, dist + 1),
          )
        })

      get_distances_loop(map, queue, distances)
    }
  }
}

fn get_cheats(
  distances_to_end: Map,
  at: Point,
  from_start: Int,
  non_cheat_time: Int,
  cheat_durr: Int,
  target_cheat_score: Int,
) -> Int {
  list.range(-cheat_durr, cheat_durr)
  |> list.map(fn(y) {
    list.range(-cheat_durr, cheat_durr)
    |> list.count(fn(x) {
      let d = int.absolute_value(x) + int.absolute_value(y)
      case d <= cheat_durr && d >= 2 {
        True -> {
          let pos = Point(x: x + at.x, y: y + at.y)
          case map.get_at(distances_to_end, pos) {
            Error(_) -> False
            Ok(to_end) -> {
              case
                non_cheat_time - { from_start + d + to_end }
                >= target_cheat_score
              {
                True -> True
                False -> False
              }
            }
          }
        }
        False -> False
      }
    })
  })
  |> int.sum
}

// Parsing

fn parse_input(input: String) -> Result(#(Int, Map, Point, Point), String) {
  use #(cheat_threshold, map_str) <- result.map(case lines.blocks(input) {
    [a] -> Ok(#(100, a))
    [a, b] -> {
      use ct <- result.map(
        int.parse(a)
        |> result.replace_error("Couldn't parse input."),
      )
      #(ct, b)
    }
    _ -> Error("Couldn't parse input.")
  })

  let #(map, start, end) = parse_map(map_str)

  #(cheat_threshold, map, start, end)
}

fn parse_map(input: String) -> #(Map, Point, Point) {
  lines.lines(input)
  |> yielder.from_list
  |> yielder.index
  |> yielder.fold(#(map.new(), Point(0, 0), Point(0, 0)), parse_row)
}

fn parse_row(
  acc: #(Map, Point, Point),
  pair: #(String, Int),
) -> #(Map, Point, Point) {
  let #(row, y) = pair

  string.to_graphemes(row)
  |> yielder.from_list
  |> yielder.index
  |> yielder.fold(acc, fn(acc, pair) { parse_char(y, acc, pair) })
}

fn parse_char(
  y: Int,
  acc: #(Map, Point, Point),
  pair: #(String, Int),
) -> #(Map, Point, Point) {
  let #(char, x) = pair
  let #(map, start, end) = acc

  case char {
    "#" -> #(map.insert(map, Point(x, y), -1), start, end)
    "S" -> #(map, Point(x, y), end)
    "E" -> #(map, start, Point(x, y))
    _ -> acc
  }
}
