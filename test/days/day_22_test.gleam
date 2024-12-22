import days/day_22
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_22.txt")

  day_22.day(PartOne, input)
  |> should.equal(Ok("37327623"))
}
