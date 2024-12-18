import gleam/dict.{type Dict}

pub type Direction {
  North
  South
  East
  West
}

pub type Point {
  Point(x: Int, y: Int)
}

pub type Map(v) =
  Dict(Point, v)

pub fn new() -> Map(v) {
  dict.new()
}

pub fn insert(map: Map(v), p: Point, v: v) -> Map(v) {
  dict.insert(map, p, v)
}

pub fn move(pos: Point, dir: Direction) -> Point {
  let Point(x:, y:) = pos
  case dir {
    North -> Point(x:, y: y - 1)
    South -> Point(x:, y: y + 1)
    East -> Point(x: x + 1, y:)
    West -> Point(x: x - 1, y:)
  }
}

pub fn get_at(map: Map(v), at: Point) -> Result(v, Nil) {
  dict.get(map, at)
}

pub fn get_at_dir(map: Map(v), at: Point, dir: Direction) -> Result(v, Nil) {
  dict.get(map, move(at, dir))
}
