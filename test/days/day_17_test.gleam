import days/day_17
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input) = simplifile.read("./res/test/day_17.txt")

  day_17.day(PartOne, input)
  |> should.equal(Ok("4,6,3,5,6,3,5,2,1,0"))
}
