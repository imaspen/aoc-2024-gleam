import days/day_03
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_03.txt")

  day_03.day(PartOne, input)
  |> should.equal(Ok("161"))
}
