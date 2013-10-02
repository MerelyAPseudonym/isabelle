(*  Title:      HOL/BNF/Examples/TreeFsetI.thy
    Author:     Dmitriy Traytel, TU Muenchen
    Author:     Andrei Popescu, TU Muenchen
    Copyright   2012

Finitely branching possibly infinite trees, with sets of children.
*)

header {* Finitely Branching Possibly Infinite Trees, with Sets of Children *}

theory TreeFsetI
imports "../BNF"
begin

hide_fact (open) Lifting_Product.prod_rel_def

codatatype 'a treeFsetI = Tree (lab: 'a) (sub: "'a treeFsetI fset")

(* tree map (contrived example): *)
primcorec tmap where
"lab (tmap f t) = f (lab t)" |
"sub (tmap f t) = fimage (tmap f) (sub t)"

lemma "tmap (f o g) x = tmap f (tmap g x)"
  by (coinduction arbitrary: x) (auto simp: fset_rel_alt)

end
