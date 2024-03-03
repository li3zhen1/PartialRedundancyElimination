
enum MeetOperator {
  case union
  case intersect
}

struct InOutExprSets: Equatable {
  var IN: InSets
  var OUT: OutSets

  func printTable(_ name: String) {
    print("========== \(name) ==========")
    for (k, v) in IN.sorted(by: {
      return weightOf($0.key) < weightOf($1.key)
    }) {
      print(
        "\(k.id) \(String(repeating: " ", count: 12 - k.id.count))\(v)\(String(repeating: " ", count: 12 - v.description.count))\(OUT[k]!)"
      )
    }
    print("\n")
  }
}

func iterate_forward(
  v_entry: ExprSet,
  initializeOutSet: ExprSet,
  initializeInSet: ExprSet = .empty,
  meet: MeetOperator,
  f_B: (ExprSet, CFG.Node) -> ExprSet
) -> InOutExprSets {
  var IN = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, initializeInSet) })
  var OUT = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, initializeOutSet) })
  OUT[.entry] = v_entry

  while true {
    var modified = false
    for bb in cfg.nodes {
      guard bb != .entry else { continue }
      let predOfOUT = cfg.predecessors(of: bb).map { OUT[$0]! }
      let newIN = meet == .union ? predOfOUT.union() : predOfOUT.intersect()
      if newIN != IN[bb] {
        IN[bb] = newIN
        modified = true
      }
      let newOUT = f_B(newIN, bb)
      if newOUT != OUT[bb] {
        OUT[bb] = newOUT
        modified = true
      }
    }
    if !modified {
      break
    }
  }
  OUT[.exit] = .empty
  IN[.entry] = .empty
  return InOutExprSets(IN: IN, OUT: OUT)
}

func iterate_backward(
  v_exit: ExprSet,
  initializeInSet: ExprSet,
  initializeOutSet: ExprSet = .empty,
  meet: MeetOperator,
  f_B: (ExprSet, CFG.Node) -> ExprSet
) -> InOutExprSets {
  var IN = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, initializeInSet) })
  var OUT = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, initializeOutSet) })
  IN[.exit] = v_exit

  while true {
    var modified = false
    for bb in cfg.nodes.reversed() {
      guard bb != .exit else { continue }
      let succOfIN = cfg.successors(of: bb).map { IN[$0]! }
      let newOUT = meet == .union ? succOfIN.union() : succOfIN.intersect()
      if newOUT != OUT[bb] {
        OUT[bb] = newOUT
        modified = true
      }
      let newIN = f_B(newOUT, bb)
      if newIN != IN[bb] {
        IN[bb] = newIN
        modified = true
      }
    }
    if !modified {
      break
    }
  }
  OUT[.exit] = .empty
  IN[.entry] = .empty
  return InOutExprSets(IN: IN, OUT: OUT)
}
