struct ExprSet: Equatable {
  var hasAplusB: Bool

  static let empty = ExprSet(hasAplusB: false)
  static let U = ExprSet(hasAplusB: true)

  init(hasAplusB: Bool) {
    self.hasAplusB = hasAplusB
  }

  init(_ hasAplusB: Bool) {
    self.hasAplusB = hasAplusB
  }
  
}

extension ExprSet: CustomStringConvertible {
  var description: String {
    return hasAplusB ? "{a+b}" : "∅"
  }
}

extension Array where Element == ExprSet {
  func union() -> ExprSet {
    return ExprSet(hasAplusB: self.contains { $0.hasAplusB })
  }

  func intersect() -> ExprSet {
    return ExprSet(hasAplusB: self.allSatisfy { $0.hasAplusB })
  }
}

extension ExprSet {
  static func - (lhs: ExprSet, rhs: ExprSet) -> ExprSet {
    return ExprSet(hasAplusB: lhs.hasAplusB && !rhs.hasAplusB)
  }

  func intersect(_ other: ExprSet) -> ExprSet {
    return ExprSet(hasAplusB: self.hasAplusB && other.hasAplusB)
  }

  func union(_ other: ExprSet) -> ExprSet {
    return ExprSet(hasAplusB: self.hasAplusB || other.hasAplusB)
  }

  static func neg(_ set: ExprSet) -> ExprSet {
    return ExprSet(hasAplusB: !set.hasAplusB)
  }

  static prefix func !(_ value: ExprSet) -> ExprSet {
    return ExprSet(hasAplusB: !value.hasAplusB)
  }
}

extension ExprSet: ExpressibleByBooleanLiteral {
  init(booleanLiteral value: Bool) {
    self.hasAplusB = value
  }
}

struct CFG {
  struct Node: Equatable, Hashable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral,
    Identifiable
  {
    var id: String

    init(integerLiteral value: Int) {
      self.id = "\(value)"
    }

    init(stringLiteral value: String) {
      self.id = value
    }

    init(id: String) {
      self.id = id
    }

    init(_ id: Int) {
      self.id = "\(id)"
    }

    static var entry: Node { return CFG.entry }
    static var exit: Node { return CFG.exit }
  }

  struct Edge: ExpressibleByArrayLiteral, Equatable {
    init(arrayLiteral elements: Node...) {
      from = elements[0]
      to = elements[1]
    }

    var from: Node
    var to: Node

  }

  var nodes: [Node]
  var edges: [Edge]

  func successors(of node: Node) -> [Node] {
    return edges.filter { $0.from == node }.map { $0.to }
  }

  func predecessors(of node: Node) -> [Node] {
    return edges.filter { $0.to == node }.map { $0.from }
  }

  static let entry: Node = "entry"
  static let exit: Node = "exit"

  init(edges: [Edge]) {
    self.edges = edges
    self.nodes = Array(Set(edges.flatMap { [$0.from, $0.to] })).sorted(by: { $0.id < $1.id })
  }
}

typealias InSets = [CFG.Node: ExprSet]
typealias OutSets = [CFG.Node: ExprSet]

func weightOf(_ n: CFG.Node) -> Double {
  if n.id == "entry" {
    return -1
  }
  if n.id == "exit" {
    return 99999
  }
  if n.id.contains("→") {
    return Double(n.id.split(separator: "→")[0])! + 0.5
  }
  return Double(n.id)!
}
func dump(_ name: String, in: InSets, out: OutSets) {
  print("========== \(name) ==========")
  for (k, v) in `in`.sorted(by: {
    return weightOf($0.key) < weightOf($1.key)
  }) {
    print(
      "\(k.id) \(String(repeating: " ", count: 12 - k.id.count))\(v)\(String(repeating: " ", count: 12 - v.description.count))\(out[k]!)"
    )
  }
  print("\n")
}


func dump(_ name: String, set: InSets) {
  print("========== \(name) ==========")
  for (k, v) in set.sorted(by: {
    return weightOf($0.key) < weightOf($1.key)
  }) {
    print(
      "\(k.id) \(String(repeating: " ", count: 12 - k.id.count))\(v)\(String(repeating: " ", count: 12 - v.description.count))"
    )
  }
  print("\n")
}
