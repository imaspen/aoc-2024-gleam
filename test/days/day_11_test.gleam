import days/day_11
import days/part.{PartOne}
import gleeunit/should

pub fn part_one_test() {
  day_11.day(PartOne, "125 17")
  |> should.equal(Ok("55312"))
}
