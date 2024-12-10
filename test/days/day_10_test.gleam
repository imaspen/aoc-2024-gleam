import days/day_10
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_10.txt")

  day_10.day(PartOne, input)
  |> should.equal(Ok("36"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_10.txt")

  day_10.day(PartTwo, input)
  |> should.equal(Ok("81"))
}
