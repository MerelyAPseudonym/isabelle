
header {* Install quickcheck of SML code generator *}

theory SML_Quickcheck
imports Main
begin

setup {*
  let
    fun compile_generator_expr ctxt [(t, eval_terms)] =
      let
        val prop = list_abs_free (Term.add_frees t [], t)
        val test_fun = Codegen.test_term ctxt prop
        val iterations = Config.get ctxt Quickcheck.iterations
        fun iterate size 0 = NONE
          | iterate size j =
              let
                val result = test_fun size handle Match =>
                  (if Config.get ctxt Quickcheck.quiet then ()
                   else warning "Exception Match raised during quickcheck"; NONE)
              in
                case result of NONE => iterate size (j - 1) | SOME q => SOME q
              end
      in fn [_, size] => (iterate size iterations, NONE) end))
    val test_goals = Quickcheck.generator_test_goal_terms compile_generator_expr
  in
    Inductive_Codegen.quickcheck_setup
    #> Context.theory_map (Quickcheck.add_generator ("SML", compile_generator_expr))
    #> Context.theory_map (Quickcheck.add_tester ("SML", test_goals))
  end
*}

end
