import days/day_01
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_01.txt")

  day_01.day(PartOne, input)
  |> should.equal(Ok("11"))
}
