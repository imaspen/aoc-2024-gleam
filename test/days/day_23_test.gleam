import days/day_23
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_23.txt")

  day_23.day(PartOne, input)
  |> should.equal(Ok("7"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_23.txt")

  day_23.day(PartTwo, input)
  |> should.equal(Ok("co,de,ka,ta"))
}
