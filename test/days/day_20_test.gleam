import days/day_20
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_20.txt")

  day_20.day(PartOne, input)
  |> should.equal(Ok("10"))
}
