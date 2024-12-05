import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils/lines

type Page =
  Int

type RuleDefinition =
  #(Page, Page)

type Pages =
  List(Page)

type LowerPages =
  Set(Page)

type Rules =
  Dict(Page, LowerPages)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(pages_list, rules) <- result.try(get_pages_and_rules(input))

  pages_list
  |> list.filter(is_sorted(_, rules))
  |> list.map(get_middle_page)
  |> int.sum
  |> int.to_string
  |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  use #(pages_list, rules) <- result.try(get_pages_and_rules(input))

  pages_list
  |> list.filter_map(required_sorting(_, rules))
  |> list.map(get_middle_page)
  |> int.sum
  |> int.to_string
  |> Ok
}

fn get_pages_and_rules(input: String) -> Result(#(List(Pages), Rules), String) {
  use #(rules, pages) <- result.try(case lines.blocks(input) {
    [rules, pages] -> Ok(#(rules, pages))
    _ -> Error("Could not parse input")
  })
  use pages_list <- result.try(
    lines.csv_int_lines(pages) |> result.replace_error("Could not parse pages"),
  )
  use definitions <- result.try(lines.lines(rules) |> parse_definitions)
  let rules = create_rules(definitions)

  Ok(#(pages_list, rules))
}

fn parse_definitions(
  input: List(String),
) -> Result(List(RuleDefinition), String) {
  list.try_map(input, parse_definition)
  |> result.replace_error("Could not parse rules")
}

fn parse_definition(input: String) -> Result(RuleDefinition, Nil) {
  use #(lhs, rhs) <- result.try(string.split_once(input, "|"))
  case int.parse(lhs), int.parse(rhs) {
    Ok(l), Ok(r) -> Ok(#(l, r))
    _, _ -> Error(Nil)
  }
}

fn create_rules(defs: List(RuleDefinition)) -> Rules {
  list.fold(defs, dict.new(), add_rule)
}

fn add_rule(rules: Rules, def: RuleDefinition) -> Rules {
  let #(lhs, rhs) = def

  rules
  |> dict.upsert(lhs, init_lower_pages)
  |> dict.upsert(rhs, add_lesser(_, lhs))
}

fn init_lower_pages(lower_pages: Option(LowerPages)) -> LowerPages {
  case lower_pages {
    None -> set.new()
    Some(set) -> set
  }
}

fn add_lesser(lower_pages: Option(LowerPages), page: Page) -> LowerPages {
  lower_pages
  |> init_lower_pages
  |> set.insert(page)
}

fn compare_pages(a: Page, b: Page, rules: Rules) -> Order {
  let lt = dict.get(rules, b) |> result.unwrap(set.new()) |> set.contains(a)

  case a, b {
    _, _ if a == b -> Eq
    _, _ if lt -> Lt
    _, _ -> Gt
  }
}

fn is_sorted(pages: Pages, rules: Rules) -> Bool {
  pages == list.sort(pages, fn(a, b) { compare_pages(a, b, rules) })
}

fn required_sorting(pages: Pages, rules: Rules) -> Result(Pages, Nil) {
  let sorted = list.sort(pages, fn(a, b) { compare_pages(a, b, rules) })

  case pages == sorted {
    True -> Error(Nil)
    False -> Ok(sorted)
  }
}

fn get_middle_page(pages: Pages) -> Int {
  list.split(pages, list.length(pages) / 2)
  |> pair.second
  |> list.first
  |> result.unwrap(0)
}
