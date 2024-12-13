import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import utils/lines

type Vec2 {
  Vec2(x: Int, y: Int)
}

type Machine {
  Machine(a: Vec2, b: Vec2, prize: Vec2)
}

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use machines <- result.map(
    parse_machines(input) |> result.replace_error("Couldn't parse input"),
  )

  machines |> solve_machines |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  use machines <- result.map(
    parse_machines(input) |> result.replace_error("Couldn't parse input"),
  )

  machines |> list.map(fix_machine) |> solve_machines |> int.to_string
}

fn fix_machine(machine: Machine) -> Machine {
  Machine(
    machine.a,
    machine.b,
    Vec2(
      machine.prize.x + 10_000_000_000_000,
      machine.prize.y + 10_000_000_000_000,
    ),
  )
}

fn parse_machines(input: String) -> Result(List(Machine), Nil) {
  input |> lines.blocks |> list.try_map(parse_machine)
}

fn parse_machine(input: String) -> Result(Machine, Nil) {
  let assert Ok(button_regexp) =
    regexp.from_string("^Button [AB]: X\\+(\\d+), Y\\+(\\d+)$")
  let assert Ok(prize_regexp) =
    regexp.from_string("^Prize: X=(\\d+), Y=(\\d+)$")

  case lines.lines(input) {
    [a, b, t] -> {
      use match_a <- result.try(regexp.scan(button_regexp, a) |> list.first)
      use match_b <- result.try(regexp.scan(button_regexp, b) |> list.first)
      use match_t <- result.try(regexp.scan(prize_regexp, t) |> list.first)

      let unwrap_submatches = fn(submatches) {
        list.map(submatches, fn(opt) {
          opt |> option.to_result(Nil) |> result.try(int.parse)
        })
      }

      case
        unwrap_submatches(match_a.submatches),
        unwrap_submatches(match_b.submatches),
        unwrap_submatches(match_t.submatches)
      {
        [Ok(x_a), Ok(y_a)], [Ok(x_b), Ok(y_b)], [Ok(x_t), Ok(y_t)] -> {
          Ok(Machine(Vec2(x_a, y_a), Vec2(x_b, y_b), Vec2(x_t, y_t)))
        }
        _, _, _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn solve_machines(machines: List(Machine)) -> Int {
  machines |> list.map(solve_machine) |> int.sum
}

// x_, y_ are x y offsets for buttons, and coordinates for the target
// p_ is number of presses
//
// _t is the target
// _a is button a
// _b is button b
//
// knowns: x_*, y_*
// unknowns: p_*
//
// x_t = p_a * x_a + p_b * x_b
// y_t = p_a * y_a + p_b * y_b
//
// isolate presses of a
//
// p_a * x_a = x_t - p_b * x_b
// p_a = (x_t - p_b * x_b) / x_a
//
// p_a * y_a = y_t - p_b * y_b
// p_a = (y_t - p_b * y_b) / y_a
//
// derive equation for presses of b
//
// (x_t - p_b * x_b) / x_a = (y_t - p_b * y_b) / y_a
// y_a * (x_t - p_b * x_b) = x_a * (y_t - p_b * y_b)
// y_a * x_t - y_a * p_b * x_b = x_a * y_t - x_a * p_b * y_b
// y_a * x_t - y_a * p_b * x_b + x_a * p_b * y_b = x_a * y_t
// y_a * x_t + x_a * p_b * y_b - y_a * p_b * x_b = x_a * y_t
// x_a * p_b * y_b - y_a * p_b * x_b = x_a * y_t - y_a * x_t
// p_b * (x_a * y_b - y_a * x_b) = x_a * y_t - y_a * x_t
// p_b = (x_a * y_t - y_a * x_t) / (x_a * y_b - y_a * x_b)
fn solve_machine(machine: Machine) -> Int {
  let Machine(a:, b:, prize: t) = machine

  let p_b = { a.x * t.y - a.y * t.x } / { a.x * b.y - a.y * b.x }
  let p_a = { t.x - p_b * b.x } / a.x

  case Vec2(p_a * a.x + p_b * b.x, p_a * a.y + p_b * b.y) == t {
    True -> p_a * 3 + p_b
    False -> 0
  }
}
