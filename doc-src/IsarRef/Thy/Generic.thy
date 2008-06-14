(* $Id$ *)

theory Generic
imports Main
begin

chapter {* Generic tools and packages \label{ch:gen-tools} *}

section {* Configuration options *}

text {*
  Isabelle/Pure maintains a record of named configuration options
  within the theory or proof context, with values of type @{ML_type
  bool}, @{ML_type int}, or @{ML_type string}.  Tools may declare
  options in ML, and then refer to these values (relative to the
  context).  Thus global reference variables are easily avoided.  The
  user may change the value of a configuration option by means of an
  associated attribute of the same name.  This form of context
  declaration works particularly well with commands such as @{command
  "declare"} or @{command "using"}.

  For historical reasons, some tools cannot take the full proof
  context into account and merely refer to the background theory.
  This is accommodated by configuration options being declared as
  ``global'', which may not be changed within a local context.

  \begin{matharray}{rcll}
    @{command_def "print_configs"} & : & \isarkeep{theory~|~proof} \\
  \end{matharray}

  \begin{rail}
    name ('=' ('true' | 'false' | int | name))?
  \end{rail}

  \begin{descr}
  
  \item [@{command "print_configs"}] prints the available
  configuration options, with names, types, and current values.
  
  \item [@{text "name = value"}] as an attribute expression modifies
  the named option, with the syntax of the value depending on the
  option's type.  For @{ML_type bool} the default value is @{text
  true}.  Any attempt to change a global option in a local context is
  ignored.

  \end{descr}
*}


section {* Basic proof tools *}

subsection {* Miscellaneous methods and attributes \label{sec:misc-meth-att} *}

text {*
  \begin{matharray}{rcl}
    @{method_def unfold} & : & \isarmeth \\
    @{method_def fold} & : & \isarmeth \\
    @{method_def insert} & : & \isarmeth \\[0.5ex]
    @{method_def erule}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def drule}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def frule}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def succeed} & : & \isarmeth \\
    @{method_def fail} & : & \isarmeth \\
  \end{matharray}

  \begin{rail}
    ('fold' | 'unfold' | 'insert') thmrefs
    ;
    ('erule' | 'drule' | 'frule') ('('nat')')? thmrefs
    ;
  \end{rail}

  \begin{descr}
  
  \item [@{method unfold}~@{text "a\<^sub>1 \<dots> a\<^sub>n"} and @{method
  fold}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}] expand (or fold back) the
  given definitions throughout all goals; any chained facts provided
  are inserted into the goal and subject to rewriting as well.

  \item [@{method insert}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}] inserts
  theorems as facts into all goals of the proof state.  Note that
  current facts indicated for forward chaining are ignored.

  \item [@{method erule}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}, @{method
  drule}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}, and @{method frule}~@{text
  "a\<^sub>1 \<dots> a\<^sub>n"}] are similar to the basic @{method rule}
  method (see \secref{sec:pure-meth-att}), but apply rules by
  elim-resolution, destruct-resolution, and forward-resolution,
  respectively \cite{isabelle-ref}.  The optional natural number
  argument (default 0) specifies additional assumption steps to be
  performed here.

  Note that these methods are improper ones, mainly serving for
  experimentation and tactic script emulation.  Different modes of
  basic rule application are usually expressed in Isar at the proof
  language level, rather than via implicit proof state manipulations.
  For example, a proper single-step elimination would be done using
  the plain @{method rule} method, with forward chaining of current
  facts.

  \item [@{method succeed}] yields a single (unchanged) result; it is
  the identity of the ``@{text ","}'' method combinator (cf.\
  \secref{sec:syn-meth}).

  \item [@{method fail}] yields an empty result sequence; it is the
  identity of the ``@{text "|"}'' method combinator (cf.\
  \secref{sec:syn-meth}).

  \end{descr}

  \begin{matharray}{rcl}
    @{attribute_def tagged} & : & \isaratt \\
    @{attribute_def untagged} & : & \isaratt \\[0.5ex]
    @{attribute_def THEN} & : & \isaratt \\
    @{attribute_def COMP} & : & \isaratt \\[0.5ex]
    @{attribute_def unfolded} & : & \isaratt \\
    @{attribute_def folded} & : & \isaratt \\[0.5ex]
    @{attribute_def rotated} & : & \isaratt \\
    @{attribute_def (Pure) elim_format} & : & \isaratt \\
    @{attribute_def standard}@{text "\<^sup>*"} & : & \isaratt \\
    @{attribute_def no_vars}@{text "\<^sup>*"} & : & \isaratt \\
  \end{matharray}

  \begin{rail}
    'tagged' nameref
    ;
    'untagged' name
    ;
    ('THEN' | 'COMP') ('[' nat ']')? thmref
    ;
    ('unfolded' | 'folded') thmrefs
    ;
    'rotated' ( int )?
  \end{rail}

  \begin{descr}

  \item [@{attribute tagged}~@{text "name arg"} and @{attribute
  untagged}~@{text name}] add and remove \emph{tags} of some theorem.
  Tags may be any list of string pairs that serve as formal comment.
  The first string is considered the tag name, the second its
  argument.  Note that @{attribute untagged} removes any tags of the
  same name.

  \item [@{attribute THEN}~@{text a} and @{attribute COMP}~@{text a}]
  compose rules by resolution.  @{attribute THEN} resolves with the
  first premise of @{text a} (an alternative position may be also
  specified); the @{attribute COMP} version skips the automatic
  lifting process that is normally intended (cf.\ @{ML "op RS"} and
  @{ML "op COMP"} in \cite[\S5]{isabelle-ref}).
  
  \item [@{attribute unfolded}~@{text "a\<^sub>1 \<dots> a\<^sub>n"} and
  @{attribute folded}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}] expand and fold
  back again the given definitions throughout a rule.

  \item [@{attribute rotated}~@{text n}] rotate the premises of a
  theorem by @{text n} (default 1).

  \item [@{attribute (Pure) elim_format}] turns a destruction rule
  into elimination rule format, by resolving with the rule @{prop
  "PROP A \<Longrightarrow> (PROP A \<Longrightarrow> PROP B) \<Longrightarrow> PROP B"}.
  
  Note that the Classical Reasoner (\secref{sec:classical}) provides
  its own version of this operation.

  \item [@{attribute standard}] puts a theorem into the standard form
  of object-rules at the outermost theory level.  Note that this
  operation violates the local proof context (including active
  locales).

  \item [@{attribute no_vars}] replaces schematic variables by free
  ones; this is mainly for tuning output of pretty printed theorems.

  \end{descr}
*}


subsection {* Low-level equational reasoning *}

text {*
  \begin{matharray}{rcl}
    @{method_def subst} & : & \isarmeth \\
    @{method_def hypsubst} & : & \isarmeth \\
    @{method_def split} & : & \isarmeth \\
  \end{matharray}

  \begin{rail}
    'subst' ('(' 'asm' ')')? ('(' (nat+) ')')? thmref
    ;
    'split' ('(' 'asm' ')')? thmrefs
    ;
  \end{rail}

  These methods provide low-level facilities for equational reasoning
  that are intended for specialized applications only.  Normally,
  single step calculations would be performed in a structured text
  (see also \secref{sec:calculation}), while the Simplifier methods
  provide the canonical way for automated normalization (see
  \secref{sec:simplifier}).

  \begin{descr}

  \item [@{method subst}~@{text eq}] performs a single substitution
  step using rule @{text eq}, which may be either a meta or object
  equality.

  \item [@{method subst}~@{text "(asm) eq"}] substitutes in an
  assumption.

  \item [@{method subst}~@{text "(i \<dots> j) eq"}] performs several
  substitutions in the conclusion. The numbers @{text i} to @{text j}
  indicate the positions to substitute at.  Positions are ordered from
  the top of the term tree moving down from left to right. For
  example, in @{text "(a + b) + (c + d)"} there are three positions
  where commutativity of @{text "+"} is applicable: 1 refers to
  @{text "a + b"}, 2 to the whole term, and 3 to @{text "c + d"}.

  If the positions in the list @{text "(i \<dots> j)"} are non-overlapping
  (e.g.\ @{text "(2 3)"} in @{text "(a + b) + (c + d)"}) you may
  assume all substitutions are performed simultaneously.  Otherwise
  the behaviour of @{text subst} is not specified.

  \item [@{method subst}~@{text "(asm) (i \<dots> j) eq"}] performs the
  substitutions in the assumptions. The positions refer to the
  assumptions in order from left to right.  For example, given in a
  goal of the form @{text "P (a + b) \<Longrightarrow> P (c + d) \<Longrightarrow> \<dots>"}, position 1 of
  commutativity of @{text "+"} is the subterm @{text "a + b"} and
  position 2 is the subterm @{text "c + d"}.

  \item [@{method hypsubst}] performs substitution using some
  assumption; this only works for equations of the form @{text "x =
  t"} where @{text x} is a free or bound variable.

  \item [@{method split}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}] performs
  single-step case splitting using the given rules.  By default,
  splitting is performed in the conclusion of a goal; the @{text
  "(asm)"} option indicates to operate on assumptions instead.
  
  Note that the @{method simp} method already involves repeated
  application of split rules as declared in the current context.

  \end{descr}
*}


subsection {* Further tactic emulations \label{sec:tactics} *}

text {*
  The following improper proof methods emulate traditional tactics.
  These admit direct access to the goal state, which is normally
  considered harmful!  In particular, this may involve both numbered
  goal addressing (default 1), and dynamic instantiation within the
  scope of some subgoal.

  \begin{warn}
    Dynamic instantiations refer to universally quantified parameters
    of a subgoal (the dynamic context) rather than fixed variables and
    term abbreviations of a (static) Isar context.
  \end{warn}

  Tactic emulation methods, unlike their ML counterparts, admit
  simultaneous instantiation from both dynamic and static contexts.
  If names occur in both contexts goal parameters hide locally fixed
  variables.  Likewise, schematic variables refer to term
  abbreviations, if present in the static context.  Otherwise the
  schematic variable is interpreted as a schematic variable and left
  to be solved by unification with certain parts of the subgoal.

  Note that the tactic emulation proof methods in Isabelle/Isar are
  consistently named @{text foo_tac}.  Note also that variable names
  occurring on left hand sides of instantiations must be preceded by a
  question mark if they coincide with a keyword or contain dots.  This
  is consistent with the attribute @{attribute "where"} (see
  \secref{sec:pure-meth-att}).

  \begin{matharray}{rcl}
    @{method_def rule_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def erule_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def drule_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def frule_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def cut_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def thin_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def subgoal_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def rename_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def rotate_tac}@{text "\<^sup>*"} & : & \isarmeth \\
    @{method_def tactic}@{text "\<^sup>*"} & : & \isarmeth \\
  \end{matharray}

  \begin{rail}
    ( 'rule\_tac' | 'erule\_tac' | 'drule\_tac' | 'frule\_tac' | 'cut\_tac' | 'thin\_tac' ) goalspec?
    ( insts thmref | thmrefs )
    ;
    'subgoal\_tac' goalspec? (prop +)
    ;
    'rename\_tac' goalspec? (name +)
    ;
    'rotate\_tac' goalspec? int?
    ;
    'tactic' text
    ;

    insts: ((name '=' term) + 'and') 'in'
    ;
  \end{rail}

\begin{descr}

  \item [@{method rule_tac} etc.] do resolution of rules with explicit
  instantiation.  This works the same way as the ML tactics @{ML
  Tactic.res_inst_tac} etc. (see \cite[\S3]{isabelle-ref})

  Multiple rules may be only given if there is no instantiation; then
  @{method rule_tac} is the same as @{ML resolve_tac} in ML (see
  \cite[\S3]{isabelle-ref}).

  \item [@{method cut_tac}] inserts facts into the proof state as
  assumption of a subgoal, see also @{ML Tactic.cut_facts_tac} in
  \cite[\S3]{isabelle-ref}.  Note that the scope of schematic
  variables is spread over the main goal statement.  Instantiations
  may be given as well, see also ML tactic @{ML Tactic.cut_inst_tac}
  in \cite[\S3]{isabelle-ref}.

  \item [@{method thin_tac}~@{text \<phi>}] deletes the specified
  assumption from a subgoal; note that @{text \<phi>} may contain schematic
  variables.  See also @{ML Tactic.thin_tac} in
  \cite[\S3]{isabelle-ref}.

  \item [@{method subgoal_tac}~@{text \<phi>}] adds @{text \<phi>} as an
  assumption to a subgoal.  See also @{ML Tactic.subgoal_tac} and @{ML
  Tactic.subgoals_tac} in \cite[\S3]{isabelle-ref}.

  \item [@{method rename_tac}~@{text "x\<^sub>1 \<dots> x\<^sub>n"}] renames
  parameters of a goal according to the list @{text "x\<^sub>1, \<dots>,
  x\<^sub>n"}, which refers to the \emph{suffix} of variables.

  \item [@{method rotate_tac}~@{text n}] rotates the assumptions of a
  goal by @{text n} positions: from right to left if @{text n} is
  positive, and from left to right if @{text n} is negative; the
  default value is 1.  See also @{ML rotate_tac} in
  \cite[\S3]{isabelle-ref}.

  \item [@{method tactic}~@{text "text"}] produces a proof method from
  any ML text of type @{ML_type tactic}.  Apart from the usual ML
  environment and the current implicit theory context, the ML code may
  refer to the following locally bound values:

%FIXME check
{\footnotesize\begin{verbatim}
val ctxt  : Proof.context
val facts : thm list
val thm   : string -> thm
val thms  : string -> thm list
\end{verbatim}}

  Here @{ML_text ctxt} refers to the current proof context, @{ML_text
  facts} indicates any current facts for forward-chaining, and @{ML
  thm}~/~@{ML thms} retrieve named facts (including global theorems)
  from the context.

  \end{descr}
*}


section {* The Simplifier \label{sec:simplifier} *}

subsection {* Simplification methods *}

text {*
  \begin{matharray}{rcl}
    @{method_def simp} & : & \isarmeth \\
    @{method_def simp_all} & : & \isarmeth \\
  \end{matharray}

  \indexouternonterm{simpmod}
  \begin{rail}
    ('simp' | 'simp\_all') ('!' ?) opt? (simpmod *)
    ;

    opt: '(' ('no\_asm' | 'no\_asm\_simp' | 'no\_asm\_use' | 'asm\_lr' ) ')'
    ;
    simpmod: ('add' | 'del' | 'only' | 'cong' (() | 'add' | 'del') |
      'split' (() | 'add' | 'del')) ':' thmrefs
    ;
  \end{rail}

  \begin{descr}

  \item [@{method simp}] invokes the Simplifier, after declaring
  additional rules according to the arguments given.  Note that the
  \railtterm{only} modifier first removes all other rewrite rules,
  congruences, and looper tactics (including splits), and then behaves
  like \railtterm{add}.

  \medskip The \railtterm{cong} modifiers add or delete Simplifier
  congruence rules (see also \cite{isabelle-ref}), the default is to
  add.

  \medskip The \railtterm{split} modifiers add or delete rules for the
  Splitter (see also \cite{isabelle-ref}), the default is to add.
  This works only if the Simplifier method has been properly setup to
  include the Splitter (all major object logics such HOL, HOLCF, FOL,
  ZF do this already).

  \item [@{method simp_all}] is similar to @{method simp}, but acts on
  all goals (backwards from the last to the first one).

  \end{descr}

  By default the Simplifier methods take local assumptions fully into
  account, using equational assumptions in the subsequent
  normalization process, or simplifying assumptions themselves (cf.\
  @{ML asm_full_simp_tac} in \cite[\S10]{isabelle-ref}).  In
  structured proofs this is usually quite well behaved in practice:
  just the local premises of the actual goal are involved, additional
  facts may be inserted via explicit forward-chaining (via @{command
  "then"}, @{command "from"}, @{command "using"} etc.).  The full
  context of premises is only included if the ``@{text "!"}'' (bang)
  argument is given, which should be used with some care, though.

  Additional Simplifier options may be specified to tune the behavior
  further (mostly for unstructured scripts with many accidental local
  facts): ``@{text "(no_asm)"}'' means assumptions are ignored
  completely (cf.\ @{ML simp_tac}), ``@{text "(no_asm_simp)"}'' means
  assumptions are used in the simplification of the conclusion but are
  not themselves simplified (cf.\ @{ML asm_simp_tac}), and ``@{text
  "(no_asm_use)"}'' means assumptions are simplified but are not used
  in the simplification of each other or the conclusion (cf.\ @{ML
  full_simp_tac}).  For compatibility reasons, there is also an option
  ``@{text "(asm_lr)"}'', which means that an assumption is only used
  for simplifying assumptions which are to the right of it (cf.\ @{ML
  asm_lr_simp_tac}).

  The configuration option @{text "depth_limit"} limits the number of
  recursive invocations of the simplifier during conditional
  rewriting.

  \medskip The Splitter package is usually configured to work as part
  of the Simplifier.  The effect of repeatedly applying @{ML
  split_tac} can be simulated by ``@{text "(simp only: split:
  a\<^sub>1 \<dots> a\<^sub>n)"}''.  There is also a separate @{text split}
  method available for single-step case splitting.
*}


subsection {* Declaring rules *}

text {*
  \begin{matharray}{rcl}
    @{command_def "print_simpset"}@{text "\<^sup>*"} & : & \isarkeep{theory~|~proof} \\
    @{attribute_def simp} & : & \isaratt \\
    @{attribute_def cong} & : & \isaratt \\
    @{attribute_def split} & : & \isaratt \\
  \end{matharray}

  \begin{rail}
    ('simp' | 'cong' | 'split') (() | 'add' | 'del')
    ;
  \end{rail}

  \begin{descr}

  \item [@{command "print_simpset"}] prints the collection of rules
  declared to the Simplifier, which is also known as ``simpset''
  internally \cite{isabelle-ref}.

  \item [@{attribute simp}] declares simplification rules.

  \item [@{attribute cong}] declares congruence rules.

  \item [@{attribute split}] declares case split rules.

  \end{descr}
*}


subsection {* Simplification procedures *}

text {*
  \begin{matharray}{rcl}
    @{command_def "simproc_setup"} & : & \isarkeep{local{\dsh}theory} \\
    simproc & : & \isaratt \\
  \end{matharray}

  \begin{rail}
    'simproc\_setup' name '(' (term + '|') ')' '=' text \\ ('identifier' (nameref+))?
    ;

    'simproc' (('add' ':')? | 'del' ':') (name+)
    ;
  \end{rail}

  \begin{descr}

  \item [@{command "simproc_setup"}] defines a named simplification
  procedure that is invoked by the Simplifier whenever any of the
  given term patterns match the current redex.  The implementation,
  which is provided as ML source text, needs to be of type @{ML_type
  "morphism -> simpset -> cterm -> thm option"}, where the @{ML_type
  cterm} represents the current redex @{text r} and the result is
  supposed to be some proven rewrite rule @{text "r \<equiv> r'"} (or a
  generalized version), or @{ML NONE} to indicate failure.  The
  @{ML_type simpset} argument holds the full context of the current
  Simplifier invocation, including the actual Isar proof context.  The
  @{ML_type morphism} informs about the difference of the original
  compilation context wrt.\ the one of the actual application later
  on.  The optional @{keyword "identifier"} specifies theorems that
  represent the logical content of the abstract theory of this
  simproc.

  Morphisms and identifiers are only relevant for simprocs that are
  defined within a local target context, e.g.\ in a locale.

  \item [@{text "simproc add: name"} and @{text "simproc del: name"}]
  add or delete named simprocs to the current Simplifier context.  The
  default is to add a simproc.  Note that @{command "simproc_setup"}
  already adds the new simproc to the subsequent context.

  \end{descr}
*}


subsection {* Forward simplification *}

text {*
  \begin{matharray}{rcl}
    @{attribute_def simplified} & : & \isaratt \\
  \end{matharray}

  \begin{rail}
    'simplified' opt? thmrefs?
    ;

    opt: '(' ('no\_asm' | 'no\_asm\_simp' | 'no\_asm\_use') ')'
    ;
  \end{rail}

  \begin{descr}
  
  \item [@{attribute simplified}~@{text "a\<^sub>1 \<dots> a\<^sub>n"}]
  causes a theorem to be simplified, either by exactly the specified
  rules @{text "a\<^sub>1, \<dots>, a\<^sub>n"}, or the implicit Simplifier
  context if no arguments are given.  The result is fully simplified
  by default, including assumptions and conclusion; the options @{text
  no_asm} etc.\ tune the Simplifier in the same way as the for the
  @{text simp} method.

  Note that forward simplification restricts the simplifier to its
  most basic operation of term rewriting; solver and looper tactics
  \cite{isabelle-ref} are \emph{not} involved here.  The @{text
  simplified} attribute should be only rarely required under normal
  circumstances.

  \end{descr}
*}


section {* The Classical Reasoner \label{sec:classical} *}

subsection {* Basic methods *}

text {*
  \begin{matharray}{rcl}
    @{method_def rule} & : & \isarmeth \\
    @{method_def contradiction} & : & \isarmeth \\
    @{method_def intro} & : & \isarmeth \\
    @{method_def elim} & : & \isarmeth \\
  \end{matharray}

  \begin{rail}
    ('rule' | 'intro' | 'elim') thmrefs?
    ;
  \end{rail}

  \begin{descr}

  \item [@{method rule}] as offered by the Classical Reasoner is a
  refinement over the primitive one (see \secref{sec:pure-meth-att}).
  Both versions essentially work the same, but the classical version
  observes the classical rule context in addition to that of
  Isabelle/Pure.

  Common object logics (HOL, ZF, etc.) declare a rich collection of
  classical rules (even if these would qualify as intuitionistic
  ones), but only few declarations to the rule context of
  Isabelle/Pure (\secref{sec:pure-meth-att}).

  \item [@{method contradiction}] solves some goal by contradiction,
  deriving any result from both @{text "\<not> A"} and @{text A}.  Chained
  facts, which are guaranteed to participate, may appear in either
  order.

  \item [@{method intro} and @{method elim}] repeatedly refine some
  goal by intro- or elim-resolution, after having inserted any chained
  facts.  Exactly the rules given as arguments are taken into account;
  this allows fine-tuned decomposition of a proof problem, in contrast
  to common automated tools.

  \end{descr}
*}


subsection {* Automated methods *}

text {*
  \begin{matharray}{rcl}
    @{method_def blast} & : & \isarmeth \\
    @{method_def fast} & : & \isarmeth \\
    @{method_def slow} & : & \isarmeth \\
    @{method_def best} & : & \isarmeth \\
    @{method_def safe} & : & \isarmeth \\
    @{method_def clarify} & : & \isarmeth \\
  \end{matharray}

  \indexouternonterm{clamod}
  \begin{rail}
    'blast' ('!' ?) nat? (clamod *)
    ;
    ('fast' | 'slow' | 'best' | 'safe' | 'clarify') ('!' ?) (clamod *)
    ;

    clamod: (('intro' | 'elim' | 'dest') ('!' | () | '?') | 'del') ':' thmrefs
    ;
  \end{rail}

  \begin{descr}

  \item [@{method blast}] refers to the classical tableau prover (see
  @{ML blast_tac} in \cite[\S11]{isabelle-ref}).  The optional
  argument specifies a user-supplied search bound (default 20).

  \item [@{method fast}, @{method slow}, @{method best}, @{method
  safe}, and @{method clarify}] refer to the generic classical
  reasoner.  See @{ML fast_tac}, @{ML slow_tac}, @{ML best_tac}, @{ML
  safe_tac}, and @{ML clarify_tac} in \cite[\S11]{isabelle-ref} for
  more information.

  \end{descr}

  Any of the above methods support additional modifiers of the context
  of classical rules.  Their semantics is analogous to the attributes
  given before.  Facts provided by forward chaining are inserted into
  the goal before commencing proof search.  The ``@{text
  "!"}''~argument causes the full context of assumptions to be
  included as well.
*}


subsection {* Combined automated methods \label{sec:clasimp} *}

text {*
  \begin{matharray}{rcl}
    @{method_def auto} & : & \isarmeth \\
    @{method_def force} & : & \isarmeth \\
    @{method_def clarsimp} & : & \isarmeth \\
    @{method_def fastsimp} & : & \isarmeth \\
    @{method_def slowsimp} & : & \isarmeth \\
    @{method_def bestsimp} & : & \isarmeth \\
  \end{matharray}

  \indexouternonterm{clasimpmod}
  \begin{rail}
    'auto' '!'? (nat nat)? (clasimpmod *)
    ;
    ('force' | 'clarsimp' | 'fastsimp' | 'slowsimp' | 'bestsimp') '!'? (clasimpmod *)
    ;

    clasimpmod: ('simp' (() | 'add' | 'del' | 'only') |
      ('cong' | 'split') (() | 'add' | 'del') |
      'iff' (((() | 'add') '?'?) | 'del') |
      (('intro' | 'elim' | 'dest') ('!' | () | '?') | 'del')) ':' thmrefs
  \end{rail}

  \begin{descr}

  \item [@{method auto}, @{method force}, @{method clarsimp}, @{method
  fastsimp}, @{method slowsimp}, and @{method bestsimp}] provide
  access to Isabelle's combined simplification and classical reasoning
  tactics.  These correspond to @{ML auto_tac}, @{ML force_tac}, @{ML
  clarsimp_tac}, and Classical Reasoner tactics with the Simplifier
  added as wrapper, see \cite[\S11]{isabelle-ref} for more
  information.  The modifier arguments correspond to those given in
  \secref{sec:simplifier} and \secref{sec:classical}.  Just note that
  the ones related to the Simplifier are prefixed by \railtterm{simp}
  here.

  Facts provided by forward chaining are inserted into the goal before
  doing the search.  The ``@{text "!"}'' argument causes the full
  context of assumptions to be included as well.

  \end{descr}
*}


subsection {* Declaring rules *}

text {*
  \begin{matharray}{rcl}
    @{command_def "print_claset"}@{text "\<^sup>*"} & : & \isarkeep{theory~|~proof} \\
    @{attribute_def intro} & : & \isaratt \\
    @{attribute_def elim} & : & \isaratt \\
    @{attribute_def dest} & : & \isaratt \\
    @{attribute_def rule} & : & \isaratt \\
    @{attribute_def iff} & : & \isaratt \\
  \end{matharray}

  \begin{rail}
    ('intro' | 'elim' | 'dest') ('!' | () | '?') nat?
    ;
    'rule' 'del'
    ;
    'iff' (((() | 'add') '?'?) | 'del')
    ;
  \end{rail}

  \begin{descr}

  \item [@{command "print_claset"}] prints the collection of rules
  declared to the Classical Reasoner, which is also known as
  ``claset'' internally \cite{isabelle-ref}.
  
  \item [@{attribute intro}, @{attribute elim}, and @{attribute dest}]
  declare introduction, elimination, and destruction rules,
  respectively.  By default, rules are considered as \emph{unsafe}
  (i.e.\ not applied blindly without backtracking), while ``@{text
  "!"}'' classifies as \emph{safe}.  Rule declarations marked by
  ``@{text "?"}'' coincide with those of Isabelle/Pure, cf.\
  \secref{sec:pure-meth-att} (i.e.\ are only applied in single steps
  of the @{method rule} method).  The optional natural number
  specifies an explicit weight argument, which is ignored by automated
  tools, but determines the search order of single rule steps.

  \item [@{attribute rule}~@{text del}] deletes introduction,
  elimination, or destruction rules from the context.

  \item [@{attribute iff}] declares logical equivalences to the
  Simplifier and the Classical reasoner at the same time.
  Non-conditional rules result in a ``safe'' introduction and
  elimination pair; conditional ones are considered ``unsafe''.  Rules
  with negative conclusion are automatically inverted (using @{text
  "\<not>"}-elimination internally).

  The ``@{text "?"}'' version of @{attribute iff} declares rules to
  the Isabelle/Pure context only, and omits the Simplifier
  declaration.

  \end{descr}
*}


subsection {* Classical operations *}

text {*
  \begin{matharray}{rcl}
    @{attribute_def swapped} & : & \isaratt \\
  \end{matharray}

  \begin{descr}

  \item [@{attribute swapped}] turns an introduction rule into an
  elimination, by resolving with the classical swap principle @{text
  "(\<not> B \<Longrightarrow> A) \<Longrightarrow> (\<not> A \<Longrightarrow> B)"}.

  \end{descr}
*}


section {* Object-logic setup \label{sec:object-logic} *}

text {*
  \begin{matharray}{rcl}
    @{command_def "judgment"} & : & \isartrans{theory}{theory} \\
    @{method_def atomize} & : & \isarmeth \\
    @{attribute_def atomize} & : & \isaratt \\
    @{attribute_def rule_format} & : & \isaratt \\
    @{attribute_def rulify} & : & \isaratt \\
  \end{matharray}

  The very starting point for any Isabelle object-logic is a ``truth
  judgment'' that links object-level statements to the meta-logic
  (with its minimal language of @{text prop} that covers universal
  quantification @{text "\<And>"} and implication @{text "\<Longrightarrow>"}).

  Common object-logics are sufficiently expressive to internalize rule
  statements over @{text "\<And>"} and @{text "\<Longrightarrow>"} within their own
  language.  This is useful in certain situations where a rule needs
  to be viewed as an atomic statement from the meta-level perspective,
  e.g.\ @{text "\<And>x. x \<in> A \<Longrightarrow> P x"} versus @{text "\<forall>x \<in> A. P x"}.

  From the following language elements, only the @{method atomize}
  method and @{attribute rule_format} attribute are occasionally
  required by end-users, the rest is for those who need to setup their
  own object-logic.  In the latter case existing formulations of
  Isabelle/FOL or Isabelle/HOL may be taken as realistic examples.

  Generic tools may refer to the information provided by object-logic
  declarations internally.

  \begin{rail}
    'judgment' constdecl
    ;
    'atomize' ('(' 'full' ')')?
    ;
    'rule\_format' ('(' 'noasm' ')')?
    ;
  \end{rail}

  \begin{descr}
  
  \item [@{command "judgment"}~@{text "c :: \<sigma> (mx)"}] declares
  constant @{text c} as the truth judgment of the current
  object-logic.  Its type @{text \<sigma>} should specify a coercion of the
  category of object-level propositions to @{text prop} of the Pure
  meta-logic; the mixfix annotation @{text "(mx)"} would typically
  just link the object language (internally of syntactic category
  @{text logic}) with that of @{text prop}.  Only one @{command
  "judgment"} declaration may be given in any theory development.
  
  \item [@{method atomize} (as a method)] rewrites any non-atomic
  premises of a sub-goal, using the meta-level equations declared via
  @{attribute atomize} (as an attribute) beforehand.  As a result,
  heavily nested goals become amenable to fundamental operations such
  as resolution (cf.\ the @{method rule} method).  Giving the ``@{text
  "(full)"}'' option here means to turn the whole subgoal into an
  object-statement (if possible), including the outermost parameters
  and assumptions as well.

  A typical collection of @{attribute atomize} rules for a particular
  object-logic would provide an internalization for each of the
  connectives of @{text "\<And>"}, @{text "\<Longrightarrow>"}, and @{text "\<equiv>"}.
  Meta-level conjunction should be covered as well (this is
  particularly important for locales, see \secref{sec:locale}).

  \item [@{attribute rule_format}] rewrites a theorem by the
  equalities declared as @{attribute rulify} rules in the current
  object-logic.  By default, the result is fully normalized, including
  assumptions and conclusions at any depth.  The @{text "(no_asm)"}
  option restricts the transformation to the conclusion of a rule.

  In common object-logics (HOL, FOL, ZF), the effect of @{attribute
  rule_format} is to replace (bounded) universal quantification
  (@{text "\<forall>"}) and implication (@{text "\<longrightarrow>"}) by the corresponding
  rule statements over @{text "\<And>"} and @{text "\<Longrightarrow>"}.

  \end{descr}
*}

end
