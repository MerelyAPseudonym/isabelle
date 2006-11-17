(*  Title:      HOL/Library/State_Monad.thy
    ID:         $Id$
    Author:     Florian Haftmann, TU Muenchen
*)

header {* Combinators syntax for generic, open state monads (single threaded monads) *}

theory State_Monad
imports Main
begin

section {* Generic, open state monads *}

subsection {* Motivation *}

text {*
  The logic HOL has no notion of constructor classes, so
  it is not possible to model monads the Haskell way
  in full genericity in Isabelle/HOL.
  
  However, this theory provides substantial support for
  a very common class of monads: \emph{state monads}
  (or \emph{single-threaded monads}, since a state
  is transformed single-threaded).

  To enter from the Haskell world,
  \url{http://www.engr.mun.ca/~theo/Misc/haskell_and_monads.htm}
  makes a good motivating start.  Here we just sketch briefly
  how those monads enter the game of Isabelle/HOL.
*}

subsection {* State transformations and combinators *}

(*<*)
typedecl \<alpha>
typedecl \<beta>
typedecl \<gamma>
typedecl \<sigma>
typedecl \<sigma>'
(*>*)

text {*
  We classify functions operating on states into two categories:

  \begin{description}
    \item[transformations]
      with type signature @{typ "\<sigma> \<Rightarrow> \<sigma>'"},
      transforming a state.
    \item[``yielding'' transformations]
      with type signature @{typ "\<sigma> \<Rightarrow> \<alpha> \<times> \<sigma>'"},
      ``yielding'' a side result while transforming a state.
    \item[queries]
      with type signature @{typ "\<sigma> \<Rightarrow> \<alpha>"},
      computing a result dependent on a state.
  \end{description}

  By convention we write @{typ "\<sigma>"} for types representing states
  and @{typ "\<alpha>"}, @{typ "\<beta>"}, @{typ "\<gamma>"}, @{text "\<dots>"}
  for types representing side results.  Type changes due
  to transformations are not excluded in our scenario.

  We aim to assert that values of any state type @{typ "\<sigma>"}
  are used in a single-threaded way: after application
  of a transformation on a value of type @{typ "\<sigma>"}, the
  former value should not be used again.  To achieve this,
  we use a set of monad combinators:
*}

definition
  mbind :: "('a \<Rightarrow> 'b \<times> 'c) \<Rightarrow> ('b \<Rightarrow> 'c \<Rightarrow> 'd) \<Rightarrow> 'a \<Rightarrow> 'd"
    (infixl ">>=" 60) where
  "f >>= g = split g \<circ> f"

definition
  fcomp :: "('a \<Rightarrow> 'b) \<Rightarrow> ('b \<Rightarrow> 'c) \<Rightarrow> 'a \<Rightarrow> 'c"
    (infixl ">>" 60) where
  "f >> g = g \<circ> f"

definition
  run :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'b" where
  "run f = f"

print_ast_translation {*[
  (Sign.const_syntax_name (the_context ()) "State_Monad.run", fn (f::ts) => Syntax.mk_appl f ts)
]*}

syntax (xsymbols)
  mbind :: "('a \<Rightarrow> 'b \<times> 'c) \<Rightarrow> ('b \<Rightarrow> 'c \<Rightarrow> 'd) \<Rightarrow> 'a \<Rightarrow> 'd"
    (infixl "\<guillemotright>=" 60)
  fcomp :: "('a \<Rightarrow> 'b) \<Rightarrow> ('b \<Rightarrow> 'c) \<Rightarrow> 'a \<Rightarrow> 'c"
    (infixl "\<guillemotright>" 60)

abbreviation (input)
  "return \<equiv> Pair"

text {*
  Given two transformations @{term f} and @{term g}, they
  may be directly composed using the @{term "op \<guillemotright>"} combinator,
  forming a forward composition: @{prop "(f \<guillemotright> g) s = f (g s)"}.

  After any yielding transformation, we bind the side result
  immediately using a lambda abstraction.  This 
  is the purpose of the @{term "op \<guillemotright>="} combinator:
  @{prop "(f \<guillemotright>= (\<lambda>x. g)) s = (let (x, s') = f s in g s')"}.

  For queries, the existing @{term "Let"} is appropriate.

  Naturally, a computation may yield a side result by pairing
  it to the state from the left;  we introduce the
  suggestive abbreviation @{term return} for this purpose.

  The @{const run} ist just a marker.

  The most crucial distinction to Haskell is that we do
  not need to introduce distinguished type constructors
  for different kinds of state.  This has two consequences:
  \begin{itemize}
    \item The monad model does not state anything about
       the kind of state; the model for the state is
       completely orthogonal and has to (or may) be
       specified completely independent.
    \item There is no distinguished type constructor
       encapsulating away the state transformation, i.e.~transformations
       may be applied directly without using any lifting
       or providing and dropping units (``open monad'').
    \item The type of states may change due to a transformation.
  \end{itemize}
*}


subsection {* Obsolete runs *}

text {*
  @{term run} is just a doodle and should not occur nested:
*}

lemma run_simp [simp]:
  "\<And>f. run (run f) = run f"
  "\<And>f g. run f \<guillemotright>= g = f \<guillemotright>= g"
  "\<And>f g. run f \<guillemotright> g = f \<guillemotright> g"
  "\<And>f g. f \<guillemotright>= (\<lambda>x. run g) = f \<guillemotright>= (\<lambda>x. g)"
  "\<And>f g. f \<guillemotright> run g = f \<guillemotright> g"
  "\<And>f. f = run f \<longleftrightarrow> True"
  "\<And>f. run f = f \<longleftrightarrow> True"
  unfolding run_def by rule+


subsection {* Monad laws *}

text {*
  The common monadic laws hold and may also be used
  as normalization rules for monadic expressions:
*}

lemma
  return_mbind [simp]: "return x \<guillemotright>= f = f x"
  unfolding mbind_def by (simp add: expand_fun_eq)

lemma
  mbind_return [simp]: "x \<guillemotright>= return = x"
  unfolding mbind_def by (simp add: expand_fun_eq split_Pair)

lemma
  mbind_mbind [simp]: "(f \<guillemotright>= g) \<guillemotright>= h = f \<guillemotright>= (\<lambda>x. g x \<guillemotright>= h)"
  unfolding mbind_def by (simp add: split_def expand_fun_eq)

lemma
  mbind_fcomp [simp]: "(f \<guillemotright>= g) \<guillemotright> h = f \<guillemotright>= (\<lambda>x. g x \<guillemotright> h)"
  unfolding mbind_def fcomp_def by (simp add: split_def expand_fun_eq)

lemma
  fcomp_mbind [simp]: "(f \<guillemotright> g) \<guillemotright>= h = f \<guillemotright> (g \<guillemotright>= h)"
  unfolding mbind_def fcomp_def by (simp add: split_def expand_fun_eq)

lemma
  fcomp_fcomp [simp]: "(f \<guillemotright> g) \<guillemotright> h = f \<guillemotright> (g \<guillemotright> h)"
  unfolding fcomp_def o_assoc ..

lemmas monad_simp = run_simp return_mbind mbind_return
  mbind_mbind mbind_fcomp fcomp_mbind fcomp_fcomp

text {*
  Evaluation of monadic expressions by force:
*}

lemmas monad_collapse = monad_simp o_apply o_assoc split_Pair split_comp
  mbind_def fcomp_def run_def

subsection {* Syntax *}

text {*
  We provide a convenient do-notation for monadic expressions
  well-known from Haskell.  @{const Let} is printed
  specially in do-expressions.
*}

nonterminals do_expr

syntax
  "_do" :: "do_expr \<Rightarrow> 'a"
    ("do _ done" [12] 12)
  "_mbind" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("_ <- _;// _" [1000, 13, 12] 12)
  "_fcomp" :: "'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("_;// _" [13, 12] 12)
  "_let" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("let _ = _;// _" [1000, 13, 12] 12)
  "_nil" :: "'a \<Rightarrow> do_expr"
    ("_" [12] 12)

syntax (xsymbols)
  "_mbind" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("_ \<leftarrow> _;// _" [1000, 13, 12] 12)

translations
  "_do f" => "State_Monad.run f"
  "_mbind x f g" => "f \<guillemotright>= (\<lambda>x. g)"
  "_fcomp f g" => "f \<guillemotright> g"
  "_let x t f" => "Let t (\<lambda>x. f)"
  "_nil f" => "f"

print_translation {*
let
  val syntax_name = Sign.const_syntax_name (the_context ());
  val name_mbind = syntax_name "State_Monad.mbind";
  val name_fcomp = syntax_name "State_Monad.fcomp";
  fun unfold_monad (t as Const (name, _) $ f $ g) =
        if name = name_mbind then let
            val ([(v, ty)], g') = Term.strip_abs_eta 1 g;
          in Const ("_mbind", dummyT) $ Free (v, ty) $ f $ unfold_monad g' end
        else if name = name_fcomp then
          Const ("_fcomp", dummyT) $ f $ unfold_monad g
        else t
    | unfold_monad (Const ("Let", _) $ f $ g) =
        let
          
          val ([(v, ty)], g') = Term.strip_abs_eta 1 g;
        in Const ("_let", dummyT) $ Free (v, ty) $ f $ unfold_monad g' end
    | unfold_monad (Const ("Pair", _) $ f) =
        Const ("return", dummyT) $ f
    | unfold_monad f = f;
  fun tr' (f::ts) =
    list_comb (Const ("_do", dummyT) $ unfold_monad f, ts)
in [
  (syntax_name "State_Monad.run", tr')
] end;
*}

text {*
  For an example, see HOL/ex/CodeRandom.thy (more examples coming soon).
*}

end