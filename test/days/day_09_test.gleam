import days/day_09
import days/part.{PartOne, PartTwo}
import gleeunit/should

pub fn part_one_test() {
  day_09.day(PartOne, "2333133121414131402")
  |> should.equal(Ok("1928"))
}

pub fn part_two_test() {
  day_09.day(PartTwo, "2333133121414131402")
  |> should.equal(Ok("2858"))
}
