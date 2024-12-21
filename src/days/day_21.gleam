import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils/lines

type Button {
  Zero
  One
  Two
  Three
  Four
  Five
  Six
  Seven
  Eight
  Nine
  A
  Up
  Down
  Left
  Right
}

type Presses =
  Deque(Button)

type Nodes =
  Dict(Button, List(#(Button, Button)))

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  parse_input(input)
  |> list.map(fn(line) {
    let #(val, presses) = line

    let result =
      presses
      |> deque.to_list
      |> list.window_by_2
      |> list.map(fn(pair) {
        find(keypad_buttons(), pair.first(pair), pair.second(pair), set.new())
        |> list.map(fn(presses) {
          presses
          |> deque.to_list
          |> list.prepend(A)
          |> list.window_by_2
          |> list.map(fn(pair) {
            find(dir_buttons(), pair.first(pair), pair.second(pair), set.new())
            |> list.map(fn(presses) {
              presses
              |> deque.to_list
              |> list.prepend(A)
              |> list.window_by_2
              |> list.map(fn(pair) {
                find(
                  dir_buttons(),
                  pair.first(pair),
                  pair.second(pair),
                  set.new(),
                )
                |> list.map(deque.length)
                |> list.fold(100_000, int.min)
              })
              |> int.sum
            })
            |> list.fold(100_000, int.min)
          })
          |> int.sum
        })
        |> list.fold(100_000, int.min)
      })
      |> int.sum

    val * result
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn find(
  nodes: Nodes,
  from: Button,
  to: Button,
  seen: Set(Button),
) -> List(Presses) {
  use <- bool.guard(when: from == to, return: [
    deque.new() |> deque.push_back(A),
  ])

  let neighbors =
    dict.get(nodes, from)
    |> result.unwrap([])
    |> list.filter(fn(n) { !set.contains(seen, pair.second(n)) })

  let paths =
    list.flat_map(neighbors, fn(n) {
      find(nodes, pair.second(n), to, set.insert(seen, from))
      |> list.map(fn(p) { deque.push_front(p, pair.first(n)) })
    })
    |> list.sort(fn(a, b) { int.compare(deque.length(a), deque.length(b)) })

  case paths {
    [] -> []
    [shortest, ..] -> {
      let length = deque.length(shortest)
      list.take_while(paths, fn(l) { deque.length(l) == length })
    }
  }
}

// +---+---+---+
// | 7 | 8 | 9 |
// +---+---+---+
// | 4 | 5 | 6 |
// +---+---+---+
// | 1 | 2 | 3 |
// +---+---+---+
//     | 0 | A |
//     +---+---+

fn keypad_buttons() -> Nodes {
  dict.from_list([
    #(A, [#(Left, Zero), #(Up, Three)]),
    #(Zero, [#(Right, A), #(Up, Two)]),
    #(One, [#(Right, Two), #(Up, Four)]),
    #(Two, [#(Down, Zero), #(Left, One), #(Right, Three), #(Up, Five)]),
    #(Three, [#(Down, A), #(Left, Two), #(Up, Six)]),
    #(Four, [#(Down, One), #(Right, Five), #(Up, Seven)]),
    #(Five, [#(Down, Two), #(Left, Four), #(Right, Six), #(Up, Eight)]),
    #(Six, [#(Down, Three), #(Left, Five), #(Up, Nine)]),
    #(Seven, [#(Down, Four), #(Right, Eight)]),
    #(Eight, [#(Down, Five), #(Left, Seven), #(Right, Nine)]),
    #(Nine, [#(Down, Six), #(Left, Eight)]),
  ])
}

//     +---+---+
//     | ^ | A |
// +---+---+---+
// | < | v | > |
// +---+---+---+

fn dir_buttons() -> Nodes {
  dict.from_list([
    #(Left, [#(Right, Down)]),
    #(Down, [#(Left, Left), #(Right, Right), #(Up, Up)]),
    #(Right, [#(Left, Down), #(Up, A)]),
    #(Up, [#(Down, Down), #(Right, A)]),
    #(A, [#(Left, Up), #(Down, Right)]),
  ])
}

fn parse_input(input: String) -> List(#(Int, Presses)) {
  lines.lines(input)
  |> list.map(fn(line) {
    let amount =
      string.slice(line, 0, 3)
      |> int.parse
      |> result.unwrap(0)

    let presses =
      string.to_graphemes(line)
      |> list.map(string_to_button)
      |> list.prepend(A)
      |> deque.from_list

    #(amount, presses)
  })
}

fn string_to_button(input: String) -> Button {
  case input {
    "0" -> Zero
    "1" -> One
    "2" -> Two
    "3" -> Three
    "4" -> Four
    "5" -> Five
    "6" -> Six
    "7" -> Seven
    "8" -> Eight
    "9" -> Nine
    "^" -> Up
    "v" -> Down
    "<" -> Left
    ">" -> Right
    _ -> A
  }
}
