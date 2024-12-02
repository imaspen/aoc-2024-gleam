import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import utils/lines

type Level =
  Int

type Report =
  List(Level)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  lines.space_separated_ints(input)
  |> list.count(is_report_safe)
  |> int.to_string()
  |> Ok()
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn is_report_safe(report: Report) -> Bool {
  get_report_decreasing(report) |> is_report_safe_loop
}

fn get_report_decreasing(report: Report) -> Report {
  case report {
    [x, y, ..] if x < y -> list.reverse(report)
    _ -> report
  }
}

fn is_report_safe_loop(report: Report) -> Bool {
  case report {
    [_] -> True
    [x, y, ..rest] if x > y && x - 3 <= y -> is_report_safe_loop([y, ..rest])
    _ -> False
  }
}
