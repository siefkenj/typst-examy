#import "../types.typ": PARENTS, e
#import "../content_to_array.typ": *

/// Take a flat list of questions/parts/subparts, and add appropriate data into the `children` array of each.
/// A typical before data structure looks like:
/// ```
/// (
///  (
///    level: "question",
///    id: 0,
///    children: (),
///    info: (
///      points: 1.0,
///      intent: none,
///    ),
///  ),
///  (
///    level: "part",
///    id: 1,
///    children: (),
///    info: (
///      points: 2.0,
///      intent: none,
///    ),
///  ),
///  (
///    level: "part",
///    id: 2,
///    children: (),
///    info: (
///      points: 4.0,
///      intent: none,
///    ),
///  ),
///  (
///    level: "question",
///    id: 3,
///    children: (),
///    info: (
///      points: none,
///      intent: none,
///    ),
///  ),
///  (
///    level: "question",
///    id: 4,
///    children: (),
///    info: (
///      points: 3.0,
///      intent: none,
///    ),
///  ),
///)
/// ```
#let question_list_to_tree(l) = {
  let active_division = (
    "question": none,
    "part": none,
    "subpart": none,
  )
  let ret = ()
  for item in l {
    let level = item.level
    active_division.insert(level, item.id)
    let parent = PARENTS.at(level, default: none)
    if parent != none {
      let parent_id = active_division.at(parent)
      if parent_id != none {
        ret.at(parent_id).children.push(item.id)
      }
    }
    ret.push(item)
  }
  ret
}

/// Given a list of question infos (with children included), compute the total number of points of the item and all sub-items.
#let compute_total_points(l, id) = {
  let item = l.at(id)
  let total = 0
  if item.info.points != none and item.info.intent == none {
    total += item.info.points
  }
  for child_id in item.children {
    total += compute_total_points(l, child_id)
  }
  total
}

/// Given a list of question infos (with children included), compute the total number of points of the item and all sub-items.
#let compute_total_bonus_points(l, id) = {
  let item = l.at(id)
  let total = 0
  if item.info.points != none and item.info.intent == "bonus" {
    total += item.info.points
  }
  for child_id in item.children {
    total += compute_total_bonus_points(l, child_id)
  }
  if total == 0 {
    none
  } else {
    total
  }
}

/// Given a question infos list, compute its children and the point value of each item.
#let augment_question_list(l) = {
  let tree = question_list_to_tree(l)
  tree.map(item => {
    item.insert("total_points", compute_total_points(tree, item.id))
    item.insert("total_bonus_points", compute_total_bonus_points(tree, item.id))
    item
  })
}

/// Determine if `it` is content that consists only of whitespace.
#let is_whitespace_content(it) = {
  if type(it) == text {
    return it.string.trim() == ""
  }
  if type(it) == content {
    if ([ ].func(), parbreak().func()).contains(it.func()) {
      return true
    }
    if it.has("children") {
      return it.at("children").all(child => is_whitespace_content(child))
    }
  }
  false
}

#{
  assert(is_whitespace_content(parbreak()))
  assert(is_whitespace_content([ ]))
  assert(is_whitespace_content([
    #parbreak()
    #[ ]
    #parbreak()
  ]))
}

// #(content_to_array([#text(fill: red)[Hello]#pagebreak()*there*]))
#{
  let test = (
    (
      level: "question",
      id: 0,
      children: (),
      info: (
        points: 1.0,
        intent: none,
      ),
    ),
    (
      level: "part",
      id: 1,
      children: (),
      info: (
        points: 2.0,
        intent: none,
      ),
    ),
    (
      level: "subpart",
      id: 2,
      children: (),
      info: (
        points: 2.0,
        intent: none,
      ),
    ),
    (
      level: "part",
      id: 3,
      children: (),
      info: (
        points: 4.0,
        intent: none,
      ),
    ),
    (
      level: "question",
      id: 4,
      children: (),
      info: (
        points: none,
        intent: none,
      ),
    ),
    (
      level: "question",
      id: 5,
      children: (),
      info: (
        points: 3.0,
        intent: none,
      ),
    ),
  )
  [Before: #test]
  [

    After: #question_list_to_tree(test)

    After with totals: #augment_question_list(test)
  ]
}


