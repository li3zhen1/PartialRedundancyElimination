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

  static prefix func ! (_ value: ExprSet) -> ExprSet {
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

    var graphvizID: String {
      return "node" + id.replacing("→", with: "_")
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

extension CFG {
  func dumpGraphviz() -> String {
    var result = ""
    result += ("digraph G {") + "\n"
    for node in nodes {
      if node.id.contains("→") {
        result +=
          ("  \(node.graphvizID) [label=\"Node \(node.id)\" shape=rect style=dashed];") + "\n"
      } else {
        if e_use[node] != .empty {
          result += ("  \(node.graphvizID) [label=\"Node \(node.id)\n=a+b\" shape=rect];") + "\n"
        } else {
          result += ("  \(node.graphvizID) [label=\"Node \(node.id)\" shape=rect];") + "\n"
        }
      }
    }
    for edge in edges {

      result += ("  \(edge.from.graphvizID) -> \(edge.to.graphvizID);") + "\n"
    }
    result += ("}") + "\n"
    return result
  }

  func dumpTypst() -> String {
    let insts = getInsts()
    let labels = nodes.map { bb in
      var ti = [String]()
      if step8b[bb]!.hasAplusB {
        ti.append("t = a + b")
      }

      if var inst = insts[bb]! {
        if step8c[bb]!.hasAplusB {
          inst.replace("a + b", with: "t")
        }
        let spl = inst.split(separator: "\n").map { String($0) }
        ti.append(contentsOf: spl)
      }

      return (
        bb.graphvizID,
        getLabel(bb: bb, insts: ti)
      )
    }

    var typstDescription = """
          #raw-render(
        ```
        \(dumpGraphviz())
        ```,
        labels: (:
          \(
      labels.map { (k, v) in
        return "\(k): \(v)"
      }.joined(separator: ",\n")
          )
        ),
      )
      """
    return typstDescription

  }

}

func getLabel(bb: CFG.Node, insts: [String] = []) -> String {
  var ops = ""
  if step8b[bb]!.hasAplusB {
    ops += "#text(fill:blue)[insert $t = a+b$]"
  }
  if step8c[bb]!.hasAplusB {
    if ops.count > 0 {
      ops += ", "
    }
    ops += "#text(fill:red)[replace $a+b$ with $t$]"
  }
  var lbl = """
    [\(
      insts.isEmpty ? "*\(bb.id)* \\ " : "#place()[*\(bb.id)*]"
      ) #box(align(center, [\(insts.joined(separator: " \\ "))
      #grid(
      columns: (\(String(repeating: "cell_width,", count: 7))),
      row-gutter: r_gutter,
    )
    """
  lbl += "[\(e_use[bb]!)]"
  lbl += "[ \(anticipated.IN[bb]!) ]"
  lbl += "[ \(available.IN[bb]!) ]"
  lbl += "[ \(earliest[bb]!) ]"
  lbl += "[ \(postponable.IN[bb]!) ]"
  lbl += "[ \(latest[bb]!) ]"
  lbl += "[ \(used.IN[bb]!) ]"
  // lbl += "[\(step8b[bb]!.hasAplusB ? "Yes" : "")]"

  lbl += "[ \(e_kill[bb]!) ]"
  lbl += "[ \(anticipated.OUT[bb]!) ]"
  lbl += "[ \(available.OUT[bb]!) ]"
  lbl += "[ ]"
  lbl += "[ \(postponable.OUT[bb]!) ]"
  lbl += "[ ]"
  lbl += "[ \(used.OUT[bb]!) ]"
  // lbl += "[\(step8c[bb]!.hasAplusB ? "Yes" : "")]"
  return lbl + "]))]"
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
