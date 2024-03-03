func getInsts() -> [Node: String?] {
  var insts = Dictionary(uniqueKeysWithValues: cfg.nodes.map { ($0, String?(nil)) })

  func setInst(_ bb: Node, _ inst: String) {
    insts[bb] = inst
  }
  setInst(1, "a := \n b :=")
  setInst(5, "a :=")
  setInst(11, "a :=")

  setInst(2, "c := a + b")
  setInst(4, "d := a + b")
  setInst(9, "c := a + b")
  setInst(13, "c := a + b")
  setInst(15, "c := a + b")
  setInst(17, "c := a + b")
  return insts
}
