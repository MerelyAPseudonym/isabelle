(*  Title:      HOL/AxClasses/Tutorial/BoolGroupInsts.thy
    ID:         $Id$
    Author:     Markus Wenzel, TU Muenchen

Define overloaded constants "<*>", "inv", "1" on type "bool"
appropriately, then prove that this forms a group.
*)

BoolGroupInsts = Group +

(* bool as abelian group *)

defs
  prod_bool_def "x <*> y == x ~= (y::bool)"
  inv_bool_def  "inv x   == x::bool"
  unit_bool_def "1       == False"

instance
  bool :: agroup                {| ALLGOALS (fast_tac HOL_cs) |}
  (*"instance" automatically uses above defs, 
    the remaining goals are proven 'inline'*)

end
