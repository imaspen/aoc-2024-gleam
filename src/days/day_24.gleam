import days/part.{type Part, PartOne, PartTwo}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
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
  use outputs <- result.try(
    parse_input(input)
    |> result.replace_error("Couldn't parse input."),
  )

  let assert [z] =
    string.to_utf_codepoints("z") |> list.map(string.utf_codepoint_to_int)

  sum_output_for_codepoint(outputs, z)
  |> result.replace_error("Couldn't run input.")
  |> result.map(int.to_string)
}

fn part_2(input: String) -> Result(String, String) {
  use gates <- result.map(
    parse_input(input)
    |> result.replace_error("Couldn't parse input."),
  )

  gates
  |> dict.keys
  |> list.fold(set.new(), fn(acc, l) { is_gate_valid(gates, acc, l) })
  |> set.to_list
  |> list.map(label_to_string)
  |> list.sort(string.compare)
  |> list.take(8)
  |> string.join(",")
}

fn is_gate_valid(gates: Outputs, invalid: Set(Label), label: Label) {
  let assert [z] =
    string.to_utf_codepoints("z") |> list.map(string.utf_codepoint_to_int)
  let assert Ok(gate) = dict.get(gates, label)

  let invalid = case gate {
    Or(a, b) -> {
      case dict.get(gates, a), dict.get(gates, b) {
        Ok(And(_, _)), Ok(And(_, _)) -> invalid
        Ok(And(_, _)), _ -> set.insert(invalid, b)
        _, Ok(And(_, _)) -> set.insert(invalid, a)
        _, _ -> invalid |> set.insert(a) |> set.insert(b)
      }
    }
    Xor(a, b) -> {
      case is_input_valid_for_xor(gates, a), is_input_valid_for_xor(gates, b) {
        True, True -> invalid
        True, False -> set.insert(invalid, b)
        False, True -> set.insert(invalid, a)
        False, False -> invalid |> set.insert(a) |> set.insert(b)
      }
    }
    _ -> invalid
  }
  case label.a == z, gate {
    False, _ -> invalid
    True, Xor(_, _) -> invalid
    True, _ -> set.insert(invalid, label)
  }
}

fn is_input_valid_for_xor(gates: Outputs, label: Label) {
  let assert [x, y, zero] =
    string.to_utf_codepoints("xy0") |> list.map(string.utf_codepoint_to_int)

  let x_label = Label(x, zero, zero)
  let y_label = Label(y, zero, zero)

  case dict.get(gates, label) {
    Ok(And(a, b)) ->
      { a == x_label && b == y_label } || { a == y_label && b == x_label }
    Ok(Xor(a, b)) -> { a.a == x && b.a == y } || { a.a == y && b.a == x }
    _ -> True
  }
}

fn sum_output_for_codepoint(
  outputs: Outputs,
  codepoint: Int,
) -> Result(Int, Nil) {
  dict.keys(outputs)
  |> list.filter(fn(l) { l.a == codepoint })
  |> list.sort(fn(a, b) { int.compare(label_to_int(a), label_to_int(b)) })
  |> list.try_map(get_output(outputs, _))
  |> result.map(list.fold_right(_, 0, fold))
}

fn fold(acc: Int, val: Bool) -> Int {
  let acc = int.bitwise_shift_left(acc, 1)
  use <- bool.guard(when: !val, return: acc)
  acc + 1
}

fn get_output(outputs: Outputs, label: Label) -> Result(Bool, Nil) {
  case dict.get(outputs, label) {
    Ok(And(a, b)) if a != label && b != label -> {
      use a_val <- result.try(get_output(outputs, a))
      use b_val <- result.map(get_output(outputs, b))
      a_val && b_val
    }
    Ok(Or(a, b)) if a != label && b != label -> {
      use a_val <- result.try(get_output(outputs, a))
      use b_val <- result.map(get_output(outputs, b))
      a_val || b_val
    }
    Ok(Xor(a, b)) if a != label && b != label -> {
      use a_val <- result.try(get_output(outputs, a))
      use b_val <- result.map(get_output(outputs, b))
      bool.exclusive_or(a_val, b_val)
    }
    Ok(Literal(l)) -> Ok(l)
    _ -> Error(Nil)
  }
}

fn label_to_int(label: Label) {
  int.bitwise_shift_left(label.a, 16)
  + int.bitwise_shift_left(label.b, 8)
  + label.c
}

fn label_to_string(label: Label) {
  let assert Ok(a) = string.utf_codepoint(label.a)
  let assert Ok(b) = string.utf_codepoint(label.b)
  let assert Ok(c) = string.utf_codepoint(label.c)
  string.from_utf_codepoints([a, b, c])
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
