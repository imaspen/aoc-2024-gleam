import days/day_07
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_07.txt")

  day_07.day(PartOne, input)
  |> should.equal(Ok("3749"))
}
