(*  Title:      HOLCF/holcfb.thy
    ID:         $Id$
    Author:     Franz Regensburger
    Copyright   1993  Technische Universitaet Muenchen

Basic definitions for the embedding of LCF into HOL.

*)

Holcfb = Nat + 

consts
        theleast     :: "(nat=>bool)=>nat"
defs

theleast_def    "theleast P == (@z.(P z & (!n.P n --> z<=n)))"

(* start 8bit 1 *)
(* end 8bit 1 *)

end
