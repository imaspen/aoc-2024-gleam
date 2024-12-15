import days/day_15
import days/part.{PartOne, PartTwo}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input1) = simplifile.read("./res/test/day_15.1.txt")
  let assert Ok(input2) = simplifile.read("./res/test/day_15.2.txt")

  day_15.day(PartOne, input1)
  |> should.equal(Ok("2028"))

  day_15.day(PartOne, input2)
  |> should.equal(Ok("10092"))
}

pub fn part_two_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_15.2.txt")

  day_15.day(PartTwo, input)
  |> should.equal(Ok("9021"))
}
