import days/day_16
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input1) = simplifile.read("./res/test/day_16.1.txt")
  let assert Ok(input2) = simplifile.read("./res/test/day_16.2.txt")

  day_16.day(PartOne, input1)
  |> should.equal(Ok("7036"))

  day_16.day(PartOne, input2)
  |> should.equal(Ok("11048"))
}
