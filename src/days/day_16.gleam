import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import utils/lines
import utils/map.{type Direction, type Point, East, North, Point, South, West}

type State {
  State(pos: Point, dir: Direction)
}

type Distances =
  Dict(State, Int)

type CameFrom =
  Dict(State, List(State))

type Queue =
  Set(State)

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

  use #(score, _) <- result.map(
    dijkstra(map, start, end) |> result.replace_error("Couldn't find route."),
  )

  int.to_string(score)
}

fn part_2(input: String) -> Result(String, String) {
  use #(map, start, end) <- result.try(
    parse_input(input) |> result.replace_error("Couldn't parse input."),
  )

  use #(score, came_from) <- result.map(
    dijkstra(map, start, end) |> result.replace_error("Couldn't find route"),
  )

  came_from
  |> backtrack(start, end, score)
  |> set.fold(set.new(), fn(acc, val) { set.insert(acc, val.pos) })
  |> set.size
  |> int.to_string
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

fn dijkstra(
  map: Map,
  start_point: Point,
  end_point: Point,
) -> Result(#(Int, CameFrom), Nil) {
  let queue = set.from_list([State(start_point, East)])
  let distances = dict.from_list([#(State(start_point, East), 0)])

  dijkstra_loop(map, end_point, queue, distances, dict.new())
}

fn dijkstra_loop(
  map: Map,
  target: Point,
  queue: Queue,
  distances: Distances,
  came_from: CameFrom,
) -> Result(#(Int, CameFrom), Nil) {
  case get_current(queue, distances) {
    Error(_) -> Error(Nil)
    Ok(#(curr, rest)) -> {
      use <- bool.lazy_guard(curr.pos == target, fn() {
        use dist <- result.map(dict.get(distances, curr))
        #(dist, came_from)
      })

      let #(new_queue, new_distances, new_came_from) =
        get_neighbors(map, curr)
        |> list.fold(#(rest, distances, came_from), fn(acc, n) {
          update_for_neighbor(acc, curr, n)
        })

      dijkstra_loop(map, target, new_queue, new_distances, new_came_from)
    }
  }
}

fn get_dist_of(distances: Distances, at: State) -> Int {
  dict.get(distances, at) |> result.unwrap(1_000_000_000_000)
}

fn get_current(
  queue: Queue,
  distances: Distances,
) -> Result(#(State, Queue), Nil) {
  use state <- result.map(
    queue
    |> set.to_list
    |> list.sort(fn(a, b) {
      int.compare(get_dist_of(distances, a), get_dist_of(distances, b))
    })
    |> list.first,
  )

  #(state, set.delete(queue, state))
}

fn get_neighbors(map: Map, at: State) -> List(State) {
  let turns =
    case at.dir {
      North | South -> [State(..at, dir: West), State(..at, dir: East)]
      East | West -> [State(..at, dir: North), State(..at, dir: South)]
    }
    |> list.filter(fn(s) { map.get_at_dir(map, s.pos, s.dir) |> result.is_ok })

  case map.get_at_dir(map, at.pos, at.dir) {
    Error(_) -> turns
    Ok(_) -> [State(..at, pos: map.move(at.pos, at.dir)), ..turns]
  }
}

fn get_dist(at: State, neighbor: State) -> Int {
  get_walk_dist(at.pos, neighbor.pos) + get_turn_dist(at.dir, neighbor.dir)
}

fn get_walk_dist(at: Point, to: Point) -> Int {
  int.absolute_value(to.x - at.x) + int.absolute_value(to.y - at.y)
}

fn get_turn_dist(at: Direction, to: Direction) -> Int {
  case int.absolute_value(turn_price(at) - turn_price(to)) {
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
  acc: #(Queue, Distances, CameFrom),
  curr: State,
  neighbor: State,
) {
  let #(queue, distances, came_from) = acc
  let alt = get_dist_of(distances, curr) + get_dist(curr, neighbor)

  case int.compare(alt, get_dist_of(distances, neighbor)) {
    order.Lt -> #(
      set.insert(queue, neighbor),
      dict.insert(distances, neighbor, alt),
      dict.insert(came_from, neighbor, [curr]),
    )
    order.Eq -> {
      #(
        queue,
        distances,
        dict.upsert(came_from, neighbor, fn(ml) {
          case ml {
            None -> [curr]
            Some(l) -> [curr, ..l]
          }
        }),
      )
    }
    order.Gt -> acc
  }
}

fn backtrack(came_from: CameFrom, from: Point, to: Point, target_score: Int) {
  backtrack_loop(
    came_from,
    from,
    target_score,
    [
      #(
        State(pos: to, dir: North),
        0,
        set.from_list([State(pos: to, dir: North)]),
      ),
    ],
    set.new(),
  )
}

fn backtrack_loop(
  next: CameFrom,
  target: Point,
  target_score: Int,
  queue: List(#(State, Int, Set(State))),
  acc: Set(State),
) {
  case queue {
    [] -> acc
    [#(at, dist, seen), ..rest] -> {
      use <- bool.lazy_guard(when: at.pos == target, return: fn() {
        backtrack_loop(next, target, target_score, rest, set.union(seen, acc))
      })
      use <- bool.lazy_guard(when: dist >= target_score, return: fn() {
        backtrack_loop(next, target, target_score, rest, acc)
      })

      let ns =
        dict.get(next, at)
        |> result.unwrap([])
        |> list.filter(fn(n) { !set.contains(seen, n) })
        |> list.map(fn(n) { #(n, get_dist(n, at), set.insert(seen, n)) })

      backtrack_loop(next, target, target_score, list.flatten([ns, rest]), acc)
    }
  }
}
