import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import utils/lines

type Equation {
  Equation(target: Int, parts: List(Int))
}

type Operator {
  Add
  Multiply
}

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use equations <- result.try(
    input
    |> lines.lines
    |> list.try_map(parse_equation),
  )

  list.filter(equations, check_equation)
  |> list.map(fn(e) { e.target })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn parse_equation(line: String) -> Result(Equation, String) {
  use #(target_str, rest) <- result.try(
    string.split_once(line, ": ")
    |> result.replace_error("Failed to split string"),
  )
  use target <- result.try(
    int.parse(target_str) |> result.replace_error("Failed to parse target"),
  )
  use parts <- result.try(
    string.split(rest, " ")
    |> list.try_map(int.parse)
    |> result.replace_error("Failed to parse equation rhs"),
  )

  Ok(Equation(target, parts))
}

fn check_equation(equation: Equation) -> Bool {
  check_equation_loop(equation.target, equation.parts, 0, Add)
}

fn check_equation_loop(
  target: Int,
  remaining: List(Int),
  total: Int,
  operator: Operator,
) -> Bool {
  case remaining {
    [] -> total == target
    [next, ..rest] -> {
      let new_total = do_operation(total, operator, next)

      check_equation_loop(target, rest, new_total, Add)
      || check_equation_loop(target, rest, new_total, Multiply)
    }
  }
}

fn do_operation(lhs: Int, operator: Operator, rhs: Int) -> Int {
  case operator {
    Add -> lhs + rhs
    Multiply -> lhs * rhs
  }
}
