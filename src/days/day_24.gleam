import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import utils/lines

type Label {
  Label(a: Int, b: Int, c: Int)
}

type Output {
  Literal(val: Bool)
  And(a: Label, b: Label)
  Or(a: Label, b: Label)
  Xor(a: Label, b: Label)
}

type Outputs =
  Dict(Label, Output)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use outputs <- result.map(
    parse_input(input)
    |> result.replace_error("Couldn't parse input."),
  )

  let assert [z] =
    string.to_utf_codepoints("z") |> list.map(string.utf_codepoint_to_int)

  dict.keys(outputs)
  |> list.filter(fn(l) { l.a == z })
  |> list.sort(fn(a, b) { int.compare(label_to_int(a), label_to_int(b)) })
  |> list.map(get_output(outputs, _))
  |> list.fold_right(0, fold)
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn fold(acc: Int, val: Bool) {
  let acc = int.bitwise_shift_left(acc, 1)
  use <- bool.guard(when: !val, return: acc)
  acc + 1
}

fn get_output(outputs: Outputs, label: Label) {
  case dict.get(outputs, label) {
    Ok(And(a, b)) -> get_output(outputs, a) && get_output(outputs, b)
    Ok(Or(a, b)) -> get_output(outputs, a) || get_output(outputs, b)
    Ok(Xor(a, b)) ->
      bool.exclusive_or(get_output(outputs, a), get_output(outputs, b))
    Ok(Literal(l)) -> l
    Error(_) -> False
  }
}

fn label_to_int(label: Label) {
  int.bitwise_shift_left(label.a, 16)
  + int.bitwise_shift_left(label.b, 8)
  + label.c
}

fn parse_input(input: String) {
  case lines.blocks(input) {
    [a, b] -> {
      parse_inputs(dict.new(), a) |> result.try(parse_gates(_, b))
    }
    _ -> Error(Nil)
  }
}

fn parse_inputs(outputs: Outputs, input: String) -> Result(Outputs, Nil) {
  let assert Ok(re) = regexp.from_string("^([a-z\\d]{3}): ([01])$")

  lines.lines(input)
  |> list.try_fold(outputs, fn(outputs, line) {
    use match <- result.try(regexp.scan(re, line) |> list.first)
    case match.submatches {
      [Some(a), Some(b)] -> {
        use label <- result.try(parse_label(a))
        use literal <- result.map(parse_literal(b))
        dict.insert(outputs, label, literal)
      }
      _ -> Error(Nil)
    }
  })
}

fn parse_gates(outputs: Outputs, input: String) {
  let assert Ok(re) =
    regexp.from_string(
      "^([a-z\\d]{3}) (AND|OR|XOR) ([a-z\\d]{3}) -> ([a-z\\d]{3})$",
    )

  lines.lines(input)
  |> list.try_fold(outputs, fn(outputs, line) {
    use match <- result.try(regexp.scan(re, line) |> list.first)
    case match.submatches {
      [Some(a), Some(g), Some(b), Some(c)] -> {
        use label_a <- result.try(parse_label(a))
        use label_b <- result.try(parse_label(b))
        use label_c <- result.try(parse_label(c))
        use gate <- result.map(parse_gate(g, label_a, label_b))
        dict.insert(outputs, label_c, gate)
      }
      _ -> Error(Nil)
    }
  })
}

fn parse_label(input: String) -> Result(Label, Nil) {
  let parts =
    input
    |> string.to_utf_codepoints
    |> list.map(string.utf_codepoint_to_int)

  case parts {
    [a, b, c] -> Ok(Label(a, b, c))
    _ -> Error(Nil)
  }
}

fn parse_literal(input: String) -> Result(Output, Nil) {
  case input {
    "0" -> Ok(Literal(False))
    "1" -> Ok(Literal(True))
    _ -> Error(Nil)
  }
}

fn parse_gate(input: String, a: Label, b: Label) {
  case input {
    "AND" -> Ok(And(a:, b:))
    "OR" -> Ok(Or(a:, b:))
    "XOR" -> Ok(Xor(a:, b:))
    _ -> Error(Nil)
  }
}
