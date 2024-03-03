typealias Node = CFG.Node
typealias Edge = CFG.Edge

let edges: [CFG.Edge] = [
  [CFG.entry, 1],
  [1, 2],
  [1, 3],
  [2, 4],
  [3, 4],
  [4, 5],
  [5, 6],
  [6, 8],
  [8, 9],
  [9, 8],
  [8, 12],
  [12, CFG.exit],
  [12, 17],
  [17, CFG.exit],
  [5, 7],
  [7, 10],
  [10, 13],
  [13, 14],
  [14, 13],
  [13, 16],
  [16, 17],
  [7, 11],
  [11, 15],
  [15, 17],
]

var cfg = CFG(edges: edges)

assert(cfg.nodes.count == 19)
assert(cfg.edges.count == 24)

var addedCount = 0

// partial redundancy elimination

// 1. Insert an empty block along all edges entering a block with more than
// one predecessor.
for to in cfg.nodes {
  let preds = cfg.predecessors(of: to)
  if preds.count > 1 {
    for from in preds {
      let newBlock = CFG.Node(id: "\(from.id)→\(to.id)")
      cfg.edges.append([from, newBlock])
      cfg.edges.append([newBlock, to])
      cfg.edges.removeAll { $0 == [from, to] }
      cfg.nodes.append(newBlock)
      addedCount += 1
    }
  }
}

cfg.nodes.sort { $0.id < $1.id }
assert(addedCount == 11)
assert(cfg.edges.count == 35)


var e_use = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
var e_kill = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })

for i in [2, 4, 9, 13, 15, 17] {
  e_use[Node(i)] = true
}

for i in [1, 5, 11] {
  e_kill[Node(i)] = true
}

func f_anticipated(OUT x: ExprSet, of bb: Node) -> ExprSet {
  return e_use[bb]!.union(x - e_kill[bb]!)
}

let anticipated = iterate_backward(
  v_exit: .empty,
  initializeInSet: .U,
  meet: .intersect,
  f_B: f_anticipated)

func f_available(IN x: ExprSet, of bb: Node) -> ExprSet {
  return (anticipated.IN[bb]!.union(x)) - e_kill[bb]!
}

let available = iterate_forward(
  v_entry: .empty,
  initializeOutSet: .U,
  meet: .intersect,
  f_B: f_available
)

available.printTable("available")

let earliest = Dictionary(
  uniqueKeysWithValues: cfg.nodes.map {
    return ($0, anticipated.IN[$0]! - available.IN[$0]!)
  })

dump("ealiest", set: earliest)

func f_postponable(IN x: ExprSet, of bb: Node) -> ExprSet {
  return (earliest[bb]!.union(x) - e_use[bb]!)
}

let postponable = iterate_forward(
  v_entry: .empty,
  initializeOutSet: .U,
  meet: .intersect,
  f_B: f_postponable)

func getLatest(_ bb: Node) -> ExprSet {
  let lhs = (earliest[bb]!.union(postponable.IN[bb]!))
  let rhs_rhs = cfg.successors(of: bb).map { s in
    return earliest[s]!.union(postponable.IN[s]!)
  }.intersect()
  let rhs =
    (e_use[bb]!.union(
      !(rhs_rhs)
    ))
  return lhs.intersect(rhs)
}

var latest = Dictionary(
  uniqueKeysWithValues: cfg.nodes.map {
    return ($0, getLatest($0))
  })

dump("latest", set: latest)

func f_used(out x: ExprSet, of bb: Node) -> ExprSet {
  return (e_use[bb]!.union(x)) - latest[bb]!
}

let used = iterate_backward(
  v_exit: .empty,
  initializeInSet: .empty,
  meet: .union,
  f_B: f_used)


used.printTable("used")

let step8b = Dictionary(
  uniqueKeysWithValues: cfg.nodes.map {
    return ($0, latest[$0]!.intersect(used.OUT[$0]!))
  })

dump("step8b", set: step8b)

let step8c = Dictionary(
  uniqueKeysWithValues: cfg.nodes.map { bb in
    return (
      bb,
      e_use[bb]!.intersect(
        (!(latest[bb]!)).union(used.OUT[bb]!)
      )
    )
  })

dump("step8c", set: step8c)
