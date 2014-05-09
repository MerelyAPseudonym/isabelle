;;
;; Keyword classification tables for Isabelle/Isar.
;; Generated from HOL + HOL-Auth + HOL-BNF_Examples + HOL-Bali + HOL-Decision_Procs + HOL-IMP + HOL-Imperative_HOL + HOL-Import + HOL-Library + HOL-Mutabelle + HOL-Nominal + HOL-Predicate_Compile_Examples + HOL-Proofs + HOL-Proofs-Extraction + HOL-SPARK + HOL-Statespace + HOL-TPTP + HOL-Word-SMT_Examples + HOL-ex + HOLCF + Pure.
;; *** DO NOT EDIT *** DO NOT EDIT *** DO NOT EDIT ***
;;

(defconst isar-keywords-major
  '("\\."
    "\\.\\."
    "Isabelle\\.command"
    "ML"
    "ML_command"
    "ML_file"
    "ML_prf"
    "ML_val"
    "ProofGeneral\\.inform_file_processed"
    "ProofGeneral\\.inform_file_retracted"
    "ProofGeneral\\.kill_proof"
    "ProofGeneral\\.pr"
    "ProofGeneral\\.process_pgip"
    "ProofGeneral\\.restart"
    "ProofGeneral\\.undo"
    "SML_export"
    "SML_file"
    "SML_import"
    "abbreviation"
    "adhoc_overloading"
    "also"
    "apply"
    "apply_end"
    "approximate"
    "assume"
    "atom_decl"
    "attribute_setup"
    "axiomatization"
    "back"
    "bnf"
    "bnf_decl"
    "boogie_file"
    "bundle"
    "by"
    "cannot_undo"
    "cartouche"
    "case"
    "case_of_simps"
    "cd"
    "chapter"
    "class"
    "class_deps"
    "codatatype"
    "code_datatype"
    "code_deps"
    "code_identifier"
    "code_monad"
    "code_pred"
    "code_printing"
    "code_reflect"
    "code_reserved"
    "code_thms"
    "coinductive"
    "coinductive_set"
    "commit"
    "consts"
    "context"
    "corollary"
    "cpodef"
    "datatype"
    "datatype_compat"
    "datatype_new"
    "declaration"
    "declare"
    "def"
    "default_sort"
    "defer"
    "defer_recdef"
    "definition"
    "defs"
    "disable_pr"
    "display_drafts"
    "domain"
    "domain_isomorphism"
    "domaindef"
    "done"
    "enable_pr"
    "end"
    "equivariance"
    "exit"
    "export_code"
    "extract"
    "extract_type"
    "finally"
    "find_consts"
    "find_theorems"
    "find_unused_assms"
    "fix"
    "fixrec"
    "free_constructors"
    "from"
    "full_prf"
    "fun"
    "fun_cases"
    "function"
    "functor"
    "guess"
    "have"
    "header"
    "help"
    "hence"
    "hide_class"
    "hide_const"
    "hide_fact"
    "hide_type"
    "import_const_map"
    "import_file"
    "import_tptp"
    "import_type_map"
    "include"
    "including"
    "inductive"
    "inductive_cases"
    "inductive_set"
    "inductive_simps"
    "init_toplevel"
    "instance"
    "instantiation"
    "interpret"
    "interpretation"
    "judgment"
    "kill"
    "kill_thy"
    "lemma"
    "lemmas"
    "let"
    "lift_definition"
    "lifting_forget"
    "lifting_update"
    "linear_undo"
    "local_setup"
    "locale"
    "locale_deps"
    "method_setup"
    "moreover"
    "next"
    "nitpick"
    "nitpick_params"
    "no_adhoc_overloading"
    "no_notation"
    "no_syntax"
    "no_translations"
    "no_type_notation"
    "nominal_datatype"
    "nominal_inductive"
    "nominal_inductive2"
    "nominal_primrec"
    "nonterminal"
    "notation"
    "note"
    "notepad"
    "obtain"
    "oops"
    "oracle"
    "overloading"
    "parse_ast_translation"
    "parse_translation"
    "partial_function"
    "pcpodef"
    "permanent_interpretation"
    "pr"
    "prefer"
    "presume"
    "pretty_setmargin"
    "prf"
    "primcorec"
    "primcorecursive"
    "primrec"
    "print_ML_antiquotations"
    "print_abbrevs"
    "print_antiquotations"
    "print_ast_translation"
    "print_attributes"
    "print_binds"
    "print_bnfs"
    "print_bundles"
    "print_case_translations"
    "print_cases"
    "print_claset"
    "print_classes"
    "print_codeproc"
    "print_codesetup"
    "print_coercions"
    "print_commands"
    "print_context"
    "print_defn_rules"
    "print_dependencies"
    "print_facts"
    "print_induct_rules"
    "print_inductives"
    "print_interps"
    "print_locale"
    "print_locales"
    "print_methods"
    "print_options"
    "print_orders"
    "print_quot_maps"
    "print_quotconsts"
    "print_quotients"
    "print_quotientsQ3"
    "print_quotmapsQ3"
    "print_rules"
    "print_simpset"
    "print_state"
    "print_statement"
    "print_syntax"
    "print_theorems"
    "print_theory"
    "print_trans_rules"
    "print_translation"
    "proof"
    "prop"
    "pwd"
    "qed"
    "quickcheck"
    "quickcheck_generator"
    "quickcheck_params"
    "quit"
    "quotient_definition"
    "quotient_type"
    "realizability"
    "realizers"
    "recdef"
    "recdef_tc"
    "record"
    "refute"
    "refute_params"
    "remove_thy"
    "rep_datatype"
    "schematic_corollary"
    "schematic_lemma"
    "schematic_theorem"
    "sect"
    "section"
    "setup"
    "setup_lifting"
    "show"
    "simproc_setup"
    "simps_of_case"
    "sledgehammer"
    "sledgehammer_params"
    "smt2_status"
    "smt_status"
    "solve_direct"
    "sorry"
    "spark_end"
    "spark_open"
    "spark_open_vcg"
    "spark_proof_functions"
    "spark_status"
    "spark_types"
    "spark_vc"
    "specification"
    "statespace"
    "subclass"
    "sublocale"
    "subsect"
    "subsection"
    "subsubsect"
    "subsubsection"
    "syntax"
    "syntax_declaration"
    "term"
    "term_cartouche"
    "termination"
    "text"
    "text_cartouche"
    "text_raw"
    "then"
    "theorem"
    "theorems"
    "theory"
    "thm"
    "thm_deps"
    "thus"
    "thy_deps"
    "translations"
    "try"
    "try0"
    "txt"
    "txt_raw"
    "typ"
    "type_notation"
    "type_synonym"
    "typed_print_translation"
    "typedecl"
    "typedef"
    "ultimately"
    "undo"
    "undos_proof"
    "unfolding"
    "unused_thms"
    "use_thy"
    "using"
    "value"
    "values"
    "values_prolog"
    "welcome"
    "with"
    "write"
    "{"
    "}"))

(defconst isar-keywords-minor
  '("and"
    "assumes"
    "attach"
    "avoids"
    "begin"
    "binder"
    "checking"
    "class_instance"
    "class_relation"
    "code_module"
    "congs"
    "constant"
    "constrains"
    "datatypes"
    "defines"
    "defining"
    "file"
    "fixes"
    "for"
    "functions"
    "hints"
    "identifier"
    "if"
    "imports"
    "in"
    "includes"
    "infix"
    "infixl"
    "infixr"
    "is"
    "keywords"
    "lazy"
    "module_name"
    "monos"
    "morphisms"
    "notes"
    "obtains"
    "open"
    "output"
    "overloaded"
    "parametric"
    "permissive"
    "pervasive"
    "shows"
    "structure"
    "type_class"
    "type_constructor"
    "unchecked"
    "unsafe"
    "where"))

(defconst isar-keywords-control
  '("Isabelle\\.command"
    "ProofGeneral\\.inform_file_processed"
    "ProofGeneral\\.inform_file_retracted"
    "ProofGeneral\\.kill_proof"
    "ProofGeneral\\.pr"
    "ProofGeneral\\.process_pgip"
    "ProofGeneral\\.restart"
    "ProofGeneral\\.undo"
    "cannot_undo"
    "cd"
    "commit"
    "disable_pr"
    "enable_pr"
    "exit"
    "init_toplevel"
    "kill"
    "kill_thy"
    "linear_undo"
    "pretty_setmargin"
    "quit"
    "remove_thy"
    "undo"
    "undos_proof"
    "use_thy"))

(defconst isar-keywords-diag
  '("ML_command"
    "ML_val"
    "approximate"
    "cartouche"
    "class_deps"
    "code_deps"
    "code_thms"
    "display_drafts"
    "find_consts"
    "find_theorems"
    "find_unused_assms"
    "full_prf"
    "header"
    "help"
    "locale_deps"
    "nitpick"
    "pr"
    "prf"
    "print_ML_antiquotations"
    "print_abbrevs"
    "print_antiquotations"
    "print_attributes"
    "print_binds"
    "print_bnfs"
    "print_bundles"
    "print_case_translations"
    "print_cases"
    "print_claset"
    "print_classes"
    "print_codeproc"
    "print_codesetup"
    "print_coercions"
    "print_commands"
    "print_context"
    "print_defn_rules"
    "print_dependencies"
    "print_facts"
    "print_induct_rules"
    "print_inductives"
    "print_interps"
    "print_locale"
    "print_locales"
    "print_methods"
    "print_options"
    "print_orders"
    "print_quot_maps"
    "print_quotconsts"
    "print_quotients"
    "print_quotientsQ3"
    "print_quotmapsQ3"
    "print_rules"
    "print_simpset"
    "print_state"
    "print_statement"
    "print_syntax"
    "print_theorems"
    "print_theory"
    "print_trans_rules"
    "prop"
    "pwd"
    "quickcheck"
    "refute"
    "sledgehammer"
    "smt2_status"
    "smt_status"
    "solve_direct"
    "spark_status"
    "term"
    "term_cartouche"
    "thm"
    "thm_deps"
    "thy_deps"
    "try"
    "try0"
    "typ"
    "unused_thms"
    "value"
    "values"
    "values_prolog"
    "welcome"))

(defconst isar-keywords-theory-begin
  '("theory"))

(defconst isar-keywords-theory-switch
  '())

(defconst isar-keywords-theory-end
  '("end"))

(defconst isar-keywords-theory-heading
  '("chapter"
    "section"
    "subsection"
    "subsubsection"))

(defconst isar-keywords-theory-decl
  '("ML"
    "ML_file"
    "SML_export"
    "SML_file"
    "SML_import"
    "abbreviation"
    "adhoc_overloading"
    "atom_decl"
    "attribute_setup"
    "axiomatization"
    "bnf_decl"
    "boogie_file"
    "bundle"
    "case_of_simps"
    "class"
    "codatatype"
    "code_datatype"
    "code_identifier"
    "code_monad"
    "code_printing"
    "code_reflect"
    "code_reserved"
    "coinductive"
    "coinductive_set"
    "consts"
    "context"
    "datatype"
    "datatype_compat"
    "datatype_new"
    "declaration"
    "declare"
    "default_sort"
    "defer_recdef"
    "definition"
    "defs"
    "domain"
    "domain_isomorphism"
    "domaindef"
    "equivariance"
    "export_code"
    "extract"
    "extract_type"
    "fixrec"
    "fun"
    "fun_cases"
    "hide_class"
    "hide_const"
    "hide_fact"
    "hide_type"
    "import_const_map"
    "import_file"
    "import_tptp"
    "import_type_map"
    "inductive"
    "inductive_cases"
    "inductive_set"
    "inductive_simps"
    "instantiation"
    "judgment"
    "lemmas"
    "lifting_forget"
    "lifting_update"
    "local_setup"
    "locale"
    "method_setup"
    "nitpick_params"
    "no_adhoc_overloading"
    "no_notation"
    "no_syntax"
    "no_translations"
    "no_type_notation"
    "nominal_datatype"
    "nonterminal"
    "notation"
    "notepad"
    "oracle"
    "overloading"
    "parse_ast_translation"
    "parse_translation"
    "partial_function"
    "primcorec"
    "primrec"
    "print_ast_translation"
    "print_translation"
    "quickcheck_generator"
    "quickcheck_params"
    "realizability"
    "realizers"
    "recdef"
    "record"
    "refute_params"
    "setup"
    "setup_lifting"
    "simproc_setup"
    "simps_of_case"
    "sledgehammer_params"
    "spark_end"
    "spark_open"
    "spark_open_vcg"
    "spark_proof_functions"
    "spark_types"
    "statespace"
    "syntax"
    "syntax_declaration"
    "text"
    "text_cartouche"
    "text_raw"
    "theorems"
    "translations"
    "type_notation"
    "type_synonym"
    "typed_print_translation"
    "typedecl"))

(defconst isar-keywords-theory-script
  '())

(defconst isar-keywords-theory-goal
  '("bnf"
    "code_pred"
    "corollary"
    "cpodef"
    "free_constructors"
    "function"
    "functor"
    "instance"
    "interpretation"
    "lemma"
    "lift_definition"
    "nominal_inductive"
    "nominal_inductive2"
    "nominal_primrec"
    "pcpodef"
    "permanent_interpretation"
    "primcorecursive"
    "quotient_definition"
    "quotient_type"
    "recdef_tc"
    "rep_datatype"
    "schematic_corollary"
    "schematic_lemma"
    "schematic_theorem"
    "spark_vc"
    "specification"
    "subclass"
    "sublocale"
    "termination"
    "theorem"
    "typedef"))

(defconst isar-keywords-qed
  '("\\."
    "\\.\\."
    "by"
    "done"
    "sorry"))

(defconst isar-keywords-qed-block
  '("qed"))

(defconst isar-keywords-qed-global
  '("oops"))

(defconst isar-keywords-proof-heading
  '("sect"
    "subsect"
    "subsubsect"))

(defconst isar-keywords-proof-goal
  '("have"
    "hence"
    "interpret"))

(defconst isar-keywords-proof-block
  '("next"
    "proof"))

(defconst isar-keywords-proof-open
  '("{"))

(defconst isar-keywords-proof-close
  '("}"))

(defconst isar-keywords-proof-chain
  '("finally"
    "from"
    "then"
    "ultimately"
    "with"))

(defconst isar-keywords-proof-decl
  '("ML_prf"
    "also"
    "include"
    "including"
    "let"
    "moreover"
    "note"
    "txt"
    "txt_raw"
    "unfolding"
    "using"
    "write"))

(defconst isar-keywords-proof-asm
  '("assume"
    "case"
    "def"
    "fix"
    "presume"))

(defconst isar-keywords-proof-asm-goal
  '("guess"
    "obtain"
    "show"
    "thus"))

(defconst isar-keywords-proof-script
  '("apply"
    "apply_end"
    "back"
    "defer"
    "prefer"))

(provide 'isar-keywords)
