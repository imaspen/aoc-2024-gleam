import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/deque
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils/lines
import utils/map.{type Point, Point}

type Map =
  map.Map(Nil)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(map, dim) <- result.try(parse_input(input, 1024))
  use res <- result.map(bfs(map, dim))
  res |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use #(points, max) <- result.try(parse_points(input))
  binary_search(points, max) |> result.replace_error("Couldn't find point")
}

// Part 1

type Queue =
  deque.Deque(#(Point, Int))

type Seen =
  Set(Point)

fn bfs(map: Map, to: Int) -> Result(Int, String) {
  let queue = deque.from_list([#(Point(0, 0), 0)])
  let seen = set.new()

  bfs_loop(map, to, queue, seen)
}

fn bfs_loop(map: Map, to: Int, queue: Queue, seen: Seen) -> Result(Int, String) {
  case deque.pop_front(queue) {
    Error(_) -> Error("Couldn't find a path to the point")
    Ok(#(#(at, dist), queue)) -> {
      use <- bool.guard(when: at.x == to && at.y == to, return: Ok(dist))

      let #(queue, seen) =
        get_neighbors(map, at, to)
        |> list.fold(#(queue, seen), fn(acc, neighbor) {
          use <- bool.guard(when: set.contains(seen, neighbor), return: acc)

          let #(queue, seen) = acc
          #(
            deque.push_back(queue, #(neighbor, dist + 1)),
            set.insert(seen, neighbor),
          )
        })

      bfs_loop(map, to, queue, seen)
    }
  }
}

fn get_neighbors(map: Map, of: Point, max: Int) -> List(Point) {
  [map.North, map.East, map.South, map.West]
  |> list.map(fn(dir) {
    let point = map.move(of, dir)
    case map.get_at(map, point) {
      Ok(_) -> Error(Nil)
      Error(_) -> {
        case point.x > max || point.x < 0 || point.y > max || point.y < 0 {
          True -> Error(Nil)
          False -> Ok(point)
        }
      }
    }
  })
  |> result.values
}

// Part 2

fn binary_search(points: List(Point), map_size: Int) -> Result(String, Nil) {
  let time = binary_search_loop(points, map_size, 0, list.length(points))
  io.println(time |> int.to_string)
  use point <- result.map(list.drop(points, time) |> list.first)
  string.join([point.x, point.y] |> list.map(int.to_string), ",")
}

fn binary_search_loop(
  points: List(Point),
  map_size: Int,
  min: Int,
  max: Int,
) -> Int {
  use <- bool.guard(when: max - min <= 1, return: min)
  let mid = { min + max } / 2
  let map = build_map(points, mid)
  case bfs(map, map_size) {
    Error(_) -> binary_search_loop(points, map_size, min, mid)
    Ok(_) -> binary_search_loop(points, map_size, mid, max)
  }
}

// Parsing

fn parse_input(input: String, time: Int) -> Result(#(Map, Int), String) {
  use #(points, max) <- result.map(parse_points(input))

  #(build_map(points, time), max)
}

fn build_map(points: List(Point), time: Int) -> Map {
  points
  |> list.take(time)
  |> list.fold(map.new(), fn(map, point) { map.insert(map, point, Nil) })
}

fn parse_points(input: String) -> Result(#(List(Point), Int), String) {
  use lines <- result.try(lines.csv_int_lines(input))
  use max <- result.try(
    list.flatten(lines)
    |> list.sort(fn(a, b) { int.compare(b, a) })
    |> list.first
    |> result.replace_error("Couldn't find input dimensions."),
  )

  use points <- result.map(
    lines
    |> list.try_map(fn(line) {
      case line {
        [x, y] -> {
          Ok(Point(x, y))
        }
        _ -> Error("Malformed points.")
      }
    }),
  )

  #(points, max)
}
