import days/part.{type Part, PartOne, PartTwo}
import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/regexp
import gleam/result
import gleam/string

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  get_mults(input)
  |> list.fold(0, fn(acc, val) { pair.first(val) * pair.second(val) + acc })
  |> int.to_string
  |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  get_conditional_mults(input)
  |> list.fold(0, fn(acc, val) { pair.first(val) * pair.second(val) + acc })
  |> int.to_string
  |> Ok
}

fn get_conditional_mults(input: String) {
  let assert Ok(re) =
    regexp.from_string(
      "don't\\(\\).*?(?:(?=don't\\(\\))|do\\(\\))|don't\\(\\).*?$",
    )

  // gleam doesn't support single line mode in regexp,
  // so replace new lines with spaces
  let single_lined = string.replace(input, "\n", " ")

  regexp.split(re, single_lined)
  |> string.join("")
  |> get_mults
}

fn get_mults(input: String) -> List(#(Int, Int)) {
  let assert Ok(re) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")

  regexp.scan(re, input)
  |> list.map(fn(match) { match.submatches })
  |> list.filter_map(fn(submatches) {
    let matches =
      list.try_map(submatches, fn(submatch) {
        use match <- result.try(submatch |> option.to_result(Nil))
        int.parse(match)
      })
    case matches {
      Ok([x, y]) -> Ok(#(x, y))
      _ -> Error(Nil)
    }
  })
}
