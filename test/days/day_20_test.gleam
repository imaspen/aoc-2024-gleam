import days/day_20
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_20.1.txt")

  day_20.day(PartOne, input)
  |> should.equal(Ok("10"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_20.2.txt")

  day_20.day(PartTwo, input)
  |> should.equal(Ok("285"))
}
