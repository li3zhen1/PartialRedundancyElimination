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

print("CFG nodes:")
cfg.nodes.forEach {
  print($0.id)
}

var e_use = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
var e_kill = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })

for i in [2, 4, 9, 13, 15, 17] {
  e_use[Node(i)] = true
}

for i in [1, 5, 11] {
  e_kill[Node(i)] = true
}

var anticipated_in = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
var anticipated_out = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })

func f_anticipated(out x: ExprSet, of bb: Node) -> ExprSet {
  return e_use[bb]!.union(x - e_kill[bb]!)
}

func iterate_anticipatable() -> Bool {
  var isStable = true
  for bb in cfg.nodes {
    if bb != CFG.entry {
      let newOut = cfg.successors(of: bb).map { anticipated_in[$0]! }.union()
      if newOut != anticipated_out[bb] {
        anticipated_out[bb] = newOut
        isStable = false
      }
    }
    if bb != CFG.entry {
      let newIn = f_anticipated(out: anticipated_out[bb]!, of: bb)
      if newIn != anticipated_in[bb] {
        anticipated_in[bb] = newIn
        isStable = false
      }
    }
  }
  return isStable
}
while !iterate_anticipatable() {}
assert(iterate_anticipatable() == true)

dump("anticipated", in: anticipated_in, out: anticipated_out)
