(*  Title:      HOL/Tools/Quickcheck/narrowing_generators.ML
    Author:     Lukas Bulwahn, TU Muenchen

Narrowing-based counterexample generation.
*)

signature NARROWING_GENERATORS =
sig
  val allow_existentials : bool Config.T
  val finite_functions : bool Config.T
  val overlord : bool Config.T
  val ghc_options : string Config.T  (* FIXME prefer settings, i.e. getenv (!?) *)
  val active : bool Config.T
  datatype counterexample = Universal_Counterexample of (term * counterexample)
    | Existential_Counterexample of (term * counterexample) list
    | Empty_Assignment
  val put_counterexample: (unit -> (bool * term list) option) -> Proof.context -> Proof.context
  val put_existential_counterexample : (unit -> counterexample option) -> Proof.context -> Proof.context
end;

structure Narrowing_Generators : NARROWING_GENERATORS =
struct

(* configurations *)

val allow_existentials = Attrib.setup_config_bool @{binding quickcheck_allow_existentials} (K true)
val finite_functions = Attrib.setup_config_bool @{binding quickcheck_finite_functions} (K true)
val overlord = Attrib.setup_config_bool @{binding quickcheck_narrowing_overlord} (K false)
val ghc_options = Attrib.setup_config_string @{binding quickcheck_narrowing_ghc_options} (K "")

(* partial_term_of instances *)

fun mk_partial_term_of (x, T) =
  Const (@{const_name Quickcheck_Narrowing.partial_term_of_class.partial_term_of},
    Term.itselfT T --> @{typ narrowing_term} --> @{typ Code_Evaluation.term})
      $ Logic.mk_type T $ x

(** formal definition **)

fun add_partial_term_of tyco raw_vs thy =
  let
    val vs = map (fn (v, _) => (v, @{sort typerep})) raw_vs;
    val ty = Type (tyco, map TFree vs);
    val lhs = Const (@{const_name partial_term_of},
        Term.itselfT ty --> @{typ narrowing_term} --> @{typ Code_Evaluation.term})
      $ Free ("x", Term.itselfT ty) $ Free ("t", @{typ narrowing_term});
    val rhs = @{term "undefined :: Code_Evaluation.term"};
    val eq = HOLogic.mk_Trueprop (HOLogic.mk_eq (lhs, rhs));
    fun triv_name_of t = (fst o dest_Free o fst o strip_comb o fst
      o HOLogic.dest_eq o HOLogic.dest_Trueprop) t ^ "_triv";
  in
    thy
    |> Class.instantiation ([tyco], vs, @{sort partial_term_of})
    |> `(fn lthy => Syntax.check_term lthy eq)
    |-> (fn eq => Specification.definition (NONE, ((Binding.name (triv_name_of eq), []), eq)))
    |> snd
    |> Class.prove_instantiation_exit (K (Class.intro_classes_tac []))
  end;

fun ensure_partial_term_of (tyco, (raw_vs, _)) thy =
  let
    val need_inst = not (Sorts.has_instance (Sign.classes_of thy) tyco @{sort partial_term_of})
      andalso Sorts.has_instance (Sign.classes_of thy) tyco @{sort typerep};
  in if need_inst then add_partial_term_of tyco raw_vs thy else thy end;


(** code equations for datatypes **)

fun mk_partial_term_of_eq thy ty (i, (c, (_, tys))) =
  let
    val frees = map Free (Name.invent_names Name.context "a" (map (K @{typ narrowing_term}) tys))
    val narrowing_term = @{term Quickcheck_Narrowing.Narrowing_constructor} $ HOLogic.mk_number @{typ integer} i
      $ HOLogic.mk_list @{typ narrowing_term} (rev frees)
    val rhs = fold (fn u => fn t => @{term "Code_Evaluation.App"} $ t $ u)
        (map mk_partial_term_of (frees ~~ tys))
        (@{term "Code_Evaluation.Const"} $ HOLogic.mk_literal c $ HOLogic.mk_typerep (tys ---> ty))
    val insts =
      map (SOME o Thm.cterm_of thy o Logic.unvarify_types_global o Logic.varify_global)
        [Free ("ty", Term.itselfT ty), narrowing_term, rhs]
    val cty = Thm.ctyp_of thy ty;
  in
    @{thm partial_term_of_anything}
    |> Drule.instantiate' [SOME cty] insts
    |> Thm.varifyT_global
  end

fun add_partial_term_of_code tyco raw_vs raw_cs thy =
  let
    val algebra = Sign.classes_of thy;
    val vs = map (fn (v, sort) =>
      (v, curry (Sorts.inter_sort algebra) @{sort typerep} sort)) raw_vs;
    val ty = Type (tyco, map TFree vs);
    val cs = (map o apsnd o apsnd o map o map_atyps)
      (fn TFree (v, _) => TFree (v, (the o AList.lookup (op =) vs) v)) raw_cs;
    val const = Axclass.param_of_inst thy (@{const_name partial_term_of}, tyco);
    val var_insts =
      map (SOME o Thm.cterm_of thy o Logic.unvarify_types_global o Logic.varify_global)
        [Free ("ty", Term.itselfT ty), @{term "Quickcheck_Narrowing.Narrowing_variable p tt"},
          @{term "Code_Evaluation.Free (STR ''_'')"} $ HOLogic.mk_typerep ty];
    val var_eq =
      @{thm partial_term_of_anything}
      |> Drule.instantiate' [SOME (Thm.ctyp_of thy ty)] var_insts
      |> Thm.varifyT_global
    val eqs = var_eq :: map_index (mk_partial_term_of_eq thy ty) cs;
 in
    thy
    |> Code.del_eqns const
    |> fold Code.add_eqn eqs
  end;

fun ensure_partial_term_of_code (tyco, (raw_vs, cs)) thy =
  let
    val has_inst = Sorts.has_instance (Sign.classes_of thy) tyco @{sort partial_term_of};
  in if has_inst then add_partial_term_of_code tyco raw_vs cs thy else thy end;


(* narrowing generators *)

(** narrowing specific names and types **)

exception FUNCTION_TYPE;

val narrowingN = "narrowing";

fun narrowingT T =
  @{typ integer} --> Type (@{type_name Quickcheck_Narrowing.narrowing_cons}, [T])

fun mk_cons c T = Const (@{const_name Quickcheck_Narrowing.cons}, T --> narrowingT T) $ Const (c, T)

fun mk_apply (T, t) (U, u) =
  let
    val (_, U') = dest_funT U
  in
    (U', Const (@{const_name Quickcheck_Narrowing.apply},
      narrowingT U --> narrowingT T --> narrowingT U') $ u $ t)
  end

fun mk_sum (t, u) =
  let
    val T = fastype_of t
  in
    Const (@{const_name Quickcheck_Narrowing.sum}, T --> T --> T) $ t $ u
  end

(** deriving narrowing instances **)

fun mk_equations descr vs narrowings =
  let
    fun mk_call T =
      (T, Const (@{const_name "Quickcheck_Narrowing.narrowing_class.narrowing"}, narrowingT T))
    fun mk_aux_call fTs (k, _) (tyco, Ts) =
      let
        val T = Type (tyco, Ts)
        val _ = if not (null fTs) then raise FUNCTION_TYPE else ()
      in
        (T, nth narrowings k)
      end
    fun mk_consexpr simpleT (c, xs) =
      let
        val Ts = map fst xs
      in snd (fold mk_apply xs (Ts ---> simpleT, mk_cons c (Ts ---> simpleT))) end
    fun mk_rhs exprs = foldr1 mk_sum exprs
    val rhss =
      Old_Datatype_Aux.interpret_construction descr vs
        { atyp = mk_call, dtyp = mk_aux_call }
      |> (map o apfst) Type
      |> map (fn (T, cs) => map (mk_consexpr T) cs)
      |> map mk_rhs
    val lhss = narrowings
    val eqs = map (HOLogic.mk_Trueprop o HOLogic.mk_eq) (lhss ~~ rhss)
  in
    eqs
  end

fun contains_recursive_type_under_function_types xs =
  exists (fn (_, (_, _, cs)) => cs |> exists (snd #> exists (fn dT =>
    (case Old_Datatype_Aux.strip_dtyp dT of (_ :: _, Old_Datatype_Aux.DtRec _) => true | _ => false)))) xs

fun instantiate_narrowing_datatype config descr vs tycos prfx (names, auxnames) (Ts, Us) thy =
  let
    val _ = Old_Datatype_Aux.message config "Creating narrowing generators ...";
    val narrowingsN = map (prefix (narrowingN ^ "_")) (names @ auxnames);
  in
    if not (contains_recursive_type_under_function_types descr) then
      thy
      |> Class.instantiation (tycos, vs, @{sort narrowing})
      |> Quickcheck_Common.define_functions
        (fn narrowings => mk_equations descr vs narrowings, NONE)
        prfx [] narrowingsN (map narrowingT (Ts @ Us))
      |> Class.prove_instantiation_exit (K (Class.intro_classes_tac []))
    else
      thy
  end;

(* testing framework *)

val target = "Haskell_Quickcheck"

(** invocation of Haskell interpreter **)

val narrowing_engine =
  File.read @{path "~~/src/HOL/Tools/Quickcheck/Narrowing_Engine.hs"}

val pnf_narrowing_engine =
  File.read @{path "~~/src/HOL/Tools/Quickcheck/PNF_Narrowing_Engine.hs"}

fun exec verbose code =
  ML_Context.exec (fn () => Secure.use_text ML_Env.local_context (0, "generated code") verbose code)

fun with_overlord_dir name f =
  let
    val path =
      Path.append (Path.explode "$ISABELLE_HOME_USER") (Path.basic (name ^ serial_string ()))
    val _ = Isabelle_System.mkdirs path;
  in Exn.release (Exn.capture f path) end;

fun elapsed_time description e =
  let val ({elapsed, ...}, result) = Timing.timing e ()
  in (result, (description, Time.toMilliseconds elapsed)) end

fun value (contains_existentials, ((genuine_only, (quiet, verbose)), size)) ctxt cookie (code_modules, _) =
  let
    val ((is_genuine, counterexample_of), (get, put, put_ml)) = cookie
    fun message s = if quiet then () else writeln s
    fun verbose_message s = if not quiet andalso verbose then writeln s else ()
    val current_size = Unsynchronized.ref 0
    val current_result = Unsynchronized.ref Quickcheck.empty_result
    val tmp_prefix = "Quickcheck_Narrowing"
    val ghc_options = Config.get ctxt ghc_options
    val with_tmp_dir =
      if Config.get ctxt overlord then with_overlord_dir else Isabelle_System.with_tmp_dir
    fun run in_path =
      let
        fun mk_code_file name = Path.append in_path (Path.basic (name ^ ".hs"))
        val generatedN = Code_Target.generatedN
        val includes = AList.delete (op =) generatedN code_modules |> (map o apfst) mk_code_file;
        val code = the (AList.lookup (op =) code_modules generatedN)
        val code_file = mk_code_file generatedN
        val narrowing_engine_file = mk_code_file "Narrowing_Engine"
        val main_file = mk_code_file "Main"
        val main = "module Main where {\n\n" ^
          "import System.IO;\n" ^
          "import System.Environment;\n" ^
          "import Narrowing_Engine;\n" ^
          "import " ^ generatedN ^ " ;\n\n" ^
          "main = getArgs >>= \\[potential, size] -> " ^
          "Narrowing_Engine.depthCheck (read potential) (read size) (" ^ generatedN ^ ".value ())\n\n" ^
          "}\n"
        val _ = map (uncurry File.write) (includes @
          [(narrowing_engine_file, if contains_existentials then pnf_narrowing_engine else narrowing_engine),
           (code_file, code), (main_file, main)])
        val executable = File.shell_path (Path.append in_path (Path.basic "isabelle_quickcheck_narrowing"))
        val cmd = "exec \"$ISABELLE_GHC\" " ^ Code_Haskell.language_params ^ " " ^
          ghc_options ^ " " ^
          (space_implode " " (map File.shell_path (map fst includes @ [code_file, narrowing_engine_file, main_file]))) ^
          " -o " ^ executable ^ ";"
        val (_, compilation_time) =
          elapsed_time "Haskell compilation" (fn () => Isabelle_System.bash cmd)
        val _ = Quickcheck.add_timing compilation_time current_result
        fun haskell_string_of_bool v = if v then "True" else "False"
        val _ = if Isabelle_System.bash cmd <> 0 then error "Compilation with GHC failed" else ()
        fun with_size genuine_only k =
          if k > size then
            (NONE, !current_result)
          else
            let
              val _ = verbose_message ("[Quickcheck-narrowing] Test data size: " ^ string_of_int k)
              val _ = current_size := k
              val ((response, _), timing) = elapsed_time ("execution of size " ^ string_of_int k)
                (fn () => Isabelle_System.bash_output
                  (executable ^ " " ^ haskell_string_of_bool genuine_only ^ " " ^ string_of_int k))
              val _ = Quickcheck.add_timing timing current_result
            in
              if response = "NONE\n" then
                with_size genuine_only (k + 1)
              else
                let
                  val output_value = the_default "NONE"
                    (try (snd o split_last o filter_out (fn s => s = "") o split_lines) response)
                    |> translate_string (fn s => if s = "\\" then "\\\\" else s)
                  val ml_code = "\nval _ = Context.set_thread_data (SOME (Context.map_proof (" ^ put_ml
                    ^ " (fn () => " ^ output_value ^ ")) (ML_Context.the_generic_context ())))";
                  val ctxt' = ctxt
                    |> put (fn () => error ("Bad evaluation for " ^ quote put_ml))
                    |> Context.proof_map (exec false ml_code);
                  val counterexample = get ctxt' ()
                in
                  if is_genuine counterexample then
                    (counterexample, !current_result)
                  else
                    let
                      val cex = Option.map (rpair []) (counterexample_of counterexample)
                    in
                      (message (Pretty.string_of (Quickcheck.pretty_counterex ctxt false cex));
                      message "Quickcheck continues to find a genuine counterexample...";
                      with_size true (k + 1))
                    end
               end
            end
      in with_size genuine_only 0 end
  in
    with_tmp_dir tmp_prefix run
  end;

fun dynamic_value_strict opts cookie ctxt postproc t =
  let
    fun evaluator program _ vs_ty_t deps =
      Exn.interruptible_capture (value opts ctxt cookie)
        (Code_Target.evaluator ctxt target program deps true vs_ty_t);
  in Exn.release (Code_Thingol.dynamic_value ctxt (Exn.map_result o postproc) evaluator t) end;


(** counterexample generator **)

datatype counterexample =
    Universal_Counterexample of (term * counterexample)
  | Existential_Counterexample of (term * counterexample) list
  | Empty_Assignment

fun map_counterexample f Empty_Assignment = Empty_Assignment
  | map_counterexample f (Universal_Counterexample (t, c)) =
      Universal_Counterexample (f t, map_counterexample f c)
  | map_counterexample f (Existential_Counterexample cs) =
      Existential_Counterexample (map (fn (t, c) => (f t, map_counterexample f c)) cs)

structure Data = Proof_Data
(
  type T =
    (unit -> (bool * term list) option) *
    (unit -> counterexample option);
  val empty: T =
   (fn () => raise Fail "counterexample",
    fn () => raise Fail "existential_counterexample");
  fun init _ = empty;
);

val get_counterexample = #1 o Data.get;
val get_existential_counterexample = #2 o Data.get;

val put_counterexample = Data.map o @{apply 2(1)} o K;
val put_existential_counterexample = Data.map o @{apply 2(2)} o K;

fun finitize_functions (xTs, t) =
  let
    val (names, boundTs) = split_list xTs
    fun mk_eval_ffun dT rT =
      Const (@{const_name "Quickcheck_Narrowing.eval_ffun"},
        Type (@{type_name "Quickcheck_Narrowing.ffun"}, [dT, rT]) --> dT --> rT)
    fun mk_eval_cfun dT rT =
      Const (@{const_name "Quickcheck_Narrowing.eval_cfun"},
        Type (@{type_name "Quickcheck_Narrowing.cfun"}, [rT]) --> dT --> rT)
    fun eval_function (Type (@{type_name fun}, [dT, rT])) =
      let
        val (rt', rT') = eval_function rT
      in
        case dT of
          Type (@{type_name fun}, _) =>
            (fn t => absdummy dT (rt' (mk_eval_cfun dT rT' $ incr_boundvars 1 t $ Bound 0)),
              Type (@{type_name "Quickcheck_Narrowing.cfun"}, [rT']))
        | _ =>
            (fn t => absdummy dT (rt' (mk_eval_ffun dT rT' $ incr_boundvars 1 t $ Bound 0)),
              Type (@{type_name "Quickcheck_Narrowing.ffun"}, [dT, rT']))
      end
      | eval_function (T as Type (@{type_name prod}, [fT, sT])) =
        let
          val (ft', fT') = eval_function fT
          val (st', sT') = eval_function sT
          val T' = Type (@{type_name prod}, [fT', sT'])
          val map_const = Const (@{const_name map_prod}, (fT' --> fT) --> (sT' --> sT) --> T' --> T)
          fun apply_dummy T t = absdummy T (t (Bound 0))
        in
          (fn t => list_comb (map_const, [apply_dummy fT' ft', apply_dummy sT' st', t]), T')
        end
      | eval_function T = (I, T)
    val (tt, boundTs') = split_list (map eval_function boundTs)
    val t' = subst_bounds (map2 (fn f => fn x => f x) (rev tt) (map_index (Bound o fst) boundTs), t)
  in
    (names ~~ boundTs', t')
  end

fun dest_ffun (Type (@{type_name "Quickcheck_Narrowing.ffun"}, [dT, rT])) = (dT, rT)

fun eval_finite_functions (Const (@{const_name "Quickcheck_Narrowing.ffun.Constant"}, T) $ value) =
    absdummy (fst (dest_ffun (body_type T))) (eval_finite_functions value)
  | eval_finite_functions (Const (@{const_name "Quickcheck_Narrowing.ffun.Update"}, T) $ a $ b $ f) =
    let
      val (T1, T2) = dest_ffun (body_type T)
    in
      Quickcheck_Common.mk_fun_upd T1 T2
        (eval_finite_functions a, eval_finite_functions b) (eval_finite_functions f)
    end
  | eval_finite_functions t = t

(** tester **)

val rewrs =
    map (swap o HOLogic.dest_eq o HOLogic.dest_Trueprop o Thm.prop_of)
      (@{thms all_simps} @ @{thms ex_simps})
    @ map (HOLogic.dest_eq o HOLogic.dest_Trueprop o Thm.prop_of)
        [@{thm iff_conv_conj_imp}, @{thm not_ex}, @{thm not_all},
         @{thm meta_eq_to_obj_eq [OF Ex1_def]}]

fun make_pnf_term thy t = Pattern.rewrite_term thy rewrs [] t

fun strip_quantifiers (Const (@{const_name Ex}, _) $ Abs (x, T, t)) =
    apfst (cons (@{const_name Ex}, (x, T))) (strip_quantifiers t)
  | strip_quantifiers (Const (@{const_name All}, _) $ Abs (x, T, t)) =
    apfst (cons (@{const_name All}, (x, T))) (strip_quantifiers t)
  | strip_quantifiers t = ([], t)

fun contains_existentials t = exists (fn (Q, _) => Q = @{const_name Ex}) (fst (strip_quantifiers t))

fun mk_property qs t =
  let
    fun enclose (@{const_name Ex}, (x, T)) t =
        Const (@{const_name Quickcheck_Narrowing.exists}, (T --> @{typ property}) --> @{typ property})
          $ Abs (x, T, t)
      | enclose (@{const_name All}, (x, T)) t =
        Const (@{const_name Quickcheck_Narrowing.all}, (T --> @{typ property}) --> @{typ property})
          $ Abs (x, T, t)
  in
    fold_rev enclose qs (@{term Quickcheck_Narrowing.Property} $ t)
  end

fun mk_case_term ctxt p ((@{const_name Ex}, (x, T)) :: qs') (Existential_Counterexample cs) =
    Case_Translation.make_case ctxt Case_Translation.Quiet Name.context (Free (x, T)) (map (fn (t, c) =>
      (t, mk_case_term ctxt (p - 1) qs' c)) cs)
  | mk_case_term ctxt p ((@{const_name All}, _) :: qs') (Universal_Counterexample (t, c)) =
    if p = 0 then t else mk_case_term ctxt (p - 1) qs' c

val post_process = (perhaps (try Quickcheck_Common.post_process_term)) o eval_finite_functions

fun mk_terms ctxt qs result =
  let
    val
      ps = filter (fn (_, (@{const_name All}, _)) => true | _ => false) (map_index I qs)
    in
      map (fn (p, (_, (x, _))) => (x, mk_case_term ctxt p qs result)) ps
      |> map (apsnd post_process)
    end

fun test_term ctxt catch_code_errors (t, _) =
  let
    fun dest_result (Quickcheck.Result r) = r
    val opts =
      ((Config.get ctxt Quickcheck.genuine_only,
       (Config.get ctxt Quickcheck.quiet, Config.get ctxt Quickcheck.verbose)),
        Config.get ctxt Quickcheck.size)
    val thy = Proof_Context.theory_of ctxt
    val t' = fold_rev (fn (x, T) => fn t => HOLogic.mk_all (x, T, t)) (Term.add_frees t []) t
    val pnf_t = make_pnf_term thy t'
  in
    if Config.get ctxt allow_existentials andalso contains_existentials pnf_t then
      let
        fun wrap f (qs, t) =
          let val (qs1, qs2) = split_list qs in
          apfst (map2 pair qs1) (f (qs2, t)) end
        val finitize = if Config.get ctxt finite_functions then wrap finitize_functions else I
        val (qs, prop_t) = finitize (strip_quantifiers pnf_t)
        val act = if catch_code_errors then try else (fn f => SOME o f)
        val execute =
          dynamic_value_strict (true, opts)
            ((K true, fn _ => error ""),
              (get_existential_counterexample, put_existential_counterexample,
                "Narrowing_Generators.put_existential_counterexample"))
            ctxt (apfst o Option.map o map_counterexample)
      in
        case act execute (mk_property qs prop_t) of
          SOME (counterexample, result) => Quickcheck.Result
            {counterexample = Option.map (pair true o mk_terms ctxt qs) counterexample,
            evaluation_terms = Option.map (K []) counterexample,
            timings = #timings (dest_result result), reports = #reports (dest_result result)}
        | NONE =>
          (Quickcheck.message ctxt ("Conjecture is not executable with Quickcheck-narrowing");
           Quickcheck.empty_result)
      end
    else
      let
        val frees = Term.add_frees t []
        val t' = fold_rev absfree frees t
        fun wrap f t = uncurry (fold_rev Term.abs) (f (strip_abs t))
        val finitize = if Config.get ctxt finite_functions then wrap finitize_functions else I
        fun ensure_testable t =
          Const (@{const_name Quickcheck_Narrowing.ensure_testable}, fastype_of t --> fastype_of t) $ t
        fun is_genuine (SOME (true, _)) = true
          | is_genuine _ = false
        val counterexample_of = Option.map (apsnd (curry (op ~~) (map fst frees) o map post_process))
        val act = if catch_code_errors then try else (fn f => SOME o f)
        val execute =
          dynamic_value_strict (false, opts)
            ((is_genuine, counterexample_of),
              (get_counterexample, put_counterexample,
                "Narrowing_Generators.put_counterexample"))
            ctxt (apfst o Option.map o apsnd o map)
      in
        case act execute (ensure_testable (finitize t')) of
          SOME (counterexample, result) =>
            Quickcheck.Result
             {counterexample = counterexample_of counterexample,
              evaluation_terms = Option.map (K []) counterexample,
              timings = #timings (dest_result result),
              reports = #reports (dest_result result)}
        | NONE =>
          (Quickcheck.message ctxt ("Conjecture is not executable with Quickcheck-narrowing");
           Quickcheck.empty_result)
      end
  end;

fun test_goals ctxt catch_code_errors insts goals =
  if (not (getenv "ISABELLE_GHC" = "")) then
    let
      val _ = Quickcheck.message ctxt ("Testing conjecture with Quickcheck-narrowing...")
      val correct_inst_goals = Quickcheck_Common.instantiate_goals ctxt insts goals
    in
      Quickcheck_Common.collect_results (test_term ctxt catch_code_errors)
        (maps (map snd) correct_inst_goals) []
    end
  else
    (if Config.get ctxt Quickcheck.quiet then () else writeln
      ("Environment variable ISABELLE_GHC is not set. To use narrowing-based quickcheck, please set "
        ^ "this variable to your GHC Haskell compiler in your settings file. "
        ^ "To deactivate narrowing-based quickcheck, set quickcheck_narrowing_active to false.");
      [Quickcheck.empty_result])

(* setup *)

val active = Attrib.setup_config_bool @{binding quickcheck_narrowing_active} (K false);

val _ =
  Theory.setup
   (Code.datatype_interpretation ensure_partial_term_of
    #> Code.datatype_interpretation ensure_partial_term_of_code
    #> Quickcheck_Common.datatype_interpretation @{plugin quickcheck_narrowing}
      (@{sort narrowing}, instantiate_narrowing_datatype)
    #> Context.theory_map (Quickcheck.add_tester ("narrowing", (active, test_goals))));

end;
