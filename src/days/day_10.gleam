import days/part.{type Part, PartOne, PartTwo}
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/yielder
import glearray.{type Array} as array
import graph.{type Directed, type Graph, type Node, Node}
import utils/lines

type Position {
  Position(x: Int, y: Int)
}

type Point {
  Point(position: Position, height: Int)
}

type MapGraph =
  Graph(Directed, Point, Nil)

pub fn day(part: Part, input: String) -> Result(String, String) {
  case part {
    PartOne -> part_1(input)
    PartTwo -> part_2(input)
  }
}

fn part_1(input: String) -> Result(String, String) {
  use height_list <- result.map(
    input |> lines.lines |> list.try_map(lines.digits),
  )

  let point_array = height_list_to_point_arrays(height_list)
  let nodes = point_array |> array.to_list |> list.flat_map(array.to_list)
  let trailheads = get_trailheads(nodes)
  let map_graph = generate_graph(point_array, nodes)

  list.map(trailheads, fn(node) {
    dfs(map_graph, node.id, set.new())
    |> set.to_list
    |> list.count(is_node_target(map_graph, _))
  })
  |> int.sum
  |> int.to_string
}

fn part_2(input: String) -> Result(String, String) {
  todo
}

fn height_list_to_point_arrays(
  list_map: List(List(Int)),
) -> Array(Array(Node(Point))) {
  list_map
  |> yielder.from_list
  |> yielder.index
  |> yielder.map(fn(r) {
    let #(row, y) = r
    row
    |> yielder.from_list
    |> yielder.index
    |> yielder.map(fn(c) {
      let #(cell, x) = c
      let position = Position(x, y)
      Node(position_to_id(position), Point(position, cell))
    })
    |> yielder.to_list
    |> array.from_list
  })
  |> yielder.to_list
  |> array.from_list
}

fn position_to_id(position: Position) -> Int {
  position.y * 100 + position.x
}

fn generate_graph(
  point_array: Array(Array(Node(Point))),
  nodes: List(Node(Point)),
) -> MapGraph {
  let graph_with_nodes =
    list.fold(nodes, graph.new(), fn(map_graph, node) {
      map_graph |> graph.insert_node(node)
    })

  list.fold(nodes, graph_with_nodes, fn(g, node) {
    node
    |> get_neighbors(point_array)
    |> list.fold(g, fn(map_graph, neighbor) {
      map_graph
      |> graph.insert_directed_edge(Nil, from: node.id, to: neighbor.id)
    })
  })
}

fn get_neighbors(
  node: Node(Point),
  point_array: Array(Array(Node(Point))),
) -> List(Node(Point)) {
  let Node(id: _, value: Point(height:, position: Position(x, y))) = node
  [
    Position(x + 1, y),
    Position(x - 1, y),
    Position(x, y + 1),
    Position(x, y - 1),
  ]
  |> list.filter_map(fn(pos) {
    let Position(neighbor_x, neighbor_y) = pos

    use row <- result.try(array.get(point_array, neighbor_y))
    use neighbor <- result.try(array.get(row, neighbor_x))

    case neighbor.value.height - height {
      1 -> Ok(neighbor)
      _ -> Error(Nil)
    }
  })
}

fn get_trailheads(nodes: List(Node(Point))) -> List(Node(Point)) {
  list.filter(nodes, fn(node) { node.value.height == 0 })
}

fn dfs(map_graph: MapGraph, node: Int, discovered: Set(Int)) -> Set(Int) {
  graph.get_context(map_graph, node)
  |> result.map(fn(context) { context.outgoing |> dict.keys })
  |> result.unwrap([])
  |> list.filter(fn(neighbor) { !set.contains(discovered, neighbor) })
  |> list.fold(set.insert(discovered, node), fn(d, neighbor) {
    dfs(map_graph, neighbor, d)
  })
}

fn is_node_target(map_graph: MapGraph, id: Int) -> Bool {
  case graph.get_context(map_graph, id) {
    Error(_) -> False
    Ok(graph.Context(_, node, _)) -> node.value.height == 9
  }
}
