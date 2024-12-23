import days/part.{type Part, PartOne, PartTwo}
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import graph.{
  type Context, type Graph, type Node, type Undirected, Context, Node,
}
import utils/lines

type NetGraph =
  Graph(Undirected, String, String)

type NetNode =
  Node(String)

type NetContext =
  Context(String, String)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use graph <- result.map(
    parse_input(input) |> result.replace_error("Couldn't parse input."),
  )

  graph.fold(graph, set.new(), fn(a, b) { search(graph, a, b) })
  |> set.filter(fn(set) {
    set
    |> set.to_list
    |> list.any(fn(node) {
      let Node(_, label) = node
      string.starts_with(label, "t")
    })
  })
  |> set.size
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn search(
  graph: NetGraph,
  acc: Set(Set(NetNode)),
  curr: NetContext,
) -> Set(Set(NetNode)) {
  let Context(_, node, neighbors) = curr
  list.combination_pairs(dict.keys(neighbors))
  |> list.filter(fn(key) {
    graph.has_edge(graph, pair.first(key), pair.second(key))
  })
  |> list.fold(acc, fn(set, pair) {
    let #(a_id, b_id) = pair

    let assert Ok(Context(_, a, _)) = graph.get_context(graph, a_id)
    let assert Ok(Context(_, b, _)) = graph.get_context(graph, b_id)

    set.insert(set, set.from_list([node, a, b]))
  })
}

fn parse_input(input: String) {
  lines.lines(input)
  |> list.try_fold(graph.new(), parse_line)
}

fn parse_line(graph: NetGraph, input: String) -> Result(NetGraph, Nil) {
  case string.split(input, "-") {
    [a_str, b_str] -> {
      use a <- result.try(parse_id(a_str))
      use b <- result.map(parse_id(b_str))

      let graph = case
        graph.has_node(graph, a.id),
        graph.has_node(graph, b.id)
      {
        True, True -> graph
        False, False -> graph |> graph.insert_node(a) |> graph.insert_node(b)
        False, True -> graph.insert_node(graph, a)
        True, False -> graph.insert_node(graph, b)
      }

      graph.insert_undirected_edge(graph, input, a.id, b.id)
    }
    _ -> Error(Nil)
  }
}

fn parse_id(input: String) -> Result(NetNode, Nil) {
  let codepoints =
    string.to_utf_codepoints(input)
    |> list.map(string.utf_codepoint_to_int)

  case codepoints {
    [a, b] -> {
      Ok(Node(int.bitwise_shift_left(a, 7) + b, input))
    }
    _ -> Error(Nil)
  }
}
