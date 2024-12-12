import days/day_12
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_12.txt")

  day_12.day(PartOne, input)
  |> should.equal(Ok("1930"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_12.txt")

  day_12.day(PartTwo, input)
  |> should.equal(Ok("1206"))
}
