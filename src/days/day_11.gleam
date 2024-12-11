import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/yielder
import utils/lines

type Stones =
  Dict(Int, Int)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use stones <- result.map(
    input
    |> lines.space_separated_ints
    |> list.first
    |> result.replace_error("Couldn't parse input."),
  )

  yielder.repeat(Nil)
  |> yielder.take(25)
  |> yielder.fold(stones, fn(stones, _) { blink(stones) })
  |> list.length
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  // turns out the order of the stones isn't important after all...

  use stones <- result.map(
    input
    |> lines.space_separated_ints
    |> list.first
    |> result.replace_error("Couldn't parse input."),
  )

  let stones_map =
    list.group(stones, fn(s) { s })
    |> dict.map_values(fn(_, l) { list.length(l) })

  yielder.repeat(Nil)
  |> yielder.take(75)
  |> yielder.fold(stones_map, fn(stones, _) { blink_map(stones) })
  |> dict.values
  |> int.sum
  |> int.to_string
}

fn blink(stones: List(Int)) -> List(Int) {
  list.flat_map(stones, mutate_stone)
}

fn blink_map(stones: Stones) -> Stones {
  stones
  |> dict.to_list
  |> list.fold(dict.new(), fn(n_stones, input) {
    let #(stone, count) = input
    stone
    |> mutate_stone
    |> list.fold(n_stones, fn(nn_stones, new_stone) {
      dict.upsert(nn_stones, new_stone, fn(b) { upsert_stones(b, count) })
    })
  })
}

fn upsert_stones(maybe_count: Option(Int), to_add: Int) -> Int {
  case maybe_count {
    None -> to_add
    Some(count) -> count + to_add
  }
}

fn mutate_stone(stone: Int) -> List(Int) {
  case stone {
    0 -> [1]
    _ ->
      case log_10(stone) {
        x if x % 2 == 0 -> split_stone(stone, x)
        _ -> [stone * 2024]
      }
  }
}

fn log_10(stone: Int) -> Int {
  log_10_loop(stone, 1)
}

fn log_10_loop(stone: Int, acc: Int) -> Int {
  case stone < 10 {
    True -> acc
    False -> log_10_loop(stone / 10, acc + 1)
  }
}

fn split_stone(stone: Int, stone_length: Int) -> List(Int) {
  let divisor =
    int.power(10, int.to_float(stone_length / 2))
    |> result.unwrap(0.0)
    |> float.truncate

  [stone / divisor, stone % divisor]
}
