(*  Title:      HOL/TPTP/ATP_Theory_Export.thy
    Author:     Jasmin Blanchette, TU Muenchen
*)

section {* ATP Theory Exporter *}

theory ATP_Theory_Export
imports Complex_Main
begin

ML_file "atp_theory_export.ML"

ML {*
open ATP_Problem
open ATP_Theory_Export
*}

ML {*
val do_it = false (* switch to "true" to generate the files *)
val ctxt = @{context}
val thy = @{theory List}
val infer_policy = Unchecked_Inferences
*}

ML {*
if do_it then
  "/tmp/axs_tc_native.dfg"
  |> generate_atp_inference_file_for_theory ctxt thy (DFG Polymorphic)
         infer_policy "tc_native"
else
  ()
*}

ML {*
if do_it then
  "/tmp/infs_poly_guards_query_query.tptp"
  |> generate_atp_inference_file_for_theory ctxt thy FOF infer_policy
         "poly_guards??"
else
  ()
*}

ML {*
if do_it then
  "/tmp/infs_poly_tags_query_query.tptp"
  |> generate_atp_inference_file_for_theory ctxt thy FOF infer_policy
         "poly_tags??"
else
  ()
*}

ML {*
if do_it then
  "/tmp/casc_ltb_isa"
  |> generate_casc_lbt_isa_files_for_theory ctxt thy FOF infer_policy
         "poly_tags??"
else
  ()
*}

end
