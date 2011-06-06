(*  Title:      HOL/Metis_Examples/Type_Encodings.thy
    Author:     Jasmin Blanchette, TU Muenchen

Example that exercises Metis's (and hence Sledgehammer's) type encodings.
*)

header {*
Example that Exercises Metis's (and Hence Sledgehammer's) Type Encodings
*}

theory Type_Encodings
imports Main
begin

declare [[metis_new_skolemizer]]

sledgehammer_params [prover = e, blocking, timeout = 10, preplay_timeout = 0]


text {* Setup for testing Metis exhaustively *}

lemma fork: "P \<Longrightarrow> P \<Longrightarrow> P" by assumption

ML {*
open ATP_Translate

val polymorphisms = [Polymorphic, Monomorphic, Mangled_Monomorphic]
val levels =
  [All_Types, Nonmonotonic_Types, Finite_Types, Const_Arg_Types, No_Types]
val heaviness = [Heavyweight, Lightweight]
val type_syss =
  (levels |> map Simple_Types) @
  (map_product pair levels heaviness
   (* The following two families of type systems are too incomplete for our
      tests. *)
   |> remove (op =) (Nonmonotonic_Types, Heavyweight)
   |> remove (op =) (Finite_Types, Heavyweight)
   |> map_product pair polymorphisms
   |> map_product (fn constr => fn (poly, (level, heaviness)) =>
                      constr (poly, level, heaviness))
                  [Preds, Tags])

fun new_metis_exhaust_tac ctxt ths =
  let
    fun tac [] st = all_tac st
      | tac (type_sys :: type_syss) st =
        st (* |> tap (fn _ => tracing (PolyML.makestring type_sys)) *)
           |> ((if null type_syss then all_tac else rtac @{thm fork} 1)
               THEN Metis_Tactics.new_metis_tac [type_sys] ctxt ths 1
               THEN COND (has_fewer_prems 2) all_tac no_tac
               THEN tac type_syss)
  in tac end
*}

method_setup new_metis_exhaust = {*
  Attrib.thms >>
    (fn ths => fn ctxt => SIMPLE_METHOD (new_metis_exhaust_tac ctxt ths type_syss))
*} "exhaustively run the new Metis with all type encodings"


text {* Miscellaneous tests *}

lemma "x = y \<Longrightarrow> y = x"
by new_metis_exhaust

lemma "[a] = [1 + 1] \<Longrightarrow> a = 1 + (1::int)"
by (new_metis_exhaust last.simps)

lemma "map Suc [0] = [Suc 0]"
by (new_metis_exhaust map.simps)

lemma "map Suc [1 + 1] = [Suc 2]"
by (new_metis_exhaust map.simps nat_1_add_1)

lemma "map Suc [2] = [Suc (1 + 1)]"
by (new_metis_exhaust map.simps nat_1_add_1)

definition "null xs = (xs = [])"

lemma "P (null xs) \<Longrightarrow> null xs \<Longrightarrow> xs = []"
by (new_metis_exhaust null_def)

lemma "(0::nat) + 0 = 0"
by (new_metis_exhaust arithmetic_simps(38))

end
