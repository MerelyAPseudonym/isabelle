(*  Title:      TFL/usyntax
    ID:         $Id$
    Author:     Konrad Slind, Cambridge University Computer Laboratory
    Copyright   1997  University of Cambridge

Emulation of HOL's abstract syntax functions
*)

structure USyntax : USyntax_sig =
struct

structure Utils = Utils;
open Utils;
open Mask;

infix 7 |->;
infix 4 ##;

fun ERR{func,mesg} = Utils.ERR{module = "USyntax", func = func, mesg = mesg};


(*---------------------------------------------------------------------------
 *
 *                            Types 
 *
 *---------------------------------------------------------------------------*)
val mk_prim_vartype = TVar;
fun mk_vartype s = mk_prim_vartype((s,0),["term"]);

(* But internally, it's useful *)
fun dest_vtype (TVar x) = x
  | dest_vtype _ = raise ERR{func = "dest_vtype", 
                             mesg = "not a flexible type variable"};

val is_vartype = Utils.can dest_vtype;

val type_vars  = map mk_prim_vartype o typ_tvars
fun type_varsl L = Utils.mk_set (curry op=)
                      (Utils.rev_itlist (curry op @ o type_vars) L []);

val alpha  = mk_vartype "'a"
val beta   = mk_vartype "'b"

fun match_type ty1 ty2 = raise ERR{func="match_type",mesg="not implemented"};


(* What nonsense *)
nonfix -->; 
val --> = -->;
infixr 3 -->;

fun strip_type ty = (binder_types ty, body_type ty);

fun strip_prod_type (Type("*", [ty1,ty2])) =
	strip_prod_type ty1 @ strip_prod_type ty2
  | strip_prod_type ty = [ty];



(*---------------------------------------------------------------------------
 *
 *                              Terms 
 *
 *---------------------------------------------------------------------------*)
nonfix aconv;
val aconv = curry (op aconv);

fun free_vars tm = add_term_frees(tm,[]);


(* Free variables, in order of occurrence, from left to right in the 
 * syntax tree. *)
fun free_vars_lr tm = 
  let fun memb x = let fun m[] = false | m(y::rst) = (x=y)orelse m rst in m end
      fun add (t, frees) = case t of
            Free   _ => if (memb t frees) then frees else t::frees
          | Abs (_,_,body) => add(body,frees)
          | f$t =>  add(t, add(f, frees))
          | _ => frees
  in rev(add(tm,[]))
  end;



fun free_varsl L = Utils.mk_set aconv
                      (Utils.rev_itlist (curry op @ o free_vars) L []);

val type_vars_in_term = map mk_prim_vartype o term_tvars;

(* Can't really be very exact in Isabelle *)
fun all_vars tm = 
  let fun memb x = let fun m[] = false | m(y::rst) = (x=y)orelse m rst in m end
      fun add (t, A) = case t of
            Free   _ => if (memb t A) then A else t::A
          | Abs (s,ty,body) => add(body, add(Free(s,ty),A))
          | f$t =>  add(t, add(f, A))
          | _ => A
  in rev(add(tm,[]))
  end;
fun all_varsl L = Utils.mk_set aconv
                      (Utils.rev_itlist (curry op @ o all_vars) L []);


(* Prelogic *)
val subst = subst_free o map (fn (a |-> b) => (a,b));

fun dest_tybinding (v |-> ty) = (#1(dest_vtype v),ty)
fun inst theta = subst_vars (map dest_tybinding theta,[])

fun beta_conv((t1 as Abs _ ) $ t2) = betapply(t1,t2)
  | beta_conv _ = raise ERR{func = "beta_conv", mesg = "Not a beta-redex"};


(* Construction routines *)
fun mk_var{Name,Ty} = Free(Name,Ty);
val mk_prim_var = Var;

val string_variant = variant;

local fun var_name(Var((Name,_),_)) = Name
        | var_name(Free(s,_)) = s
        | var_name _ = raise ERR{func = "variant",
                                 mesg = "list elem. is not a variable"}
in
fun variant [] v = v
  | variant vlist (Var((Name,i),ty)) = 
       Var((string_variant (map var_name vlist) Name,i),ty)
  | variant vlist (Free(Name,ty)) =
       Free(string_variant (map var_name vlist) Name,ty)
  | variant _ _ = raise ERR{func = "variant",
                            mesg = "2nd arg. should be a variable"}
end;

fun mk_const{Name,Ty} = Const(Name,Ty)
fun mk_comb{Rator,Rand} = Rator $ Rand;

fun mk_abs{Bvar as Var((s,_),ty),Body}  = Abs(s,ty,abstract_over(Bvar,Body))
  | mk_abs{Bvar as Free(s,ty),Body}  = Abs(s,ty,abstract_over(Bvar,Body))
  | mk_abs _ = raise ERR{func = "mk_abs", mesg = "Bvar is not a variable"};


fun mk_imp{ant,conseq} = 
   let val c = mk_const{Name = "op -->", Ty = HOLogic.boolT --> HOLogic.boolT --> HOLogic.boolT}
   in list_comb(c,[ant,conseq])
   end;

fun mk_select (r as {Bvar,Body}) = 
  let val ty = type_of Bvar
      val c = mk_const{Name = "Eps", Ty = (ty --> HOLogic.boolT) --> ty}
  in list_comb(c,[mk_abs r])
  end;

fun mk_forall (r as {Bvar,Body}) = 
  let val ty = type_of Bvar
      val c = mk_const{Name = "All", Ty = (ty --> HOLogic.boolT) --> HOLogic.boolT}
  in list_comb(c,[mk_abs r])
  end;

fun mk_exists (r as {Bvar,Body}) = 
  let val ty = type_of Bvar 
      val c = mk_const{Name = "Ex", Ty = (ty --> HOLogic.boolT) --> HOLogic.boolT}
  in list_comb(c,[mk_abs r])
  end;


fun mk_conj{conj1,conj2} =
   let val c = mk_const{Name = "op &", Ty = HOLogic.boolT --> HOLogic.boolT --> HOLogic.boolT}
   in list_comb(c,[conj1,conj2])
   end;

fun mk_disj{disj1,disj2} =
   let val c = mk_const{Name = "op |", Ty = HOLogic.boolT --> HOLogic.boolT --> HOLogic.boolT}
   in list_comb(c,[disj1,disj2])
   end;

fun prod_ty ty1 ty2 = Type("*", [ty1,ty2]);

local
fun mk_uncurry(xt,yt,zt) =
    mk_const{Name = "split", Ty = (xt --> yt --> zt) --> prod_ty xt yt --> zt}
fun dest_pair(Const("Pair",_) $ M $ N) = {fst=M, snd=N}
  | dest_pair _ = raise ERR{func = "dest_pair", mesg = "not a pair"}
fun is_var(Var(_)) = true | is_var (Free _) = true | is_var _ = false
in
fun mk_pabs{varstruct,body} = 
 let fun mpa(varstruct,body) =
       if (is_var varstruct)
       then mk_abs{Bvar = varstruct, Body = body}
       else let val {fst,snd} = dest_pair varstruct
            in mk_comb{Rator= mk_uncurry(type_of fst,type_of snd,type_of body),
                       Rand = mpa(fst,mpa(snd,body))}
            end
 in mpa(varstruct,body)
 end
 handle _ => raise ERR{func = "mk_pabs", mesg = ""};
end;

(* Destruction routines *)

datatype lambda = VAR   of {Name : string, Ty : typ}
                | CONST of {Name : string, Ty : typ}
                | COMB  of {Rator: term, Rand : term}
                | LAMB  of {Bvar : term, Body : term};


fun dest_term(Var((s,i),ty)) = VAR{Name = s, Ty = ty}
  | dest_term(Free(s,ty))    = VAR{Name = s, Ty = ty}
  | dest_term(Const(s,ty))   = CONST{Name = s, Ty = ty}
  | dest_term(M$N)           = COMB{Rator=M,Rand=N}
  | dest_term(Abs(s,ty,M))   = let  val v = mk_var{Name = s, Ty = ty}
                               in LAMB{Bvar = v, Body = betapply (M,v)}
                               end
  | dest_term(Bound _)       = raise ERR{func = "dest_term",mesg = "Bound"};

fun dest_var(Var((s,i),ty)) = {Name = s, Ty = ty}
  | dest_var(Free(s,ty))    = {Name = s, Ty = ty}
  | dest_var _ = raise ERR{func = "dest_var", mesg = "not a variable"};

fun dest_const(Const(s,ty)) = {Name = s, Ty = ty}
  | dest_const _ = raise ERR{func = "dest_const", mesg = "not a constant"};

fun dest_comb(t1 $ t2) = {Rator = t1, Rand = t2}
  | dest_comb _ =  raise ERR{func = "dest_comb", mesg = "not a comb"};

fun dest_abs(a as Abs(s,ty,M)) = 
     let val v = mk_var{Name = s, Ty = ty}
     in {Bvar = v, Body = betapply (a,v)}
     end
  | dest_abs _ =  raise ERR{func = "dest_abs", mesg = "not an abstraction"};

fun dest_eq(Const("op =",_) $ M $ N) = {lhs=M, rhs=N}
  | dest_eq _ = raise ERR{func = "dest_eq", mesg = "not an equality"};

fun dest_imp(Const("op -->",_) $ M $ N) = {ant=M, conseq=N}
  | dest_imp _ = raise ERR{func = "dest_imp", mesg = "not an implication"};

fun dest_select(Const("Eps",_) $ (a as Abs _)) = dest_abs a
  | dest_select _ = raise ERR{func = "dest_select", mesg = "not a select"};

fun dest_forall(Const("All",_) $ (a as Abs _)) = dest_abs a
  | dest_forall _ = raise ERR{func = "dest_forall", mesg = "not a forall"};

fun dest_exists(Const("Ex",_) $ (a as Abs _)) = dest_abs a
  | dest_exists _ = raise ERR{func = "dest_exists", mesg="not an existential"};

fun dest_neg(Const("not",_) $ M) = M
  | dest_neg _ = raise ERR{func = "dest_neg", mesg = "not a negation"};

fun dest_conj(Const("op &",_) $ M $ N) = {conj1=M, conj2=N}
  | dest_conj _ = raise ERR{func = "dest_conj", mesg = "not a conjunction"};

fun dest_disj(Const("op |",_) $ M $ N) = {disj1=M, disj2=N}
  | dest_disj _ = raise ERR{func = "dest_disj", mesg = "not a disjunction"};

fun mk_pair{fst,snd} = 
   let val ty1 = type_of fst
       val ty2 = type_of snd
       val c = mk_const{Name = "Pair", Ty = ty1 --> ty2 --> prod_ty ty1 ty2}
   in list_comb(c,[fst,snd])
   end;

fun dest_pair(Const("Pair",_) $ M $ N) = {fst=M, snd=N}
  | dest_pair _ = raise ERR{func = "dest_pair", mesg = "not a pair"};


local  fun ucheck t = (if #Name(dest_const t) = "split" then t
                       else raise Match)
in
fun dest_pabs tm =
   let val {Bvar,Body} = dest_abs tm
   in {varstruct = Bvar, body = Body}
   end 
    handle 
     _ => let val {Rator,Rand} = dest_comb tm
              val _ = ucheck Rator
              val {varstruct = lv,body} = dest_pabs Rand
              val {varstruct = rv,body} = dest_pabs body
          in {varstruct = mk_pair{fst = lv, snd = rv}, body = body}
          end
end;


(* Garbage - ought to be dropped *)
val lhs   = #lhs o dest_eq
val rhs   = #rhs o dest_eq
val rator = #Rator o dest_comb
val rand  = #Rand o dest_comb
val bvar  = #Bvar o dest_abs
val body  = #Body o dest_abs
  

(* Query routines *)
val is_var    = can dest_var
val is_const  = can dest_const
val is_comb   = can dest_comb
val is_abs    = can dest_abs
val is_eq     = can dest_eq
val is_imp    = can dest_imp
val is_forall = can dest_forall
val is_exists = can dest_exists
val is_neg    = can dest_neg
val is_conj   = can dest_conj
val is_disj   = can dest_disj
val is_pair   = can dest_pair
val is_pabs   = can dest_pabs


(* Construction of a cterm from a list of Terms *)

fun list_mk_abs(L,tm) = itlist (fn v => fn M => mk_abs{Bvar=v, Body=M}) L tm;

(* These others are almost never used *)
fun list_mk_imp(A,c) = itlist(fn a => fn tm => mk_imp{ant=a,conseq=tm}) A c;
fun list_mk_exists(V,t) = itlist(fn v => fn b => mk_exists{Bvar=v, Body=b})V t;
fun list_mk_forall(V,t) = itlist(fn v => fn b => mk_forall{Bvar=v, Body=b})V t;
val list_mk_conj = end_itlist(fn c1 => fn tm => mk_conj{conj1=c1, conj2=tm})
val list_mk_disj = end_itlist(fn d1 => fn tm => mk_disj{disj1=d1, disj2=tm})


(* Need to reverse? *)
fun gen_all tm = list_mk_forall(free_vars tm, tm);

(* Destructing a cterm to a list of Terms *)
fun strip_comb tm = 
   let fun dest(M$N, A) = dest(M, N::A)
         | dest x = x
   in dest(tm,[])
   end;

fun strip_abs(tm as Abs _) =
       let val {Bvar,Body} = dest_abs tm
           val (bvs, core) = strip_abs Body
       in (Bvar::bvs, core)
       end
  | strip_abs M = ([],M);


fun strip_imp fm =
   if (is_imp fm)
   then let val {ant,conseq} = dest_imp fm
            val (was,wb) = strip_imp conseq
        in ((ant::was), wb)
        end
   else ([],fm);

fun strip_forall fm =
   if (is_forall fm)
   then let val {Bvar,Body} = dest_forall fm
            val (bvs,core) = strip_forall Body
        in ((Bvar::bvs), core)
        end
   else ([],fm);


fun strip_exists fm =
   if (is_exists fm)
   then let val {Bvar, Body} = dest_exists fm 
            val (bvs,core) = strip_exists Body
        in (Bvar::bvs, core)
        end
   else ([],fm);

fun strip_conj w = 
   if (is_conj w)
   then let val {conj1,conj2} = dest_conj w
        in (strip_conj conj1@strip_conj conj2)
        end
   else [w];

fun strip_disj w =
   if (is_disj w)
   then let val {disj1,disj2} = dest_disj w 
        in (strip_disj disj1@strip_disj disj2)
        end
   else [w];

fun strip_pair tm = 
   if (is_pair tm) 
   then let val {fst,snd} = dest_pair tm
            fun dtuple t =
               if (is_pair t)
               then let val{fst,snd} = dest_pair t
                    in (fst :: dtuple snd)
                    end
               else [t]
        in fst::dtuple snd
        end
   else [tm];


fun mk_preterm tm = #t(rep_cterm tm);

(* Miscellaneous *)

fun mk_vstruct ty V =
  let fun follow_prod_type (Type("*",[ty1,ty2])) vs =
	      let val (ltm,vs1) = follow_prod_type ty1 vs
		  val (rtm,vs2) = follow_prod_type ty2 vs1
	      in (mk_pair{fst=ltm, snd=rtm}, vs2) end
	| follow_prod_type _ (v::vs) = (v,vs)
  in #1 (follow_prod_type ty V)  end;


(* Search a term for a sub-term satisfying the predicate p. *)
fun find_term p =
   let fun find tm =
      if (p tm)
      then tm 
      else if (is_abs tm)
           then find (#Body(dest_abs tm))
           else let val {Rator,Rand} = dest_comb tm
                in find Rator handle _ => find Rand
                end handle _ => raise ERR{func = "find_term",mesg = ""}
   in find
   end;

(*******************************************************************
 * find_terms: (term -> HOLogic.boolT) -> term -> term list
 * 
 *  Find all subterms in a term that satisfy a given predicate p.
 *
 *******************************************************************)
fun find_terms p =
   let fun accum tl tm =
      let val tl' = if (p tm) then (tm::tl) else tl 
      in if (is_abs tm)
         then accum tl' (#Body(dest_abs tm))
         else let val {Rator,Rand} = dest_comb tm
              in accum (accum tl' Rator) Rand
              end handle _ => tl'
      end
   in accum []
   end;


val Term_to_string = string_of_cterm;

fun dest_relation tm =
   if (type_of tm = HOLogic.boolT)
   then let val (Const("op :",_) $ (Const("Pair",_)$y$x) $ R) = tm
        in (R,y,x)
        end handle _ => raise ERR{func="dest_relation",
                                  mesg="unexpected term structure"}
   else raise ERR{func="dest_relation",mesg="not a boolean term"};

fun is_WFR tm = (#Name(dest_const(rator tm)) = "wf") handle _ => false;

fun ARB ty = mk_select{Bvar=mk_var{Name="v",Ty=ty},
                       Body=mk_const{Name="True",Ty=HOLogic.boolT}};

end; (* Syntax *)
