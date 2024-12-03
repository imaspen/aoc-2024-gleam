import days/day_03
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_03_1.txt")

  day_03.day(PartOne, input)
  |> should.equal(Ok("161"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_03_2.txt")

  day_03.day(PartTwo, input)
  |> should.equal(Ok("48"))
}
