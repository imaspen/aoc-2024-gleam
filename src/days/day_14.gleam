import days/part.{type Part, PartOne, PartTwo}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/regexp
import gleam/result
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
  todo
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
