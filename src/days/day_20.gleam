import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import utils/lines
import utils/map.{type Point, Point}

type Map =
  map.Map(Nil)

type Queue =
  Deque(#(Point, Int))

type Seen =
  Set(Point)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(threshold, map, start, end, dim) <- result.try(parse_input(input))

  use target_score <- result.map(bfs(map, start, end, 1_000_000_000))

  find_permutations(map, dim)
  |> list.map(bfs(_, start, end, target_score - threshold))
  |> result.values
  |> list.length
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

// Part 1

fn find_permutations(map: Map, dim: Point) -> List(Map) {
  let Point(x: dx, y: dy) = dim
  list.range(1, dy - 1)
  |> list.flat_map(fn(y) {
    list.range(1, dx - 1)
    |> list.map(fn(x) {
      let p = Point(x:, y:)
      case map.get_at(map, p) {
        Ok(_) -> {
          let n_walls =
            [map.North, map.South, map.East, map.West]
            |> list.map(map.move(p, _))
            |> list.map(map.get_at(map, _))
            |> list.count(result.is_ok)

          case n_walls <= 2 {
            True -> Ok(p)
            False -> Error(Nil)
          }
        }
        Error(_) -> Error(Nil)
      }
    })
    |> result.values
  })
  |> list.map(dict.delete(map, _))
}

fn bfs(
  map: Map,
  start: Point,
  target: Point,
  target_score: Int,
) -> Result(Int, String) {
  let queue = deque.from_list([#(start, 0)])
  let seen = set.new()

  bfs_loop(map, target, target_score, queue, seen)
}

fn bfs_loop(
  map: Map,
  target: Point,
  target_score: Int,
  queue: Queue,
  seen: Seen,
) -> Result(Int, String) {
  case deque.pop_front(queue) {
    Error(_) -> Error("Couldn't find a path to the point")
    Ok(#(#(at, dist), queue)) -> {
      use <- bool.guard(when: at == target, return: Ok(dist))
      use <- bool.guard(
        when: dist >= target_score,
        return: Error("Path too long"),
      )

      let #(queue, seen) =
        get_neighbors(map, at)
        |> list.fold(#(queue, seen), fn(acc, neighbor) {
          use <- bool.guard(when: set.contains(seen, neighbor), return: acc)

          let #(queue, seen) = acc
          #(
            deque.push_back(queue, #(neighbor, dist + 1)),
            set.insert(seen, neighbor),
          )
        })

      bfs_loop(map, target, target_score, queue, seen)
    }
  }
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

// Parsing

fn parse_input(
  input: String,
) -> Result(#(Int, Map, Point, Point, Point), String) {
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

  let #(map, start, end, dim) = parse_map(map_str)

  #(cheat_threshold, map, start, end, dim)
}

fn parse_map(input: String) -> #(Map, Point, Point, Point) {
  lines.lines(input)
  |> yielder.from_list
  |> yielder.index
  |> yielder.fold(
    #(map.new(), Point(0, 0), Point(0, 0), Point(0, 0)),
    parse_row,
  )
}

fn parse_row(
  acc: #(Map, Point, Point, Point),
  pair: #(String, Int),
) -> #(Map, Point, Point, Point) {
  let #(row, y) = pair
  let #(map, start, end, dim) = acc
  let dim = Point(..dim, y:)

  string.to_graphemes(row)
  |> yielder.from_list
  |> yielder.index
  |> yielder.fold(#(map, start, end, dim), fn(acc, pair) {
    parse_char(y, acc, pair)
  })
}

fn parse_char(
  y: Int,
  acc: #(Map, Point, Point, Point),
  pair: #(String, Int),
) -> #(Map, Point, Point, Point) {
  let #(char, x) = pair
  let #(map, start, end, dim) = acc
  let dim = Point(..dim, x:)

  case char {
    "#" -> #(map.insert(map, Point(x, y), Nil), start, end, dim)
    "S" -> #(map, Point(x, y), end, dim)
    "E" -> #(map, start, Point(x, y), dim)
    _ -> #(map, start, end, dim)
  }
}
