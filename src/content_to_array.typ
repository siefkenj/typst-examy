
/// Convert content of various types into an array of content.
#let content_to_array(it) = {
  if type(it) == array {
    return it
  }
  if type(it) != content {
    return (it,)
  }
  // We are content. If we have a `text` field, we are just a block of text.
  if it.has("text") {
    return (it.at("text"),)
  }
  // Otherwise, we look for children or body
  if it.has("children") {
    return it.at("children").map(content_to_array).flatten()
  }
  (it,)
}

// Testing code
#{
  assert(type(content_to_array("Hello")) == array)
  assert(type(content_to_array([Hello])) == array)
  assert(content_to_array([Hello#pagebreak()there]).len() == 3)
  assert(content_to_array([#metadata("")]).len() == 1)
  assert(content_to_array([#metadata("")#metadata("")]).len() == 2)
  assert(content_to_array([abc#[xyz#parbreak()www]]).len() == 4)
}

