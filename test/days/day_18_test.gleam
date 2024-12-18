import days/day_18
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_18.1.txt")

  day_18.day(PartOne, input)
  |> should.equal(Ok("22"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_18.2.txt")

  day_18.day(PartTwo, input)
  |> should.equal(Ok("6,1"))
}
