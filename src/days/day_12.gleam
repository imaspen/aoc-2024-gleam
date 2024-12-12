import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import glearray.{type Array} as array
import utils/lines

type Point {
  Point(x: Int, y: Int)
}

type Seen =
  Set(Point)

type Map =
  Array(Array(Int))

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use map <- result.map(
    parse_input(input) |> result.replace_error("Couldn't parse input"),
  )

  map
  |> get_fence_prices(False)
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use map <- result.map(
    parse_input(input) |> result.replace_error("Couldn't parse input"),
  )

  map
  |> get_fence_prices(True)
  |> int.to_string
}

fn parse_input(input: String) -> Result(Map, Nil) {
  input
  |> lines.lines
  |> list.try_map(parse_line)
  |> result.map(array.from_list)
}

fn parse_line(line: String) -> Result(Array(Int), Nil) {
  line
  |> string.to_graphemes
  |> list.try_map(parse_char)
  |> result.map(array.from_list)
}

fn parse_char(char: String) -> Result(Int, Nil) {
  char
  |> string.to_utf_codepoints
  |> list.first
  |> result.map(string.utf_codepoint_to_int)
}

fn get_point(map: Map, point: Point) -> Result(Int, Nil) {
  array.get(map, point.y)
  |> result.try(array.get(_, point.x))
}

fn get_fence_prices(map: Map, count_edges: Bool) -> Int {
  get_fence_prices_loop(map, count_edges, Some(Point(0, 0)), set.new(), 0)
}

fn get_fence_prices_loop(
  map: Map,
  count_edges: Bool,
  maybe_pos: Option(Point),
  seen: Seen,
  acc: Int,
) -> Int {
  case maybe_pos {
    None -> acc
    Some(pos) -> {
      let next_pos = get_next_point(map, pos)
      case set.contains(seen, pos) {
        True -> get_fence_prices_loop(map, count_edges, next_pos, seen, acc)
        False -> {
          let #(next_seen, price) = get_fence_price(map, count_edges, pos, seen)
          get_fence_prices_loop(
            map,
            count_edges,
            next_pos,
            next_seen,
            acc + price,
          )
        }
      }
    }
  }
}

fn get_next_point(map: Map, pos: Point) -> Option(Point) {
  let height = array.length(map)
  let width = array.get(map, 0) |> result.lazy_unwrap(array.new) |> array.length
  case pos.x + 1 {
    nx if nx < width -> Some(Point(nx, pos.y))
    _ ->
      case pos.y + 1 {
        ny if ny < height -> Some(Point(0, ny))
        _ -> None
      }
  }
}

fn get_fence_price(
  map: Map,
  count_edges: Bool,
  pos: Point,
  seen: Seen,
) -> #(Seen, Int) {
  get_fence_price_loop(map, count_edges, set.insert(seen, pos), [pos], 0, 0)
}

fn get_fence_price_loop(
  map: Map,
  count_edges: Bool,
  seen: Seen,
  queue: List(Point),
  count_acc: Int,
  perimeter_acc: Int,
) -> #(Seen, Int) {
  case queue {
    [] -> #(seen, count_acc * perimeter_acc)
    [pos, ..rest] -> {
      let #(all_neighbors, perimeter) = get_neighbors(map, pos)
      let #(new_seen, new_queue) =
        list.fold(all_neighbors, #(seen, rest), fn(acc, neighbor) {
          let #(curr_seen, curr_queue) = acc

          case set.contains(seen, neighbor) {
            False -> #(set.insert(curr_seen, neighbor), [neighbor, ..curr_queue])
            _ -> acc
          }
        })

      get_fence_price_loop(
        map,
        count_edges,
        new_seen,
        new_queue,
        count_acc + 1,
        perimeter_acc
          + perimeter
          - case count_edges {
          True -> on_edges(map, pos)
          False -> 0
        },
      )
    }
  }
}

fn get_neighbors(map: Map, pos: Point) -> #(List(Point), Int) {
  let assert Ok(curr) = get_point(map, pos)
  let Point(x, y) = pos

  [Point(x + 1, y), Point(x - 1, y), Point(x, y + 1), Point(x, y - 1)]
  |> list.fold(#([], 0), fn(acc, point) {
    let #(neighbors, perimeter) = acc
    case get_point(map, point) {
      Ok(p) if p == curr -> #([point, ..neighbors], perimeter)
      _ -> #(neighbors, perimeter + 1)
    }
  })
}

fn on_edges(map: Map, pos: Point) -> Int {
  let curr = get_point(map, pos) |> result.unwrap(-1)
  let Point(x, y) = pos

  let gp = fn(gx, gy) {
    get_point(map, Point(gx, gy)) |> result.unwrap(-1) == curr
  }

  let is_edge_above = !gp(x, y - 1) && !gp(x + 1, y - 1) && gp(x + 1, y)
  let is_edge_right = !gp(x + 1, y) && !gp(x + 1, y + 1) && gp(x, y + 1)
  let is_edge_below = !gp(x, y + 1) && !gp(x - 1, y + 1) && gp(x - 1, y)
  let is_edge_left = !gp(x - 1, y) && !gp(x - 1, y - 1) && gp(x, y - 1)

  [is_edge_above, is_edge_right, is_edge_below, is_edge_left]
  |> list.count(fn(x) { x })
}
