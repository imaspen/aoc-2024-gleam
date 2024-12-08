import days/day_08
import days/part.{PartOne}
import gleeunit/should
import simplifile

pub fn part_one_test() {
  let assert Ok(input_1) = simplifile.read("./res/test/day_08.1.txt")
  let assert Ok(input_2) = simplifile.read("./res/test/day_08.2.txt")
  let assert Ok(input_3) = simplifile.read("./res/test/day_08.3.txt")

  day_08.day(PartOne, input_1)
  |> should.equal(Ok("2"))

  day_08.day(PartOne, input_2)
  |> should.equal(Ok("4"))

  day_08.day(PartOne, input_3)
  |> should.equal(Ok("14"))
}
