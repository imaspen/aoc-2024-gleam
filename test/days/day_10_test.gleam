import days/day_10
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_10.txt")

  day_10.day(PartOne, input)
  |> should.equal(Ok("36"))
}
