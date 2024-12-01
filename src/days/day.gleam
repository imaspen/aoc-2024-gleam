import days/part.{type Part}

pub type Day =
  fn(Part, String) -> Result(String, String)
