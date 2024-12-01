import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import utils/lines

type Lists =
  #(List(Int), List(Int))

type Pair =
  #(Int, Int)

type Frequencies =
  Dict(Int, Int)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use parsed <- result.try(parse_input(input))

  parsed
  |> sort_lists()
  |> zip_lists()
  |> list.map(calc_diff)
  |> int.sum()
  |> int.to_string()
  |> Ok()
}

fn part_2(input: String) -> Result(String, String) {
  use parsed <- result.try(parse_input(input))

  get_similarity_scores(get_frequencies(parsed.0), get_frequencies(parsed.1))
  |> int.sum()
  |> int.to_string()
  |> Ok()
}

fn parse_input(input: String) -> Result(Lists, String) {
  lines.lines(input)
  |> list.fold(Ok(#([], [])), parse_line)
}

fn parse_line(
  lists_result: Result(Lists, String),
  line: String,
) -> Result(Lists, String) {
  use lists <- result.try(lists_result)

  case string.split(line, "   ") |> list.map(int.parse) {
    // empty line case
    [Error(Nil)] -> Ok(lists)
    [Ok(a), Ok(b)] -> Ok(#([a, ..lists.0], [b, ..lists.1]))
    _ -> Error("Failed to parse input file")
  }
}

fn sort_lists(lists: Lists) -> Lists {
  let #(a, b) = lists

  #(list.sort(a, int.compare), list.sort(b, int.compare))
}

fn zip_lists(lists: Lists) -> List(Pair) {
  list.zip(lists.0, lists.1)
}

fn calc_diff(pair: Pair) -> Int {
  int.absolute_value(pair.0 - pair.1)
}

fn get_frequencies(ints: List(Int)) -> Frequencies {
  list.fold(ints, dict.new(), update_frequencies)
}

fn update_frequencies(frequencies: Frequencies, value: Int) -> Frequencies {
  dict.upsert(frequencies, value, fn(x) {
    case x {
      Some(x) -> x + 1
      None -> 1
    }
  })
}

fn get_similarity_scores(lhs: Frequencies, rhs: Frequencies) -> List(Int) {
  lhs
  |> dict.to_list()
  |> list.map(calc_similarity_score(_, rhs))
}

fn calc_similarity_score(
  value: #(Int, Int),
  rhs_frequencies: Frequencies,
) -> Int {
  let #(id, count) = value

  id * count * { dict.get(rhs_frequencies, id) |> result.unwrap(0) }
}
