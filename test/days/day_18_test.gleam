import days/day_18
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_18.1.txt")

  day_18.day(PartOne, input)
  |> should.equal(Ok("22"))
}
