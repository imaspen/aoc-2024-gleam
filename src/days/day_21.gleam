import days/part.{type Part, PartOne, PartTwo}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import utils/lines
import utils/map.{type Point, Point}

type Button {
  Void
  A
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
  Up
  Down
  Left
  Right
}

type Presses =
  List(Button)

type Input {
  Input(presses: Presses, id: Int)
}

type Buttons =
  Dict(Button, Point)

type Robot {
  Robot(buttons: Buttons, over: Button)
}

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use cache <- memo.create()

  parse_input(input)
  |> list.map(fn(input) {
    input.id * get_press_count(input.presses, generate_robots(2), cache).0
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn part_2(input: String) -> Result(String, String) {
  use cache <- memo.create()

  parse_input(input)
  |> list.map(fn(input) {
    input.id * get_press_count(input.presses, generate_robots(25), cache).0
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn generate_robots(dir_buttons_robot_count: Int) {
  [
    Robot(keypad_buttons(), A),
    ..list.repeat(Robot(dir_buttons(), A), dir_buttons_robot_count)
  ]
}

fn get_press_count(
  presses: Presses,
  robots: List(Robot),
  cache,
) -> #(Int, List(Robot)) {
  use <- memo.memoize(cache, #(presses, robots))
  list.fold(presses, #(0, robots), fn(acc, button) {
    let #(count, robots) = acc
    case robots {
      [] -> #(count + 1, robots)
      [Robot(buttons:, over:), ..rest] -> {
        let presses_list = get_presses(over, button, buttons)

        let #(new_count, new_robots) =
          list.map(presses_list, get_press_count(_, rest, cache))
          |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
          |> list.first
          |> result.unwrap(#(0, []))

        #(new_count + count, [Robot(buttons:, over: button), ..new_robots])
      }
    }
  })
}

fn get_presses(from: Button, to: Button, buttons: Buttons) {
  let Point(x: from_x, y: from_y) =
    dict.get(buttons, from) |> result.unwrap(Point(0, 0))
  let Point(x:, y:) = dict.get(buttons, to) |> result.unwrap(Point(0, 0))
  let void = dict.get(buttons, Void) |> result.unwrap(Point(0, 0))

  let xs = case x > from_x {
    True -> list.repeat(Right, x - from_x)
    False -> list.repeat(Left, from_x - x)
  }

  let ys = case y > from_y {
    True -> list.repeat(Up, y - from_y)
    False -> list.repeat(Down, from_y - y)
  }

  let x_first = list.flatten([xs, ys, [A]])
  let y_first = list.flatten([ys, xs, [A]])

  case
    Point(x, from_y) == void,
    Point(from_x, y) == void,
    list.is_empty(xs) || list.is_empty(ys)
  {
    True, _, _ -> [y_first]
    _, True, _ -> [x_first]
    _, _, True -> [x_first]
    _, _, _ -> [x_first, y_first]
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

fn keypad_buttons() -> Buttons {
  dict.from_list([
    #(Void, Point(0, 0)),
    #(Zero, Point(1, 0)),
    #(A, Point(2, 0)),
    #(One, Point(0, 1)),
    #(Two, Point(1, 1)),
    #(Three, Point(2, 1)),
    #(Four, Point(0, 2)),
    #(Five, Point(1, 2)),
    #(Six, Point(2, 2)),
    #(Seven, Point(0, 3)),
    #(Eight, Point(1, 3)),
    #(Nine, Point(2, 3)),
  ])
}

//     +---+---+
//     | ^ | A |
// +---+---+---+
// | < | v | > |
// +---+---+---+

fn dir_buttons() -> Buttons {
  dict.from_list([
    #(Left, Point(0, 0)),
    #(Down, Point(1, 0)),
    #(Right, Point(2, 0)),
    #(Void, Point(0, 1)),
    #(Up, Point(1, 1)),
    #(A, Point(2, 1)),
  ])
}

fn parse_input(input: String) -> List(Input) {
  lines.lines(input)
  |> list.map(fn(line) {
    let id =
      string.slice(line, 0, 3)
      |> int.parse
      |> result.unwrap(0)

    let presses =
      string.to_graphemes(line)
      |> list.map(string_to_button)

    Input(presses:, id:)
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
