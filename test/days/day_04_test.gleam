import days/day_04
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_04.txt")

  day_04.day(PartOne, input)
  |> should.equal(Ok("18"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_04.txt")

  day_04.day(PartTwo, input)
  |> should.equal(Ok("9"))
}
