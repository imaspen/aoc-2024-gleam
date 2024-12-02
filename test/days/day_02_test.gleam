import days/day_02
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_02.txt")

  day_02.day(PartOne, input)
  |> should.equal(Ok("2"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_02.txt")
}
