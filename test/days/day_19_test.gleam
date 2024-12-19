import days/day_19
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_19.txt")

  day_19.day(PartOne, input)
  |> should.equal(Ok("6"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_19.txt")

  day_19.day(PartTwo, input)
  |> should.equal(Ok("16"))
}
