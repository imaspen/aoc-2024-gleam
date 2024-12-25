import days/day_25
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_25.txt")

  day_25.day(PartOne, input)
  |> should.equal(Ok("3"))
}
