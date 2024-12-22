import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/yielder
import parallel_map.{MatchSchedulersOnline}
import utils/lines

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use numbers <- result.map(parse_input(input))
  numbers |> list.map(do_iterations(_, 2000)) |> int.sum |> int.to_string
}

fn pmap(list: List(a), apply: fn(a) -> b, default: b) -> List(b) {
  parallel_map.list_pmap(list, apply, MatchSchedulersOnline, 1000)
  |> list.map(result.unwrap(_, default))
}

fn part_2(input: String) -> Result(String, String) {
  use numbers <- result.try(parse_input(input))

  let prices_list =
    numbers
    |> pmap(get_iterations(_, 2000), [])
    |> pmap(list.map(_, fn(x) { x % 10 }), [])

  let price_changes_list =
    prices_list
    |> pmap(
      fn(prices) {
        list.window_by_2(prices)
        |> list.map(fn(price_pair) {
          pair.second(price_pair) - pair.first(price_pair)
        })
        |> list.window(4)
      },
      [],
    )

  let lut_list =
    pmap(
      list.zip(prices_list, price_changes_list),
      fn(in) {
        let #(prices, price_changes) = in
        yielder.from_list(price_changes)
        |> yielder.index
        |> yielder.to_list
        |> list.fold_right(dict.new(), fn(dict, val) {
          let #(window, i) = val
          dict.insert(
            dict,
            window,
            list.drop(prices, i + 4) |> list.first |> result.unwrap(0),
          )
        })
      },
      dict.new(),
    )

  let to_try_list =
    list.fold(price_changes_list, set.new(), fn(acc, price_changes) {
      list.fold(price_changes, acc, set.insert)
    })
    |> set.to_list

  pmap(
    to_try_list,
    fn(to_try) {
      list.map(lut_list, fn(lut) { dict.get(lut, to_try) |> result.unwrap(0) })
      |> int.sum
    },
    0,
  )
  |> list.reduce(int.max)
  |> result.map(int.to_string)
  |> result.replace_error("Couldn't find min.")
}

fn do_iterations(n: Int, count: Int) -> Int {
  use <- bool.guard(when: count == 0, return: n)
  do_iterations(iterate(n), count - 1)
}

fn get_iterations(n: Int, count: Int) -> List(Int) {
  use <- bool.guard(when: count == 0, return: [n])
  [n, ..get_iterations(iterate(n), count - 1)]
}

fn iterate(n: Int) {
  let n = mix_and_prune(n * 64, n)
  let n = mix_and_prune(n / 32, n)
  mix_and_prune(n * 2048, n)
}

fn mix_and_prune(n: Int, secret: Int) -> Int {
  let n = int.bitwise_exclusive_or(n, secret)
  n % 16_777_216
}

fn parse_input(input: String) -> Result(List(Int), String) {
  use lines <- result.try(lines.csv_int_lines(input))
  list.try_map(lines, list.first)
  |> result.replace_error("Couldn't parse input.")
}
