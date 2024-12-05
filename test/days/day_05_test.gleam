import days/day_05
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_05.txt")

  day_05.day(PartOne, input)
  |> should.equal(Ok("143"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_05.txt")

  day_05.day(PartTwo, input)
  |> should.equal(Ok("123"))
}
