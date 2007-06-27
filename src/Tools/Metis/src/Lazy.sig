(* ========================================================================= *)
(* SUPPORT FOR LAZY EVALUATION                                               *)
(* Copyright (c) 2007 Joe Hurd, distributed under the BSD License      *)
(* ========================================================================= *)

signature Lazy =
sig

type 'a lazy

val delay : (unit -> 'a) -> 'a lazy

val force : 'a lazy -> 'a

val memoize : (unit -> 'a) -> unit -> 'a

end
