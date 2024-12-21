import days/day_21
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_21.txt")

  day_21.day(PartOne, input)
  |> should.equal(Ok("126384"))
}
