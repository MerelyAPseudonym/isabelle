
(* $Id$ *)

theory logic imports base begin

chapter {* Primitive logic \label{ch:logic} *}

text {*
  The logical foundations of Isabelle/Isar are that of the Pure logic,
  which has been introduced as a natural-deduction framework in
  \cite{paulson700}.  This is essentially the same logic as ``@{text
  "\<lambda>HOL"}'' in the more abstract setting of Pure Type Systems (PTS)
  \cite{Barendregt-Geuvers:2001}, although there are some key
  differences in the specific treatment of simple types in
  Isabelle/Pure.

  Following type-theoretic parlance, the Pure logic consists of three
  levels of @{text "\<lambda>"}-calculus with corresponding arrows: @{text
  "\<Rightarrow>"} for syntactic function space (terms depending on terms), @{text
  "\<And>"} for universal quantification (proofs depending on terms), and
  @{text "\<Longrightarrow>"} for implication (proofs depending on proofs).

  Pure derivations are relative to a logical theory, which declares
  type constructors, term constants, and axioms.  Theory declarations
  support schematic polymorphism, which is strictly speaking outside
  the logic.\footnote{Incidently, this is the main logical reason, why
  the theory context @{text "\<Theta>"} is separate from the context @{text
  "\<Gamma>"} of the core calculus.}
*}


section {* Types \label{sec:types} *}

text {*
  The language of types is an uninterpreted order-sorted first-order
  algebra; types are qualified by ordered type classes.

  \medskip A \emph{type class} is an abstract syntactic entity
  declared in the theory context.  The \emph{subclass relation} @{text
  "c\<^isub>1 \<subseteq> c\<^isub>2"} is specified by stating an acyclic
  generating relation; the transitive closure is maintained
  internally.  The resulting relation is an ordering: reflexive,
  transitive, and antisymmetric.

  A \emph{sort} is a list of type classes written as @{text
  "{c\<^isub>1, \<dots>, c\<^isub>m}"}, which represents symbolic
  intersection.  Notationally, the curly braces are omitted for
  singleton intersections, i.e.\ any class @{text "c"} may be read as
  a sort @{text "{c}"}.  The ordering on type classes is extended to
  sorts according to the meaning of intersections: @{text
  "{c\<^isub>1, \<dots> c\<^isub>m} \<subseteq> {d\<^isub>1, \<dots>, d\<^isub>n}"} iff
  @{text "\<forall>j. \<exists>i. c\<^isub>i \<subseteq> d\<^isub>j"}.  The empty intersection
  @{text "{}"} refers to the universal sort, which is the largest
  element wrt.\ the sort order.  The intersections of all (finitely
  many) classes declared in the current theory are the minimal
  elements wrt.\ the sort order.

  \medskip A \emph{fixed type variable} is a pair of a basic name
  (starting with a @{text "'"} character) and a sort constraint.  For
  example, @{text "('a, s)"} which is usually printed as @{text
  "\<alpha>\<^isub>s"}.  A \emph{schematic type variable} is a pair of an
  indexname and a sort constraint.  For example, @{text "(('a, 0),
  s)"} which is usually printed as @{text "?\<alpha>\<^isub>s"}.

  Note that \emph{all} syntactic components contribute to the identity
  of type variables, including the sort constraint.  The core logic
  handles type variables with the same name but different sorts as
  different, although some outer layers of the system make it hard to
  produce anything like this.

  A \emph{type constructor} @{text "\<kappa>"} is a @{text "k"}-ary operator
  on types declared in the theory.  Type constructor application is
  usually written postfix as @{text "(FIXME)\<kappa>"}.  For @{text "k = 0"}
  the argument tuple is omitted, e.g.\ @{text "prop"} instead of
  @{text "()prop"}.  For @{text "k = 1"} the parentheses are omitted,
  e.g.\ @{text "\<alpha> list"} instead of @{text "(\<alpha>)list"}.  Further
  notation is provided for specific constructors, notably
  right-associative infix @{text "\<alpha> \<Rightarrow> \<beta>"} instead of @{text "(\<alpha>,
  \<beta>)fun"} constructor.
  
  A \emph{type} is defined inductively over type variables and type
  constructors as follows: @{text "\<tau> = \<alpha>\<^isub>s | ?\<alpha>\<^isub>s |
  (\<tau>\<^sub>1, \<dots>, \<tau>\<^sub>k)c"}.

  A \emph{type abbreviation} is a syntactic abbreviation of an
  arbitrary type expression of the theory.  Type abbreviations looks
  like type constructors at the surface, but are expanded before the
  core logic encounters them.

  A \emph{type arity} declares the image behavior of a type
  constructor wrt.\ the algebra of sorts: @{text "c :: (s\<^isub>1, \<dots>,
  s\<^isub>k)s"} means that @{text "(\<tau>\<^isub>1, \<dots>, \<tau>\<^isub>k)c"} is
  of sort @{text "s"} if each argument type @{text "\<tau>\<^isub>i"} is of
  sort @{text "s\<^isub>i"}.  Arity declarations are implicitly
  completed, i.e.\ @{text "c :: (\<^vec>s)c"} entails @{text "c ::
  (\<^vec>s)c'"} for any @{text "c' \<supseteq> c"}.

  \medskip The sort algebra is always maintained as \emph{coregular},
  which means that type arities are consistent with the subclass
  relation: for each type constructor @{text "c"} and classes @{text
  "c\<^isub>1 \<subseteq> c\<^isub>2"}, any arity @{text "c ::
  (\<^vec>s\<^isub>1)c\<^isub>1"} has a corresponding arity @{text "c
  :: (\<^vec>s\<^isub>2)c\<^isub>2"} where @{text "\<^vec>s\<^isub>1 \<subseteq>
  \<^vec>s\<^isub>2"} holds pointwise for all argument sorts.

  The key property of a coregular order-sorted algebra is that sort
  constraints may be always fulfilled in a most general fashion: for
  each type constructor @{text "c"} and sort @{text "s"} there is a
  most general vector of argument sorts @{text "(s\<^isub>1, \<dots>,
  s\<^isub>k)"} such that a type scheme @{text
  "(\<alpha>\<^bsub>s\<^isub>1\<^esub>, \<dots>, \<alpha>\<^bsub>s\<^isub>k\<^esub>)c"} is
  of sort @{text "s"}.  Consequently, the unification problem on the
  algebra of types has most general solutions (modulo renaming and
  equivalence of sorts).  Moreover, the usual type-inference algorithm
  will produce primary types as expected \cite{nipkow-prehofer}.
*}

text %mlref {*
  \begin{mldecls}
  @{index_ML_type class} \\
  @{index_ML_type sort} \\
  @{index_ML_type typ} \\
  @{index_ML_type arity} \\
  @{index_ML Sign.subsort: "theory -> sort * sort -> bool"} \\
  @{index_ML Sign.of_sort: "theory -> typ * sort -> bool"} \\
  @{index_ML Sign.add_types: "(bstring * int * mixfix) list -> theory -> theory"} \\
  @{index_ML Sign.add_tyabbrs_i: "
  (bstring * string list * typ * mixfix) list -> theory -> theory"} \\
  @{index_ML Sign.primitive_class: "string * class list -> theory -> theory"} \\
  @{index_ML Sign.primitive_classrel: "class * class -> theory -> theory"} \\
  @{index_ML Sign.primitive_arity: "arity -> theory -> theory"} \\
  \end{mldecls}

  \begin{description}

  \item @{ML_type class} represents type classes; this is an alias for
  @{ML_type string}.

  \item @{ML_type sort} represents sorts; this is an alias for
  @{ML_type "class list"}.

  \item @{ML_type arity} represents type arities; this is an alias for
  triples of the form @{text "(c, \<^vec>s, s)"} for @{text "c ::
  (\<^vec>s)s"} described above.

  \item @{ML_type typ} represents types; this is a datatype with
  constructors @{ML TFree}, @{ML TVar}, @{ML Type}.

  \item @{ML Sign.subsort}~@{text "thy (s\<^isub>1, s\<^isub>2)"}
  tests the subsort relation @{text "s\<^isub>1 \<subseteq> s\<^isub>2"}.

  \item @{ML Sign.of_sort}~@{text "thy (\<tau>, s)"} tests whether a type
  is of a given sort.

  \item @{ML Sign.add_types}~@{text "[(c, k, mx), \<dots>]"} declares new
  type constructors @{text "c"} with @{text "k"} arguments and
  optional mixfix syntax.

  \item @{ML Sign.add_tyabbrs_i}~@{text "[(c, \<^vec>\<alpha>, \<tau>, mx), \<dots>]"}
  defines a new type abbreviation @{text "(\<^vec>\<alpha>)c = \<tau>"} with
  optional mixfix syntax.

  \item @{ML Sign.primitive_class}~@{text "(c, [c\<^isub>1, \<dots>,
  c\<^isub>n])"} declares new class @{text "c"} derived together with
  class relations @{text "c \<subseteq> c\<^isub>i"}, for @{text "i = 1, \<dots>, n"}.

  \item @{ML Sign.primitive_classrel}~@{text "(c\<^isub>1,
  c\<^isub>2)"} declares class relation @{text "c\<^isub>1 \<subseteq>
  c\<^isub>2"}.

  \item @{ML Sign.primitive_arity}~@{text "(c, \<^vec>s, s)"} declares
  arity @{text "c :: (\<^vec>s)s"}.

  \end{description}
*}



section {* Terms \label{sec:terms} *}

text {*
  \glossary{Term}{FIXME}

  The language of terms is that of simply-typed @{text "\<lambda>"}-calculus
  with de-Bruijn indices for bound variables, and named free
  variables, and constants.  Terms with loose bound variables are
  usually considered malformed.  The types of variables and constants
  is stored explicitly at each occurrence in the term (which is a
  known performance issue).

  FIXME de-Bruijn representation of lambda terms

  Term syntax provides explicit abstraction @{text "\<lambda>x :: \<alpha>. b(x)"}
  and application @{text "t u"}, while types are usually implicit
  thanks to type-inference.

  Terms of type @{text "prop"} are called
  propositions.  Logical statements are composed via @{text "\<And>x ::
  \<alpha>. B(x)"} and @{text "A \<Longrightarrow> B"}.
*}


text {*

FIXME

\glossary{Schematic polymorphism}{FIXME}

\glossary{Type variable}{FIXME}

*}


section {* Theorems \label{sec:thms} *}

text {*

  Primitive reasoning operates on judgments of the form @{text "\<Gamma> \<turnstile>
  \<phi>"}, with standard introduction and elimination rules for @{text
  "\<And>"} and @{text "\<Longrightarrow>"} that refer to fixed parameters @{text "x"} and
  hypotheses @{text "A"} from the context @{text "\<Gamma>"}.  The
  corresponding proof terms are left implicit in the classic
  ``LCF-approach'', although they could be exploited separately
  \cite{Berghofer-Nipkow:2000}.

  The framework also provides definitional equality @{text "\<equiv> :: \<alpha> \<Rightarrow> \<alpha>
  \<Rightarrow> prop"}, with @{text "\<alpha>\<beta>\<eta>"}-conversion rules.  The internal
  conjunction @{text "& :: prop \<Rightarrow> prop \<Rightarrow> prop"} enables the view of
  assumptions and conclusions emerging uniformly as simultaneous
  statements.



  FIXME

\glossary{Proposition}{A \seeglossary{term} of \seeglossary{type}
@{text "prop"}.  Internally, there is nothing special about
propositions apart from their type, but the concrete syntax enforces a
clear distinction.  Propositions are structured via implication @{text
"A \<Longrightarrow> B"} or universal quantification @{text "\<And>x. B x"} --- anything
else is considered atomic.  The canonical form for propositions is
that of a \seeglossary{Hereditary Harrop Formula}.}

\glossary{Theorem}{A proven proposition within a certain theory and
proof context, formally @{text "\<Gamma> \<turnstile>\<^sub>\<Theta> \<phi>"}; both contexts are
rarely spelled out explicitly.  Theorems are usually normalized
according to the \seeglossary{HHF} format.}

\glossary{Fact}{Sometimes used interchangably for
\seeglossary{theorem}.  Strictly speaking, a list of theorems,
essentially an extra-logical conjunction.  Facts emerge either as
local assumptions, or as results of local goal statements --- both may
be simultaneous, hence the list representation.}

\glossary{Schematic variable}{FIXME}

\glossary{Fixed variable}{A variable that is bound within a certain
proof context; an arbitrary-but-fixed entity within a portion of proof
text.}

\glossary{Free variable}{Synonymous for \seeglossary{fixed variable}.}

\glossary{Bound variable}{FIXME}

\glossary{Variable}{See \seeglossary{schematic variable},
\seeglossary{fixed variable}, \seeglossary{bound variable}, or
\seeglossary{type variable}.  The distinguishing feature of different
variables is their binding scope.}

*}


section {* Proof terms *}

text {*
  FIXME !?
*}


section {* Rules \label{sec:rules} *}

text {*

FIXME

  A \emph{rule} is any Pure theorem in HHF normal form; there is a
  separate calculus for rule composition, which is modeled after
  Gentzen's Natural Deduction \cite{Gentzen:1935}, but allows
  rules to be nested arbitrarily, similar to \cite{extensions91}.

  Normally, all theorems accessible to the user are proper rules.
  Low-level inferences are occasional required internally, but the
  result should be always presented in canonical form.  The higher
  interfaces of Isabelle/Isar will always produce proper rules.  It is
  important to maintain this invariant in add-on applications!

  There are two main principles of rule composition: @{text
  "resolution"} (i.e.\ backchaining of rules) and @{text
  "by-assumption"} (i.e.\ closing a branch); both principles are
  combined in the variants of @{text "elim-resosultion"} and @{text
  "dest-resolution"}.  Raw @{text "composition"} is occasionally
  useful as well, also it is strictly speaking outside of the proper
  rule calculus.

  Rules are treated modulo general higher-order unification, which is
  unification modulo the equational theory of @{text "\<alpha>\<beta>\<eta>"}-conversion
  on @{text "\<lambda>"}-terms.  Moreover, propositions are understood modulo
  the (derived) equivalence @{text "(A \<Longrightarrow> (\<And>x. B x)) \<equiv> (\<And>x. A \<Longrightarrow> B x)"}.

  This means that any operations within the rule calculus may be
  subject to spontaneous @{text "\<alpha>\<beta>\<eta>"}-HHF conversions.  It is common
  practice not to contract or expand unnecessarily.  Some mechanisms
  prefer an one form, others the opposite, so there is a potential
  danger to produce some oscillation!

  Only few operations really work \emph{modulo} HHF conversion, but
  expect a normal form: quantifiers @{text "\<And>"} before implications
  @{text "\<Longrightarrow>"} at each level of nesting.

\glossary{Hereditary Harrop Formula}{The set of propositions in HHF
format is defined inductively as @{text "H = (\<And>x\<^sup>*. H\<^sup>* \<Longrightarrow>
A)"}, for variables @{text "x"} and atomic propositions @{text "A"}.
Any proposition may be put into HHF form by normalizing with the rule
@{text "(A \<Longrightarrow> (\<And>x. B x)) \<equiv> (\<And>x. A \<Longrightarrow> B x)"}.  In Isabelle, the outermost
quantifier prefix is represented via \seeglossary{schematic
variables}, such that the top-level structure is merely that of a
\seeglossary{Horn Clause}}.

\glossary{HHF}{See \seeglossary{Hereditary Harrop Formula}.}

*}

end
