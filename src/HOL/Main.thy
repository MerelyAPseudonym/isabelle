
(*theory Main includes everything; note that theory
  PreList already includes most HOL theories*)

theory Main = Map + String:

lemmas [mono] = lists_mono

end

