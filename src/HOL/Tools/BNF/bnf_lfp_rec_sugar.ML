(*  Title:      HOL/Tools/BNF/bnf_lfp_rec_sugar.ML
    Author:     Lorenz Panny, TU Muenchen
    Author:     Jasmin Blanchette, TU Muenchen
    Copyright   2013

Recursor sugar.
*)

signature BNF_LFP_REC_SUGAR =
sig
  val add_primrec: (binding * typ option * mixfix) list ->
    (Attrib.binding * term) list -> local_theory -> (term list * thm list list) * local_theory
  val add_primrec_cmd: (binding * string option * mixfix) list ->
    (Attrib.binding * string) list -> local_theory -> (term list * thm list list) * local_theory
  val add_primrec_global: (binding * typ option * mixfix) list ->
    (Attrib.binding * term) list -> theory -> (term list * thm list list) * theory
  val add_primrec_overloaded: (string * (string * typ) * bool) list ->
    (binding * typ option * mixfix) list ->
    (Attrib.binding * term) list -> theory -> (term list * thm list list) * theory
  val add_primrec_simple: ((binding * typ) * mixfix) list -> term list ->
    local_theory -> (string list * (term list * (int list list * thm list list))) * local_theory
end;

structure BNF_LFP_Rec_Sugar : BNF_LFP_REC_SUGAR =
struct

open Ctr_Sugar
open BNF_Util
open BNF_Tactics
open BNF_Def
open BNF_FP_Util
open BNF_FP_Def_Sugar
open BNF_FP_N2M_Sugar
open BNF_FP_Rec_Sugar_Util

val nitpicksimp_attrs = @{attributes [nitpick_simp]};
val simp_attrs = @{attributes [simp]};
val code_nitpicksimp_simp_attrs = Code.add_default_eqn_attrib :: nitpicksimp_attrs @ simp_attrs;

exception Primrec_Error of string * term list;

fun primrec_error str = raise Primrec_Error (str, []);
fun primrec_error_eqn str eqn = raise Primrec_Error (str, [eqn]);
fun primrec_error_eqns str eqns = raise Primrec_Error (str, eqns);

datatype rec_call =
  No_Rec of int * typ |
  Mutual_Rec of (int * typ) * (int * typ) |
  Nested_Rec of int * typ;

type rec_ctr_spec =
  {ctr: term,
   offset: int,
   calls: rec_call list,
   rec_thm: thm};

type rec_spec =
  {recx: term,
   nested_map_idents: thm list,
   nested_map_comps: thm list,
   ctr_specs: rec_ctr_spec list};

exception AINT_NO_MAP of term;

fun ill_formed_rec_call ctxt t =
  error ("Ill-formed recursive call: " ^ quote (Syntax.string_of_term ctxt t));
fun invalid_map ctxt t =
  error ("Invalid map function in " ^ quote (Syntax.string_of_term ctxt t));
fun unexpected_rec_call ctxt t =
  error ("Unexpected recursive call: " ^ quote (Syntax.string_of_term ctxt t));

fun massage_nested_rec_call ctxt has_call raw_massage_fun bound_Ts y y' =
  let
    fun check_no_call t = if has_call t then unexpected_rec_call ctxt t else ();

    val typof = curry fastype_of1 bound_Ts;
    val build_map_fst = build_map ctxt (fst_const o fst);

    val yT = typof y;
    val yU = typof y';

    fun y_of_y' () = build_map_fst (yU, yT) $ y';
    val elim_y = Term.map_aterms (fn t => if t = y then y_of_y' () else t);

    fun massage_mutual_fun U T t =
      (case t of
        Const (@{const_name comp}, _) $ t1 $ t2 =>
        mk_comp bound_Ts (tap check_no_call t1, massage_mutual_fun U T t2)
      | _ =>
        if has_call t then
          (case try HOLogic.dest_prodT U of
            SOME (U1, U2) => if U1 = T then raw_massage_fun T U2 t else invalid_map ctxt t
          | NONE => invalid_map ctxt t)
        else
          mk_comp bound_Ts (t, build_map_fst (U, T)));

    fun massage_map (Type (_, Us)) (Type (s, Ts)) t =
        (case try (dest_map ctxt s) t of
          SOME (map0, fs) =>
          let
            val Type (_, ran_Ts) = range_type (typof t);
            val map' = mk_map (length fs) Us ran_Ts map0;
            val fs' = map_flattened_map_args ctxt s (map3 massage_map_or_map_arg Us Ts) fs;
          in
            Term.list_comb (map', fs')
          end
        | NONE => raise AINT_NO_MAP t)
      | massage_map _ _ t = raise AINT_NO_MAP t
    and massage_map_or_map_arg U T t =
      if T = U then
        tap check_no_call t
      else
        massage_map U T t
        handle AINT_NO_MAP _ => massage_mutual_fun U T t;

    fun massage_call (t as t1 $ t2) =
        if has_call t then
          if t2 = y then
            massage_map yU yT (elim_y t1) $ y'
            handle AINT_NO_MAP t' => invalid_map ctxt t'
          else
            let val (g, xs) = Term.strip_comb t2 in
              if g = y then
                if exists has_call xs then unexpected_rec_call ctxt t2
                else Term.list_comb (massage_call (mk_compN (length xs) bound_Ts (t1, y)), xs)
              else
                ill_formed_rec_call ctxt t
            end
        else
          elim_y t
      | massage_call t = if t = y then y_of_y' () else ill_formed_rec_call ctxt t;
  in
    massage_call
  end;

fun rec_specs_of bs arg_Ts res_Ts get_indices callssss0 lthy0 =
  let
    val thy = Proof_Context.theory_of lthy0;

    val ((missing_arg_Ts, perm0_kks,
          fp_sugars as {nested_bnfs, fp_res = {xtor_co_iterss = ctor_iters1 :: _, ...},
            co_inducts = [induct_thm], ...} :: _, (lfp_sugar_thms, _)), lthy) =
      nested_to_mutual_fps Least_FP bs arg_Ts get_indices callssss0 lthy0;

    val perm_fp_sugars = sort (int_ord o pairself #index) fp_sugars;

    val indices = map #index fp_sugars;
    val perm_indices = map #index perm_fp_sugars;

    val perm_ctrss = map (#ctrs o of_fp_sugar #ctr_sugars) perm_fp_sugars;
    val perm_ctr_Tsss = map (map (binder_types o fastype_of)) perm_ctrss;
    val perm_lfpTs = map (body_type o fastype_of o hd) perm_ctrss;

    val nn0 = length arg_Ts;
    val nn = length perm_lfpTs;
    val kks = 0 upto nn - 1;
    val perm_ns = map length perm_ctr_Tsss;
    val perm_mss = map (map length) perm_ctr_Tsss;

    val perm_Cs = map (body_type o fastype_of o co_rec_of o of_fp_sugar (#xtor_co_iterss o #fp_res))
      perm_fp_sugars;
    val perm_fun_arg_Tssss =
      mk_iter_fun_arg_types perm_ctr_Tsss perm_ns perm_mss (co_rec_of ctor_iters1);

    fun unpermute0 perm0_xs = permute_like (op =) perm0_kks kks perm0_xs;
    fun unpermute perm_xs = permute_like (op =) perm_indices indices perm_xs;

    val induct_thms = unpermute0 (conj_dests nn induct_thm);

    val lfpTs = unpermute perm_lfpTs;
    val Cs = unpermute perm_Cs;

    val As_rho = tvar_subst thy (take nn0 lfpTs) arg_Ts;
    val Cs_rho = map (fst o dest_TVar) Cs ~~ pad_list HOLogic.unitT nn res_Ts;

    val substA = Term.subst_TVars As_rho;
    val substAT = Term.typ_subst_TVars As_rho;
    val substCT = Term.typ_subst_TVars Cs_rho;
    val substACT = substAT o substCT;

    val perm_Cs' = map substCT perm_Cs;

    fun offset_of_ctr 0 _ = 0
      | offset_of_ctr n (({ctrs, ...} : ctr_sugar) :: ctr_sugars) =
        length ctrs + offset_of_ctr (n - 1) ctr_sugars;

    fun call_of [i] [T] = (if exists_subtype_in Cs T then Nested_Rec else No_Rec) (i, substACT T)
      | call_of [i, i'] [T, T'] = Mutual_Rec ((i, substACT T), (i', substACT T'));

    fun mk_ctr_spec ctr offset fun_arg_Tss rec_thm =
      let
        val (fun_arg_hss, _) = indexedd fun_arg_Tss 0;
        val fun_arg_hs = flat_rec_arg_args fun_arg_hss;
        val fun_arg_iss = map (map (find_index_eq fun_arg_hs)) fun_arg_hss;
      in
        {ctr = substA ctr, offset = offset, calls = map2 call_of fun_arg_iss fun_arg_Tss,
         rec_thm = rec_thm}
      end;

    fun mk_ctr_specs index (ctr_sugars : ctr_sugar list) iter_thmsss =
      let
        val ctrs = #ctrs (nth ctr_sugars index);
        val rec_thms = co_rec_of (nth iter_thmsss index);
        val k = offset_of_ctr index ctr_sugars;
        val n = length ctrs;
      in
        map4 mk_ctr_spec ctrs (k upto k + n - 1) (nth perm_fun_arg_Tssss index) rec_thms
      end;

    fun mk_spec ({T, index, ctr_sugars, co_iterss = iterss, co_iter_thmsss = iter_thmsss, ...}
      : fp_sugar) =
      {recx = mk_co_iter thy Least_FP (substAT T) perm_Cs' (co_rec_of (nth iterss index)),
       nested_map_idents = map (unfold_thms lthy @{thms id_def} o map_id0_of_bnf) nested_bnfs,
       nested_map_comps = map map_comp_of_bnf nested_bnfs,
       ctr_specs = mk_ctr_specs index ctr_sugars iter_thmsss};
  in
    ((is_some lfp_sugar_thms, map mk_spec fp_sugars, missing_arg_Ts, induct_thm, induct_thms), lthy)
  end;

val undef_const = Const (@{const_name undefined}, dummyT);

fun permute_args n t =
  list_comb (t, map Bound (0 :: (n downto 1))) |> fold (K (Term.abs (Name.uu, dummyT))) (0 upto n);

type eqn_data = {
  fun_name: string,
  rec_type: typ,
  ctr: term,
  ctr_args: term list,
  left_args: term list,
  right_args: term list,
  res_type: typ,
  rhs_term: term,
  user_eqn: term
};

fun dissect_eqn lthy fun_names eqn' =
  let
    val eqn = drop_all eqn' |> HOLogic.dest_Trueprop
      handle TERM _ =>
        primrec_error_eqn "malformed function equation (expected \"lhs = rhs\")" eqn';
    val (lhs, rhs) = HOLogic.dest_eq eqn
        handle TERM _ =>
          primrec_error_eqn "malformed function equation (expected \"lhs = rhs\")" eqn';
    val (fun_name, args) = strip_comb lhs
      |>> (fn x => if is_Free x then fst (dest_Free x)
          else primrec_error_eqn "malformed function equation (does not start with free)" eqn);
    val (left_args, rest) = take_prefix is_Free args;
    val (nonfrees, right_args) = take_suffix is_Free rest;
    val num_nonfrees = length nonfrees;
    val _ = num_nonfrees = 1 orelse if num_nonfrees = 0 then
      primrec_error_eqn "constructor pattern missing in left-hand side" eqn else
      primrec_error_eqn "more than one non-variable argument in left-hand side" eqn;
    val _ = member (op =) fun_names fun_name orelse
      primrec_error_eqn "malformed function equation (does not start with function name)" eqn

    val (ctr, ctr_args) = strip_comb (the_single nonfrees);
    val _ = try (num_binder_types o fastype_of) ctr = SOME (length ctr_args) orelse
      primrec_error_eqn "partially applied constructor in pattern" eqn;
    val _ = let val d = duplicates (op =) (left_args @ ctr_args @ right_args) in null d orelse
      primrec_error_eqn ("duplicate variable \"" ^ Syntax.string_of_term lthy (hd d) ^
        "\" in left-hand side") eqn end;
    val _ = forall is_Free ctr_args orelse
      primrec_error_eqn "non-primitive pattern in left-hand side" eqn;
    val _ =
      let val b = fold_aterms (fn x as Free (v, _) =>
        if (not (member (op =) (left_args @ ctr_args @ right_args) x) andalso
        not (member (op =) fun_names v) andalso
        not (Variable.is_fixed lthy v)) then cons x else I | _ => I) rhs []
      in
        null b orelse
        primrec_error_eqn ("extra variable(s) in right-hand side: " ^
          commas (map (Syntax.string_of_term lthy) b)) eqn
      end;
  in
    {fun_name = fun_name,
     rec_type = body_type (type_of ctr),
     ctr = ctr,
     ctr_args = ctr_args,
     left_args = left_args,
     right_args = right_args,
     res_type = map fastype_of (left_args @ right_args) ---> fastype_of rhs,
     rhs_term = rhs,
     user_eqn = eqn'}
  end;

fun rewrite_map_arg get_ctr_pos rec_type res_type =
  let
    val pT = HOLogic.mk_prodT (rec_type, res_type);

    fun subst d (t as Bound d') = t |> d = SOME d' ? curry (op $) (fst_const pT)
      | subst d (Abs (v, T, b)) =
        Abs (v, if d = SOME ~1 then pT else T, subst (Option.map (Integer.add 1) d) b)
      | subst d t =
        let
          val (u, vs) = strip_comb t;
          val ctr_pos = try (get_ctr_pos o fst o dest_Free) u |> the_default ~1;
        in
          if ctr_pos >= 0 then
            if d = SOME ~1 andalso length vs = ctr_pos then
              list_comb (permute_args ctr_pos (snd_const pT), vs)
            else if length vs > ctr_pos andalso is_some d
                andalso d = try (fn Bound n => n) (nth vs ctr_pos) then
              list_comb (snd_const pT $ nth vs ctr_pos, map (subst d) (nth_drop ctr_pos vs))
            else
              primrec_error_eqn ("recursive call not directly applied to constructor argument") t
          else
            list_comb (u, map (subst (d |> d = SOME ~1 ? K NONE)) vs)
        end
  in
    subst (SOME ~1)
  end;

fun subst_rec_calls lthy get_ctr_pos has_call ctr_args mutual_calls nested_calls =
  let
    fun try_nested_rec bound_Ts y t =
      AList.lookup (op =) nested_calls y
      |> Option.map (fn y' =>
        massage_nested_rec_call lthy has_call (rewrite_map_arg get_ctr_pos) bound_Ts y y' t);

    fun subst bound_Ts (t as g' $ y) =
        let
          fun subst_rec () = subst bound_Ts g' $ subst bound_Ts y;
          val y_head = head_of y;
        in
          if not (member (op =) ctr_args y_head) then
            subst_rec ()
          else
            (case try_nested_rec bound_Ts y_head t of
              SOME t' => t'
            | NONE =>
              let val (g, g_args) = strip_comb g' in
                (case try (get_ctr_pos o fst o dest_Free) g of
                  SOME ctr_pos =>
                  (length g_args >= ctr_pos orelse
                   primrec_error_eqn "too few arguments in recursive call" t;
                   (case AList.lookup (op =) mutual_calls y of
                     SOME y' => list_comb (y', g_args)
                   | NONE => subst_rec ()))
                | NONE => subst_rec ())
              end)
        end
      | subst bound_Ts (Abs (v, T, b)) = Abs (v, T, subst (T :: bound_Ts) b)
      | subst _ t = t

    fun subst' t =
      if has_call t then
        (* FIXME detect this case earlier? *)
        primrec_error_eqn "recursive call not directly applied to constructor argument" t
      else
        try_nested_rec [] (head_of t) t |> the_default t
  in
    subst' o subst []
  end;

fun build_rec_arg lthy (funs_data : eqn_data list list) has_call (ctr_spec : rec_ctr_spec)
    (eqn_data_opt : eqn_data option) =
  (case eqn_data_opt of
    NONE => undef_const
  | SOME {ctr_args, left_args, right_args, rhs_term = t, ...} =>
    let
      val calls = #calls ctr_spec;
      val n_args = fold (Integer.add o (fn Mutual_Rec _ => 2 | _ => 1)) calls 0;

      val no_calls' = tag_list 0 calls
        |> map_filter (try (apsnd (fn No_Rec p => p | Mutual_Rec (p, _) => p)));
      val mutual_calls' = tag_list 0 calls
        |> map_filter (try (apsnd (fn Mutual_Rec (_, p) => p)));
      val nested_calls' = tag_list 0 calls
        |> map_filter (try (apsnd (fn Nested_Rec p => p)));

      fun ensure_unique frees t =
        if member (op =) frees t then Free (the_single (Term.variant_frees t [dest_Free t])) else t;

      val args = replicate n_args ("", dummyT)
        |> Term.rename_wrt_term t
        |> map Free
        |> fold (fn (ctr_arg_idx, (arg_idx, _)) =>
            nth_map arg_idx (K (nth ctr_args ctr_arg_idx)))
          no_calls'
        |> fold (fn (ctr_arg_idx, (arg_idx, T)) => fn xs =>
            nth_map arg_idx (K (ensure_unique xs (retype_free T (nth ctr_args ctr_arg_idx)))) xs)
          mutual_calls'
        |> fold (fn (ctr_arg_idx, (arg_idx, T)) =>
            nth_map arg_idx (K (retype_free T (nth ctr_args ctr_arg_idx))))
          nested_calls';

      val fun_name_ctr_pos_list =
        map (fn (x :: _) => (#fun_name x, length (#left_args x))) funs_data;
      val get_ctr_pos = try (the o AList.lookup (op =) fun_name_ctr_pos_list) #> the_default ~1;
      val mutual_calls = map (apfst (nth ctr_args) o apsnd (nth args o fst)) mutual_calls';
      val nested_calls = map (apfst (nth ctr_args) o apsnd (nth args o fst)) nested_calls';
    in
      t
      |> subst_rec_calls lthy get_ctr_pos has_call ctr_args mutual_calls nested_calls
      |> fold_rev lambda (args @ left_args @ right_args)
    end);

fun build_defs lthy bs mxs (funs_data : eqn_data list list) (rec_specs : rec_spec list) has_call =
  let
    val n_funs = length funs_data;

    val ctr_spec_eqn_data_list' =
      (take n_funs rec_specs |> map #ctr_specs) ~~ funs_data
      |> maps (uncurry (finds (fn (x, y) => #ctr x = #ctr y))
          ##> (fn x => null x orelse
            primrec_error_eqns "excess equations in definition" (map #rhs_term x)) #> fst);
    val _ = ctr_spec_eqn_data_list' |> map (fn (_, x) => length x <= 1 orelse
      primrec_error_eqns ("multiple equations for constructor") (map #user_eqn x));

    val ctr_spec_eqn_data_list =
      ctr_spec_eqn_data_list' @ (drop n_funs rec_specs |> maps #ctr_specs |> map (rpair []));

    val recs = take n_funs rec_specs |> map #recx;
    val rec_args = ctr_spec_eqn_data_list
      |> sort ((op <) o pairself (#offset o fst) |> make_ord)
      |> map (uncurry (build_rec_arg lthy funs_data has_call) o apsnd (try the_single));
    val ctr_poss = map (fn x =>
      if length (distinct ((op =) o pairself (length o #left_args)) x) <> 1 then
        primrec_error ("inconstant constructor pattern position for function " ^
          quote (#fun_name (hd x)))
      else
        hd x |> #left_args |> length) funs_data;
  in
    (recs, ctr_poss)
    |-> map2 (fn recx => fn ctr_pos => list_comb (recx, rec_args) |> permute_args ctr_pos)
    |> Syntax.check_terms lthy
    |> map3 (fn b => fn mx => fn t => ((b, mx), ((Binding.conceal (Thm.def_binding b), []), t)))
      bs mxs
  end;

fun find_rec_calls has_call ({ctr, ctr_args, rhs_term, ...} : eqn_data) =
  let
    fun find bound_Ts (Abs (_, T, b)) ctr_arg = find (T :: bound_Ts) b ctr_arg
      | find bound_Ts (t as _ $ _) ctr_arg =
        let
          val typof = curry fastype_of1 bound_Ts;
          val (f', args') = strip_comb t;
          val n = find_index (equal ctr_arg o head_of) args';
        in
          if n < 0 then
            find bound_Ts f' ctr_arg @ maps (fn x => find bound_Ts x ctr_arg) args'
          else
            let
              val (f, args as arg :: _) = chop n args' |>> curry list_comb f'
              val (arg_head, arg_args) = Term.strip_comb arg;
            in
              if has_call f then
                mk_partial_compN (length arg_args) (typof arg_head) f ::
                maps (fn x => find bound_Ts x ctr_arg) args
              else
                find bound_Ts f ctr_arg @ maps (fn x => find bound_Ts x ctr_arg) args
            end
        end
      | find _ _ _ = [];
  in
    map (find [] rhs_term) ctr_args
    |> (fn [] => NONE | callss => SOME (ctr, callss))
  end;

fun mk_primrec_tac ctxt num_extra_args map_idents map_comps fun_defs recx =
  unfold_thms_tac ctxt fun_defs THEN
  HEADGOAL (rtac (funpow num_extra_args (fn thm => thm RS fun_cong) recx RS trans)) THEN
  unfold_thms_tac ctxt (@{thms id_def split comp_def fst_conv snd_conv} @ map_comps @
    map_idents) THEN
  HEADGOAL (rtac refl);

fun prepare_primrec fixes specs lthy =
  let
    val thy = Proof_Context.theory_of lthy;

    val (bs, mxs) = map_split (apfst fst) fixes;
    val fun_names = map Binding.name_of bs;
    val eqns_data = map (dissect_eqn lthy fun_names) specs;
    val funs_data = eqns_data
      |> partition_eq ((op =) o pairself #fun_name)
      |> finds (fn (x, y) => x = #fun_name (hd y)) fun_names |> fst
      |> map (fn (x, y) => the_single y handle List.Empty =>
          primrec_error ("missing equations for function " ^ quote x));

    val has_call = exists_subterm (map (fst #>> Binding.name_of #> Free) fixes |> member (op =));
    val arg_Ts = map (#rec_type o hd) funs_data;
    val res_Ts = map (#res_type o hd) funs_data;
    val callssss = funs_data
      |> map (partition_eq ((op =) o pairself #ctr))
      |> map (maps (map_filter (find_rec_calls has_call)));

    val _ = (case filter_out (fn (_, T) => Sign.of_sort thy (T, HOLogic.typeS)) (bs ~~ res_Ts) of
        [] => ()
      | (b, _) :: _ => primrec_error ("type of " ^ Binding.print b ^ " contains top sort"));

    val ((n2m, rec_specs, _, induct_thm, induct_thms), lthy') =
      rec_specs_of bs arg_Ts res_Ts (get_indices fixes) callssss lthy;

    val actual_nn = length funs_data;

    val _ = let val ctrs = (maps (map #ctr o #ctr_specs) rec_specs) in
      map (fn {ctr, user_eqn, ...} => member (op =) ctrs ctr orelse
        primrec_error_eqn ("argument " ^ quote (Syntax.string_of_term lthy' ctr) ^
          " is not a constructor in left-hand side") user_eqn) eqns_data end;

    val defs = build_defs lthy' bs mxs funs_data rec_specs has_call;

    fun prove lthy def_thms' ({ctr_specs, nested_map_idents, nested_map_comps, ...} : rec_spec)
        (fun_data : eqn_data list) =
      let
        val def_thms = map (snd o snd) def_thms';
        val simp_thmss = finds (fn (x, y) => #ctr x = #ctr y) fun_data ctr_specs
          |> fst
          |> map_filter (try (fn (x, [y]) =>
            (#user_eqn x, length (#left_args x) + length (#right_args x), #rec_thm y)))
          |> map (fn (user_eqn, num_extra_args, rec_thm) =>
            mk_primrec_tac lthy num_extra_args nested_map_idents nested_map_comps def_thms rec_thm
            |> K |> Goal.prove_sorry lthy [] [] user_eqn
            |> Thm.close_derivation);
        val poss = find_indices (op = o pairself #ctr) fun_data eqns_data;
      in
        (poss, simp_thmss)
      end;

    val notes =
      (if n2m then map2 (fn name => fn thm =>
        (name, inductN, [thm], [])) fun_names (take actual_nn induct_thms) else [])
      |> map (fn (prefix, thmN, thms, attrs) =>
        ((Binding.qualify true prefix (Binding.name thmN), attrs), [(thms, [])]));

    val common_name = mk_common_name fun_names;

    val common_notes =
      (if n2m then [(inductN, [induct_thm], [])] else [])
      |> map (fn (thmN, thms, attrs) =>
        ((Binding.qualify true common_name (Binding.name thmN), attrs), [(thms, [])]));
  in
    (((fun_names, defs),
      fn lthy => fn defs =>
        split_list (map2 (prove lthy defs) (take actual_nn rec_specs) funs_data)),
      lthy' |> Local_Theory.notes (notes @ common_notes) |> snd)
  end;

(* primrec definition *)

fun add_primrec_simple fixes ts lthy =
  let
    val (((names, defs), prove), lthy) = prepare_primrec fixes ts lthy
      handle ERROR str => primrec_error str;
  in
    lthy
    |> fold_map Local_Theory.define defs
    |-> (fn defs => `(fn lthy => (names, (map fst defs, prove lthy defs))))
  end
  handle Primrec_Error (str, eqns) =>
    if null eqns
    then error ("primrec_new error:\n  " ^ str)
    else error ("primrec_new error:\n  " ^ str ^ "\nin\n  " ^
      space_implode "\n  " (map (quote o Syntax.string_of_term lthy) eqns));

local

fun gen_primrec prep_spec (raw_fixes : (binding * 'a option * mixfix) list) raw_spec lthy =
  let
    val d = duplicates (op =) (map (Binding.name_of o #1) raw_fixes)
    val _ = null d orelse primrec_error ("duplicate function name(s): " ^ commas d);

    val (fixes, specs) = fst (prep_spec raw_fixes raw_spec lthy);

    val mk_notes =
      flat ooo map3 (fn poss => fn prefix => fn thms =>
        let
          val (bs, attrss) = map_split (fst o nth specs) poss;
          val notes =
            map3 (fn b => fn attrs => fn thm =>
              ((Binding.qualify false prefix b, code_nitpicksimp_simp_attrs @ attrs), [([thm], [])]))
            bs attrss thms;
        in
          ((Binding.qualify true prefix (Binding.name simpsN), []), [(thms, [])]) :: notes
        end);
  in
    lthy
    |> add_primrec_simple fixes (map snd specs)
    |-> (fn (names, (ts, (posss, simpss))) =>
      Spec_Rules.add Spec_Rules.Equational (ts, flat simpss)
      #> Local_Theory.notes (mk_notes posss names simpss)
      #>> pair ts o map snd)
  end;

in

val add_primrec = gen_primrec Specification.check_spec;
val add_primrec_cmd = gen_primrec Specification.read_spec;

end;

fun add_primrec_global fixes specs thy =
  let
    val lthy = Named_Target.theory_init thy;
    val ((ts, simps), lthy') = add_primrec fixes specs lthy;
    val simps' = burrow (Proof_Context.export lthy' lthy) simps;
  in ((ts, simps'), Local_Theory.exit_global lthy') end;

fun add_primrec_overloaded ops fixes specs thy =
  let
    val lthy = Overloading.overloading ops thy;
    val ((ts, simps), lthy') = add_primrec fixes specs lthy;
    val simps' = burrow (Proof_Context.export lthy' lthy) simps;
  in ((ts, simps'), Local_Theory.exit_global lthy') end;

end;