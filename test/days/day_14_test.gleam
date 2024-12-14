import days/day_14
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_14.txt")

  day_14.day(PartOne, input)
  |> should.equal(Ok("12"))
}
