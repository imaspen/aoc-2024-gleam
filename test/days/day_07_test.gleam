import days/day_07
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_07.txt")

  day_07.day(PartOne, input)
  |> should.equal(Ok("3749"))
}

pub fn part_two_test() {
  day_07.day(PartTwo, "156: 15 6")
  |> should.equal(Ok("156"))

  day_07.day(PartTwo, "156: 1 56")
  |> should.equal(Ok("156"))

  day_07.day(PartTwo, "1567: 15 67")
  |> should.equal(Ok("1567"))

  day_07.day(PartTwo, "1567: 1 567")
  |> should.equal(Ok("1567"))

  day_07.day(PartTwo, "1567: 156 7")
  |> should.equal(Ok("1567"))

  day_07.day(PartTwo, "7290: 6 8 6 15")
  |> should.equal(Ok("7290"))

  day_07.day(PartTwo, "192: 17 8 14")
  |> should.equal(Ok("192"))
}
