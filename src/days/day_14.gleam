import days/part.{type Part, PartOne, PartTwo}
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/pair
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string_tree
import gleam/yielder
import utils/lines

type Vec {
  Vec(x: Int, y: Int)
}

type Robot {
  Robot(pos: Vec, vel: Vec)
}

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(map_size, robots) <- result.try(
    input
    |> parse_input
    |> result.replace_error("Couldn't parse input."),
  )

  use new_poses <- result.map(
    list.try_map(robots, calculate_new_position(_, map_size))
    |> result.replace_error("Couldn't parse input."),
  )

  get_safety_score(new_poses, map_size) |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use #(map_size, robots) <- result.map(
    input
    |> parse_input
    |> result.replace_error("Couldn't parse input."),
  )

  let #(robots, i) =
    yielder.iterate(robots, loop_robots(_, map_size))
    |> yielder.index
    |> yielder.take(100_000)
    |> yielder.find(fn(x) { tree_heuristic(pair.first(x)) })
    |> result.unwrap(#([], 0))

  io.println(robots_to_string(robots, map_size))

  int.to_string(i)
}

fn parse_input(input: String) -> Result(#(Vec, List(Robot)), Nil) {
  case lines.blocks(input) {
    [map_size_input, robots_input] -> {
      use map_size <- result.try(parse_vec(map_size_input))
      use robots <- result.map(list.try_map(
        lines.lines(robots_input),
        parse_robot,
      ))
      #(map_size, robots)
    }
    _ -> Error(Nil)
  }
}

fn parse_vec(input: String) -> Result(Vec, Nil) {
  let assert Ok(re) = regexp.from_string("^(-?\\d+),(-?\\d+)$")

  case regexp.scan(re, input) {
    [match] -> {
      case match.submatches {
        [Some(x_str), Some(y_str)] -> {
          use x <- result.try(int.parse(x_str))
          use y <- result.map(int.parse(y_str))
          Vec(x, y)
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_robot(input: String) -> Result(Robot, Nil) {
  let assert Ok(re) = regexp.from_string("^p=(.*?) v=(.*?)$")

  case regexp.scan(re, input) {
    [match] -> {
      case match.submatches {
        [Some(pos_str), Some(vel_str)] -> {
          use pos <- result.try(parse_vec(pos_str))
          use vel <- result.map(parse_vec(vel_str))
          Robot(pos:, vel:)
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn calculate_new_position(robot: Robot, map_size: Vec) -> Result(Vec, Nil) {
  let Robot(pos:, vel:) = robot
  use x <- result.try(int.modulo({ pos.x + vel.x * 100 }, map_size.x))
  use y <- result.map(int.modulo({ pos.y + vel.y * 100 }, map_size.y))
  Vec(x, y)
}

fn get_quadrant(pos: Vec, map_size: Vec) -> Int {
  let Vec(x: mx, y: my) = map_size
  let Vec(x:, y:) = pos

  let qx = { mx - 1 } / 2
  let qy = { my - 1 } / 2

  case int.compare(x, qx), int.compare(y, qy) {
    Eq, _ -> 0
    _, Eq -> 0
    Lt, Lt -> 1
    Lt, Gt -> 2
    Gt, Lt -> 3
    Gt, Gt -> 4
  }
}

fn get_safety_score(new_poses: List(Vec), map_size: Vec) {
  new_poses
  |> list.group(get_quadrant(_, map_size))
  |> dict.delete(0)
  |> dict.map_values(fn(_, l) { list.length(l) })
  |> dict.values
  |> int.product
}

fn step_robot(robot: Robot, map_size: Vec) -> Robot {
  let Robot(pos:, vel:) = robot
  let x = int.modulo(pos.x + vel.x, map_size.x) |> result.unwrap(0)
  let y = int.modulo(pos.y + vel.y, map_size.y) |> result.unwrap(0)
  Robot(pos: Vec(x:, y:), vel:)
}

fn loop_robots(robots: List(Robot), map_size: Vec) -> List(Robot) {
  list.map(robots, step_robot(_, map_size))
}

fn tree_heuristic(robots: List(Robot)) -> Bool {
  let points = list.fold(robots, set.new(), fn(s, r) { set.insert(s, r.pos) })
  tree_heuristic_loop(points)
}

fn tree_heuristic_loop(unseen: Set(Vec)) -> Bool {
  case unseen |> set.to_list |> list.first {
    Error(_) -> False
    Ok(point) -> {
      case is_valid([point], set.delete(unseen, point), 0) {
        #(True, _) -> True
        #(False, new_unseen) -> tree_heuristic_loop(new_unseen)
      }
    }
  }
}

fn is_valid(queue: List(Vec), unseen: Set(Vec), acc: Int) -> #(Bool, Set(Vec)) {
  case acc > 20 {
    True -> #(True, unseen)
    False -> {
      case queue {
        [] -> #(False, unseen)
        [Vec(x:, y:), ..rest] -> {
          let neighbours =
            [Vec(x + 1, y), Vec(x - 1, y), Vec(x, y + 1), Vec(x, y - 1)]
            |> list.filter(set.contains(unseen, _))

          is_valid(
            list.flatten([neighbours, rest]),
            set.delete(unseen, Vec(x, y)),
            acc + 1,
          )
        }
      }
    }
  }
}

fn robots_to_string(robots: List(Robot), map_size: Vec) -> String {
  let points = list.fold(robots, set.new(), fn(s, r) { set.insert(s, r.pos) })

  yielder.repeat(Nil)
  |> yielder.index
  |> yielder.take(map_size.y)
  |> yielder.fold(string_tree.new(), fn(block, ty) {
    let #(_, y) = ty

    yielder.repeat(Nil)
    |> yielder.index
    |> yielder.take(map_size.x)
    |> yielder.fold(block, fn(line, tx) {
      let #(_, x) = tx
      string_tree.append(line, case set.contains(points, Vec(x, y)) {
        True -> "#"
        False -> " "
      })
    })
    |> string_tree.append("\n")
  })
  |> string_tree.to_string
}
