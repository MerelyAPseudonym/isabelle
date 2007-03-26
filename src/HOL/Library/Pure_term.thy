(*  Title:      HOL/Library/Pure_term.thy
    ID:         $Id$
    Author:     Florian Haftmann, TU Muenchen
*)

header {* Embedding (a subset of) the Pure term algebra in HOL *}

theory Pure_term
imports MLString
begin

subsection {* Definitions *}

types vname = ml_string;
types "class" = ml_string;
types sort = "class list"

datatype "typ" =
    Type ml_string "typ list" (infix "{\<struct>}" 120)
  | TFix vname sort (infix "\<Colon>\<epsilon>" 117)

abbreviation
  Fun :: "typ \<Rightarrow> typ \<Rightarrow> typ" (infixr "\<rightarrow>" 115) where
  "ty1 \<rightarrow> ty2 \<equiv> Type (STR ''fun'') [ty1, ty2]"
abbreviation
  Funs :: "typ list \<Rightarrow> typ \<Rightarrow> typ" (infixr "{\<rightarrow>}" 115) where
  "tys {\<rightarrow>} ty \<equiv> foldr (op \<rightarrow>) tys ty"

datatype "term" =
    Const ml_string "typ" (infix "\<Colon>\<subseteq>" 112)
  | Fix   vname "typ" (infix ":\<epsilon>" 112)
  | App   "term" "term" (infixl "\<bullet>" 110)
  | Abs   "vname \<times> typ" "term" (infixr "\<mapsto>" 111)
  | Bnd   nat

abbreviation
  Apps :: "term \<Rightarrow> term list \<Rightarrow> term" (infixl "{\<bullet>}" 110) where
  "t {\<bullet>} ts \<equiv> foldl (op \<bullet>) t ts"
abbreviation
  Abss :: "(vname \<times> typ) list \<Rightarrow> term \<Rightarrow> term" (infixr "{\<mapsto>}" 111) where
  "vs {\<mapsto>} t \<equiv> foldr (op \<mapsto>) vs t"


subsection {* ML interface *}

ML {*
structure Pure_term =
struct

val mk_sort = HOLogic.mk_list @{typ class} o map MLString.mk;

fun mk_typ f (Type (tyco, tys)) =
      @{term Type} $ MLString.mk tyco
        $ HOLogic.mk_list @{typ typ} (map (mk_typ f) tys)
  | mk_typ f (TFree v) =
      f v;

fun mk_term f g (Const (c, ty)) =
      @{term Const} $ MLString.mk c $ g ty
  | mk_term f g (t1 $ t2) =
      @{term App} $ mk_term f g t1 $ mk_term f g t2
  | mk_term f g (Free v) = f v;

end;
*}


subsection {* Code generator setup *}

definition
  Bound :: "int \<Rightarrow> term"
where
  "Bound k = Bnd (nat k)"

lemma Bnd_Bound [code inline, code func]:
  "Bnd n = Bound (int n)"
  unfolding Bound_def by auto

definition
  Absp :: "vname \<Rightarrow> typ \<Rightarrow> term \<Rightarrow> term"
where
  "Absp v ty t = (v, ty) \<mapsto> t"

lemma Abs_Absp [code inline, code func]:
  "(op \<mapsto>) (v, ty) = Absp v ty"
  by rule (auto simp add: Absp_def)

definition
  "term_case' f g h k l = term_case f g h (\<lambda>(v, ty). k v ty) (\<lambda>n. l (int n))"

lemma term_case' [code inline, code func]:
  "term_case = (\<lambda>f g h k l. term_case' f g h (\<lambda>v ty. k (v, ty)) (\<lambda>v. l (nat v)))"
  unfolding term_case'_def by auto
  
code_datatype Const App Fix Absp Bound
lemmas [code func] = Bnd_Bound Abs_Absp

code_type "typ" and "term"
  (SML "Term.typ" and "Term.term")

code_const Type and TFix
  (SML "Term.Type/ (_, _)" and "Term.TFree/ (_, _)")

code_const Const and App and Fix
  and Absp and Bound
  (SML "Term.Const/ (_, _)" and "Term.$/ (_, _)" and "Term.Free/ (_, _)"
    and "Term.Abs/ (_, _, _)" and "Term.Bound/ (IntInf.toInt/ _)")

code_const term_rec and term_case and "size \<Colon> term \<Rightarrow> nat"
  (SML "!(_; _; _; _; _; raise Fail \"term'_rec\")"
    and "!(_; _; _; _; _; raise Fail \"term'_case\")"
    and "!(_; raise Fail \"size'_term\")")

code_reserved SML Term

end