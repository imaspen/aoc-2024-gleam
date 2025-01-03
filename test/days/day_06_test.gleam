import days/day_06
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_06.txt")

  day_06.day(PartOne, input)
  |> should.equal(Ok("41"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_06.txt")

  day_06.day(PartTwo, input)
  |> should.equal(Ok("6"))
}
