(*  Title:      HOL/TPTP/MaSh_Import.thy
    Author:     Jasmin Blanchette, TU Muenchen
*)

header {* MaSh Importer *}

theory MaSh_Import
imports MaSh_Export
uses "mash_import.ML"
begin

sledgehammer_params
  [max_relevant = 40, strict, dont_slice, type_enc = poly_guards??,
   lam_trans = combs_and_lifting, timeout = 5, dont_preplay, minimize]

declare [[sledgehammer_instantiate_inducts]]

ML {*
open MaSh_Import
*}

ML {*
val do_it = false (* switch to "true" to generate the files *);
val thy = @{theory Nat}
*}

ML {*
if do_it then import_and_evaluate_mash_suggestions @{context} thy "/tmp/mash_suggestions"
else ()
*}

end
