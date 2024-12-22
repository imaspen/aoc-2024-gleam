import days/day_22
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_22.1.txt")

  day_22.day(PartOne, input)
  |> should.equal(Ok("37327623"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_22.2.txt")

  // day_22.day(PartTwo, "123")
  // |> should.equal(Ok("23"))

  day_22.day(PartTwo, input)
  |> should.equal(Ok("23"))
}
