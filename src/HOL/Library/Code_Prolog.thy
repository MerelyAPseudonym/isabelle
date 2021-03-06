(*  Title:      HOL/Library/Code_Prolog.thy
    Author:     Lukas Bulwahn, TUM 2010
*)

section {* Code generation of prolog programs *}

theory Code_Prolog
imports Main
keywords "values_prolog" :: diag
begin

ML_file "~~/src/HOL/Tools/Predicate_Compile/code_prolog.ML"

section {* Setup for Numerals *}

setup {* Predicate_Compile_Data.ignore_consts [@{const_name numeral}] *}

setup {* Predicate_Compile_Data.keep_functions [@{const_name numeral}] *}

end
