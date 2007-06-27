(* ========================================================================= *)
(* ML SPECIFIC FUNCTIONS                                                     *)
(* Copyright (c) 2001-2004 Joe Hurd, distributed under the BSD License *)
(* ========================================================================= *)

signature Portable =
sig

(* ------------------------------------------------------------------------- *)
(* The ML implementation                                                     *)
(* ------------------------------------------------------------------------- *)

val ml : string

(* ------------------------------------------------------------------------- *)
(* Pointer equality using the run-time system                                *)
(* ------------------------------------------------------------------------- *)

val pointerEqual : 'a * 'a -> bool

(* ------------------------------------------------------------------------- *)
(* Timing function applications                                              *)
(* ------------------------------------------------------------------------- *)

val time : ('a -> 'b) -> 'a -> 'b

end
