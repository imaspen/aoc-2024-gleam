import days/day_13
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_13.txt")

  day_13.day(PartOne, input)
  |> should.equal(Ok("480"))
}
