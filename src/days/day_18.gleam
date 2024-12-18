import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/deque
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
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
  use #(map, dim) <- result.map(parse_input(input))

  bfs(map, Point(0, 0), dim) |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

// Part 1

type Queue =
  deque.Deque(#(Point, Int))

type Seen =
  Set(Point)

fn bfs(map: Map, from: Point, to: Int) {
  let queue = deque.from_list([#(from, 0)])
  let seen = set.new()

  bfs_loop(map, to, queue, seen)
}

fn bfs_loop(map: Map, to: Int, queue: Queue, seen: Seen) {
  case deque.pop_front(queue) {
    Error(_) -> -1
    Ok(#(#(at, dist), queue)) -> {
      use <- bool.guard(when: at.x == to && at.y == to, return: dist)

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

// Parsing

fn parse_input(input: String) -> Result(#(Map, Int), String) {
  use #(points, max) <- result.map(parse_points(input))

  let map =
    points
    |> list.take(1024)
    |> list.fold(map.new(), fn(map, point) { map.insert(map, point, Nil) })

  #(map, max)
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
    |> list.take(1024)
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
