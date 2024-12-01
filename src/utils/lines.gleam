import gleam/string

pub fn lines(input: String) -> List(String) {
  string.split(input, "\n")
}
