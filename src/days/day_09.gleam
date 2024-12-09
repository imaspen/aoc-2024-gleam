import days/part.{type Part, PartOne, PartTwo}
import gleam/deque.{type Deque}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import utils/lines

type FileId =
  Int

type File {
  File(id: FileId, length: Int)
}

type Free {
  Free(id: FileId, files: Deque(File), length: Int)
}

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use digits <- result.map(input |> lines.digits)

  digits
  |> yielder.from_list
  |> yielder.index
  |> yielder.sized_chunk(2)
  |> yielder.fold(#(deque.new(), deque.new()), parse_chunk)
  |> move_files
  |> fn(acc) {
    #(
      deque.to_list(acc.0) |> list.sort(fn(a, b) { int.compare(a.id, b.id) }),
      deque.to_list(acc.1) |> list.sort(fn(a, b) { int.compare(a.id, b.id) }),
    )
  }
  |> fn(acc) { flatten_files_and_frees(acc.0, acc.1) }
  |> calculate_checksum
  |> string.inspect
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn parse_chunk(
  accs: #(Deque(File), Deque(Free)),
  input: List(#(Int, Int)),
) -> #(Deque(File), Deque(Free)) {
  let #(files, frees) = accs
  case input {
    [file_input, free_input, ..] -> #(
      deque.push_back(files, parse_file(file_input)),
      deque.push_back(frees, parse_free(free_input)),
    )
    [file_input] -> #(deque.push_back(files, parse_file(file_input)), frees)
    _ -> accs
  }
}

fn parse_file(input: #(Int, Int)) -> File {
  let #(length, index) = input

  File(id: index / 2, length:)
}

fn parse_free(input: #(Int, Int)) -> Free {
  let #(length, index) = input

  Free(id: { index - 1 } / 2, length:, files: deque.new())
}

fn move_files(input: #(Deque(File), Deque(Free))) -> #(Deque(File), Deque(Free)) {
  case deque.pop_back(input.0), deque.pop_front(input.1) {
    Ok(#(file, _)), Ok(#(free, _)) if file.id <= free.id -> {
      input
    }
    Ok(#(file, files)), Ok(#(free, frees)) -> {
      case free.length {
        0 -> move_files(#(input.0, deque.push_back(frees, free)))
        _ -> {
          case file.length {
            0 -> move_files(#(files, input.1))
            _ -> {
              case file.length - free.length {
                // whole file fits in free space
                l if l <= 0 ->
                  move_files(#(
                    files,
                    deque.push_front(
                      frees,
                      Free(
                        id: free.id,
                        files: deque.push_back(free.files, file),
                        length: free.length - file.length,
                      ),
                    ),
                  ))
                l ->
                  move_files(#(
                    deque.push_back(files, File(id: file.id, length: l)),
                    deque.push_back(
                      frees,
                      Free(
                        id: free.id,
                        files: deque.push_back(
                          free.files,
                          File(id: file.id, length: free.length),
                        ),
                        length: 0,
                      ),
                    ),
                  ))
              }
            }
          }
        }
      }
    }
    _, _ -> input
  }
}

fn flatten_files_and_frees(files: List(File), frees: List(Free)) -> List(File) {
  flatten_files_and_frees_loop(files, frees, deque.new())
}

fn flatten_files_and_frees_loop(
  files: List(File),
  frees: List(Free),
  acc: Deque(File),
) -> List(File) {
  case files, frees {
    [file, ..rest_files], [free, ..rest_frees] ->
      flatten_files_and_frees_loop(
        rest_files,
        rest_frees,
        acc |> deque.push_back(file) |> push_all_back(free.files),
      )
    [file, ..rest_files], [] ->
      flatten_files_and_frees_loop(
        rest_files,
        frees,
        deque.push_back(acc, file),
      )
    _, _ -> deque.to_list(acc)
  }
}

fn push_all_back(files: Deque(File), to_push: Deque(File)) -> Deque(File) {
  case deque.pop_front(to_push) {
    Error(_) -> files
    Ok(#(file, rest)) -> push_all_back(deque.push_back(files, file), rest)
  }
}

fn calculate_checksum(files: List(File)) -> Int {
  calculate_checksum_loop(files, 0, 0)
}

fn calculate_checksum_loop(files: List(File), pos: Int, acc: Int) -> Int {
  case files {
    [] -> acc
    [file, ..rest] -> {
      case file.length {
        0 -> calculate_checksum_loop(rest, pos, acc)
        _ ->
          calculate_checksum_loop(
            [File(id: file.id, length: file.length - 1), ..rest],
            pos + 1,
            acc + pos * file.id,
          )
      }
    }
  }
}
