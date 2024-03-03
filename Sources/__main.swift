// typealias Node = CFG.Node
// typealias Edge = CFG.Edge

// let edges: [CFG.Edge] = [
//   [CFG.entry, 1],
//   [1, 2],
//   [1, 3],
//   [2, 4],
//   [3, 4],
//   [4, 5],
//   [5, 6],
//   [6, 8],
//   [8, 9],
//   [9, 8],
//   [8, 12],
//   [12, CFG.exit],
//   [12, 17],
//   [17, CFG.exit],
//   [5, 7],
//   [7, 10],
//   [10, 13],
//   [13, 14],
//   [14, 13],
//   [13, 16],
//   [16, 17],
//   [7, 11],
//   [11, 15],
//   [15, 17],
// ]

// var cfg = CFG(edges: edges)

// assert(cfg.nodes.count == 19)
// assert(cfg.edges.count == 24)

// var addedCount = 0

// // partial redundancy elimination

// // 1. Insert an empty block along all edges entering a block with more than
// // one predecessor.
// for to in cfg.nodes {
//   let preds = cfg.predecessors(of: to)
//   if preds.count > 1 {
//     for from in preds {
//       let newBlock = CFG.Node(id: "\(from.id)→\(to.id)")
//       cfg.edges.append([from, newBlock])
//       cfg.edges.append([newBlock, to])
//       cfg.edges.removeAll { $0 == [from, to] }
//       cfg.nodes.append(newBlock)
//       addedCount += 1
//     }
//   }
// }

// cfg.nodes.sort { $0.id < $1.id }
// assert(addedCount == 11)

// // print("CFG nodes:")
// // cfg.nodes.forEach {
// //   print($0.id)
// // }

// var e_use = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
// var e_kill = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })

// for i in [2, 4, 9, 13, 15, 17] {
//   e_use[Node(i)] = true
// }

// for i in [1, 5, 11] {
//   e_kill[Node(i)] = true
// }

// var anticipated_in = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.U) })
// var anticipated_out = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })

// func f_anticipated(out x: ExprSet, of bb: Node) -> ExprSet {
//   return e_use[bb]!.union(x - e_kill[bb]!)
// }

// func iterate_anticipatable() -> Bool {
//   var isStable = true
//   for bb in cfg.nodes {
//     if bb != CFG.exit {
//       let newOut = cfg.successors(of: bb).map { anticipated_in[$0]! }.intersect()
//       if newOut != anticipated_out[bb] {
//         anticipated_out[bb] = newOut
//         isStable = false
//       }
//     }
//     if bb != CFG.entry {
//       let newIn = f_anticipated(out: anticipated_out[bb]!, of: bb)
//       if newIn != anticipated_in[bb] {
//         anticipated_in[bb] = newIn
//         isStable = false
//       }
//     }
//   }
//   return isStable
// }
// while !iterate_anticipatable() {}

// assert(iterate_anticipatable() == true)

// dump("anticipated", in: anticipated_in, out: anticipated_out)

// let anticipated = interate_backward(
//   v_exit: .empty, initializeInSet: .U, initializeOutSet: .empty, meet: .intersect,
//   f_B: f_anticipated)

// var available_in = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
// var available_out = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.U) })

// func f_available(`in` x: ExprSet, of bb: Node) -> ExprSet {
//   return (anticipated_in[bb]!.union(x) - e_kill[bb]!)
// }

// func iterate_available() -> Bool {
//   var isStable = true
//   for bb in cfg.nodes {
//     if bb != CFG.entry {
//       let newIn = cfg.predecessors(of: bb).map { available_out[$0]! }.intersect()
//       if newIn != available_in[bb] {
//         available_in[bb] = newIn
//         isStable = false
//       }
//     }
//     if bb != CFG.exit {
//       let newOut = f_available(in: available_in[bb]!, of: bb)
//       if newOut != available_out[bb] {
//         available_out[bb] = newOut
//         isStable = false
//       }
//     }
//   }
//   return isStable
// }

// while !iterate_available() {}

// assert(iterate_available() == true)

// dump("available", in: available_in, out: available_out)

// var earliest = Dictionary(
//   uniqueKeysWithValues: cfg.nodes.map {
//     return ($0, anticipated_in[$0]! - available_in[$0]!)
//   })

// dump("earliest", set: earliest)

// var postponable_in = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
// var postponable_out = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.U) })

// func f_postponable(in x: ExprSet, of bb: Node) -> ExprSet {
//   return (earliest[bb]!.union(x) - e_use[bb]!)
// }

// func iterate_postponable() -> Bool {
//   var isStable = true
//   for bb in cfg.nodes {
//     // forwards,
//     if bb != .entry {
//       let newIn = cfg.predecessors(of: bb).map { postponable_out[$0]! }.intersect()
//       if newIn != postponable_in[bb] {
//         postponable_in[bb] = newIn
//         isStable = false
//       }
//     }
//     if bb != .exit {
//       let newOut = f_postponable(in: postponable_in[bb]!, of: bb)
//       if newOut != postponable_out[bb] {
//         postponable_out[bb] = newOut
//         isStable = false
//       }
//     }
//   }
//   return isStable
// }

// while !iterate_postponable() {}

// assert(iterate_postponable() == true)

// dump("postponable", in: postponable_in, out: postponable_out)

// func getLatest(_ bb: Node) -> ExprSet {
//   let lhs = (earliest[bb]!.union(postponable_in[bb]!))
//   let rhs_rhs = cfg.successors(of: bb).map { s in
//     return earliest[s]!.union(postponable_in[s]!)
//   }.intersect()
//   let rhs =
//     (e_use[bb]!.union(
//       ExprSet.neg(rhs_rhs)
//     ))
//   return lhs.intersect(rhs)
// }

// var latest = Dictionary(
//   uniqueKeysWithValues: cfg.nodes.map {
//     return ($0, getLatest($0))
//   })

// dump("latest", set: latest)

// var used_in = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })
// var used_out = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, ExprSet.empty) })

// func f_used(out x: ExprSet, of bb: Node) -> ExprSet {
//   return (e_use[bb]!.union(x)) - latest[bb]!
// }

// func iterate_used() -> Bool {
//   var isStable = true
//   for bb in cfg.nodes {
//     // backwards
//     if bb != .exit {
//       let newOut = cfg.successors(of: bb).map { used_in[$0]! }.union()
//       if newOut != used_out[bb] {
//         used_out[bb] = newOut
//         isStable = false
//       }
//     }
//     if bb != .entry {
//       let newIn = f_used(out: used_out[bb]!, of: bb)
//       if newIn != used_in[bb] {
//         used_in[bb] = newIn
//         isStable = false
//       }
//     }
//   }
//   return isStable
// }

// while !iterate_used() {}

// assert(iterate_used() == true)

// dump("used", in: used_in, out: used_out)
