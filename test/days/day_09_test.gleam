import days/day_09
import days/part.{PartOne}
import gleeunit/should

pub fn part_one_test() {
  day_09.day(PartOne, "2333133121414131402")
  |> should.equal(Ok("1928"))
}
