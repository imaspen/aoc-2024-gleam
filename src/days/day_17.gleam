import days/part.{type Part, PartOne, PartTwo}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import glearray.{type Array} as array
import utils/lines

type Register {
  RegA
  RegB
  RegC
}

type Operand {
  Literal(n: Int)
  Register(reg: Register)
}

type Instruction {
  Adv(op: Operand)
  Bxl(n: Int)
  Bst(op: Operand)
  Jnz(n: Int)
  Bxc
  Out(op: Operand)
  Bdv(op: Operand)
  Cdv(op: Operand)
}

type Instructions =
  Array(Instruction)

type Registers {
  Registers(a: Int, b: Int, c: Int)
}

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use #(registers, instructions) <- result.map(
    parse_input(input)
    |> result.replace_error("Couldn't parse input."),
  )

  step(instructions, registers)
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

// Part 1

fn step(instructions: Instructions, registers: Registers) -> String {
  let output = step_loop(instructions, registers, 0, [])
  output |> list.reverse |> list.map(int.to_string) |> string.join(",")
}

fn step_loop(
  instructions: Instructions,
  registers: Registers,
  pc: Int,
  output: List(Int),
) -> List(Int) {
  let Registers(a:, b:, c:) = registers
  case array.get(instructions, pc) {
    Error(Nil) -> output
    Ok(instruction) -> {
      case instruction {
        Adv(operand) -> {
          let val =
            int.to_float(a)
            |> float.divide(
              float.power(
                2.0,
                get_combo_value(operand, registers) |> int.to_float,
              )
              |> result.unwrap(0.0),
            )
            |> result.unwrap(0.0)
            |> float.truncate

          step_loop(instructions, Registers(a: val, b:, c:), pc + 1, output)
        }
        Bxl(n) -> {
          let val = int.bitwise_exclusive_or(b, n)
          step_loop(instructions, Registers(a:, b: val, c:), pc + 1, output)
        }
        Bst(operand) -> {
          let val =
            get_combo_value(operand, registers) |> int.bitwise_and(0b111)
          step_loop(instructions, Registers(a:, b: val, c:), pc + 1, output)
        }
        Jnz(n) -> {
          case a {
            0 -> step_loop(instructions, registers, pc + 1, output)
            _ -> step_loop(instructions, registers, n / 2, output)
          }
        }
        Bxc -> {
          let val = int.bitwise_exclusive_or(b, c)
          step_loop(instructions, Registers(a:, b: val, c:), pc + 1, output)
        }
        Out(operand) -> {
          let val =
            get_combo_value(operand, registers) |> int.bitwise_and(0b111)
          step_loop(instructions, registers, pc + 1, [val, ..output])
        }
        Bdv(operand) -> {
          let val =
            int.to_float(a)
            |> float.divide(
              float.power(
                2.0,
                get_combo_value(operand, registers) |> int.to_float,
              )
              |> result.unwrap(0.0),
            )
            |> result.unwrap(0.0)
            |> float.truncate

          step_loop(instructions, Registers(a:, b: val, c:), pc + 1, output)
        }
        Cdv(operand) -> {
          let val =
            int.to_float(a)
            |> float.divide(
              float.power(
                2.0,
                get_combo_value(operand, registers) |> int.to_float,
              )
              |> result.unwrap(0.0),
            )
            |> result.unwrap(0.0)
            |> float.truncate

          step_loop(instructions, Registers(a:, b:, c: val), pc + 1, output)
        }
      }
    }
  }
}

fn get_combo_value(operand: Operand, registers: Registers) -> Int {
  case operand {
    Literal(n:) -> n
    Register(reg:) -> {
      case reg {
        RegA -> registers.a
        RegB -> registers.b
        RegC -> registers.c
      }
    }
  }
}

// Parsing

fn parse_input(input: String) -> Result(#(Registers, Array(Instruction)), Nil) {
  case lines.blocks(input) {
    [registers, instructions] -> {
      use registers <- result.try(parse_registers(registers))
      use instructions <- result.map(parse_instructions(instructions))
      #(registers, array.from_list(instructions))
    }
    _ -> Error(Nil)
  }
}

fn parse_registers(input: String) -> Result(Registers, Nil) {
  let assert Ok(re) =
    regexp.from_string(
      "^Register A: (\\d+) Register B: (\\d+) Register C: (\\d+)$",
    )

  case regexp.scan(re, string.replace(input, "\n", " ")) {
    [match] -> {
      case match.submatches {
        [Some(a_str), Some(b_str), Some(c_str)] -> {
          use a <- result.try(int.parse(a_str))
          use b <- result.try(int.parse(b_str))
          use c <- result.map(int.parse(c_str))
          Registers(a:, b:, c:)
        }
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_instructions(input: String) -> Result(List(Instruction), Nil) {
  case string.split(input, " ") {
    [_, instructions_str] -> {
      use instructions <- result.try(
        string.split(instructions_str, ",") |> list.try_map(int.parse),
      )
      instructions |> list.sized_chunk(2) |> list.try_map(parse_instruction)
    }
    _ -> Error(Nil)
  }
}

fn parse_instruction(input: List(Int)) -> Result(Instruction, Nil) {
  case input {
    [opcode, n] -> {
      let combo_operand = parse_combo_operand(n)
      case opcode {
        0 -> Ok(Adv(combo_operand))
        1 -> Ok(Bxl(n))
        2 -> Ok(Bst(combo_operand))
        3 -> Ok(Jnz(n))
        4 -> Ok(Bxc)
        5 -> Ok(Out(combo_operand))
        6 -> Ok(Bdv(combo_operand))
        7 -> Ok(Cdv(combo_operand))
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_combo_operand(input: Int) -> Operand {
  case input {
    4 -> Register(RegA)
    5 -> Register(RegB)
    6 -> Register(RegC)
    x -> Literal(x)
  }
}
