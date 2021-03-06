
section \<open>Example: First-Order Logic\<close>

theory %visible First_Order_Logic
imports Base  (* FIXME Pure!? *)
begin

text \<open>
  \noindent In order to commence a new object-logic within
  Isabelle/Pure we introduce abstract syntactic categories @{text "i"}
  for individuals and @{text "o"} for object-propositions.  The latter
  is embedded into the language of Pure propositions by means of a
  separate judgment.
\<close>

typedecl i
typedecl o

judgment
  Trueprop :: "o \<Rightarrow> prop"    ("_" 5)

text \<open>
  \noindent Note that the object-logic judgment is implicit in the
  syntax: writing @{prop A} produces @{term "Trueprop A"} internally.
  From the Pure perspective this means ``@{prop A} is derivable in the
  object-logic''.
\<close>


subsection \<open>Equational reasoning \label{sec:framework-ex-equal}\<close>

text \<open>
  Equality is axiomatized as a binary predicate on individuals, with
  reflexivity as introduction, and substitution as elimination
  principle.  Note that the latter is particularly convenient in a
  framework like Isabelle, because syntactic congruences are
  implicitly produced by unification of @{term "B x"} against
  expressions containing occurrences of @{term x}.
\<close>

axiomatization
  equal :: "i \<Rightarrow> i \<Rightarrow> o"  (infix "=" 50)
where
  refl [intro]: "x = x" and
  subst [elim]: "x = y \<Longrightarrow> B x \<Longrightarrow> B y"

text \<open>
  \noindent Substitution is very powerful, but also hard to control in
  full generality.  We derive some common symmetry~/ transitivity
  schemes of @{term equal} as particular consequences.
\<close>

theorem sym [sym]:
  assumes "x = y"
  shows "y = x"
proof -
  have "x = x" ..
  with \<open>x = y\<close> show "y = x" ..
qed

theorem forw_subst [trans]:
  assumes "y = x" and "B x"
  shows "B y"
proof -
  from \<open>y = x\<close> have "x = y" ..
  from this and \<open>B x\<close> show "B y" ..
qed

theorem back_subst [trans]:
  assumes "B x" and "x = y"
  shows "B y"
proof -
  from \<open>x = y\<close> and \<open>B x\<close>
  show "B y" ..
qed

theorem trans [trans]:
  assumes "x = y" and "y = z"
  shows "x = z"
proof -
  from \<open>y = z\<close> and \<open>x = y\<close>
  show "x = z" ..
qed


subsection \<open>Basic group theory\<close>

text \<open>
  As an example for equational reasoning we consider some bits of
  group theory.  The subsequent locale definition postulates group
  operations and axioms; we also derive some consequences of this
  specification.
\<close>

locale group =
  fixes prod :: "i \<Rightarrow> i \<Rightarrow> i"  (infix "\<circ>" 70)
    and inv :: "i \<Rightarrow> i"  ("(_\<inverse>)" [1000] 999)
    and unit :: i  ("1")
  assumes assoc: "(x \<circ> y) \<circ> z = x \<circ> (y \<circ> z)"
    and left_unit:  "1 \<circ> x = x"
    and left_inv: "x\<inverse> \<circ> x = 1"
begin

theorem right_inv: "x \<circ> x\<inverse> = 1"
proof -
  have "x \<circ> x\<inverse> = 1 \<circ> (x \<circ> x\<inverse>)" by (rule left_unit [symmetric])
  also have "\<dots> = (1 \<circ> x) \<circ> x\<inverse>" by (rule assoc [symmetric])
  also have "1 = (x\<inverse>)\<inverse> \<circ> x\<inverse>" by (rule left_inv [symmetric])
  also have "\<dots> \<circ> x = (x\<inverse>)\<inverse> \<circ> (x\<inverse> \<circ> x)" by (rule assoc)
  also have "x\<inverse> \<circ> x = 1" by (rule left_inv)
  also have "((x\<inverse>)\<inverse> \<circ> \<dots>) \<circ> x\<inverse> = (x\<inverse>)\<inverse> \<circ> (1 \<circ> x\<inverse>)" by (rule assoc)
  also have "1 \<circ> x\<inverse> = x\<inverse>" by (rule left_unit)
  also have "(x\<inverse>)\<inverse> \<circ> \<dots> = 1" by (rule left_inv)
  finally show "x \<circ> x\<inverse> = 1" .
qed

theorem right_unit: "x \<circ> 1 = x"
proof -
  have "1 = x\<inverse> \<circ> x" by (rule left_inv [symmetric])
  also have "x \<circ> \<dots> = (x \<circ> x\<inverse>) \<circ> x" by (rule assoc [symmetric])
  also have "x \<circ> x\<inverse> = 1" by (rule right_inv)
  also have "\<dots> \<circ> x = x" by (rule left_unit)
  finally show "x \<circ> 1 = x" .
qed

text \<open>
  \noindent Reasoning from basic axioms is often tedious.  Our proofs
  work by producing various instances of the given rules (potentially
  the symmetric form) using the pattern ``@{command have}~@{text
  eq}~@{command "by"}~@{text "(rule r)"}'' and composing the chain of
  results via @{command also}/@{command finally}.  These steps may
  involve any of the transitivity rules declared in
  \secref{sec:framework-ex-equal}, namely @{thm trans} in combining
  the first two results in @{thm right_inv} and in the final steps of
  both proofs, @{thm forw_subst} in the first combination of @{thm
  right_unit}, and @{thm back_subst} in all other calculational steps.

  Occasional substitutions in calculations are adequate, but should
  not be over-emphasized.  The other extreme is to compose a chain by
  plain transitivity only, with replacements occurring always in
  topmost position. For example:
\<close>

(*<*)
theorem "\<And>A. PROP A \<Longrightarrow> PROP A"
proof -
  assume [symmetric, defn]: "\<And>x y. (x \<equiv> y) \<equiv> Trueprop (x = y)"
  fix x
(*>*)
  have "x \<circ> 1 = x \<circ> (x\<inverse> \<circ> x)" unfolding left_inv ..
  also have "\<dots> = (x \<circ> x\<inverse>) \<circ> x" unfolding assoc ..
  also have "\<dots> = 1 \<circ> x" unfolding right_inv ..
  also have "\<dots> = x" unfolding left_unit ..
  finally have "x \<circ> 1 = x" .
(*<*)
qed
(*>*)

text \<open>
  \noindent Here we have re-used the built-in mechanism for unfolding
  definitions in order to normalize each equational problem.  A more
  realistic object-logic would include proper setup for the Simplifier
  (\secref{sec:simplifier}), the main automated tool for equational
  reasoning in Isabelle.  Then ``@{command unfolding}~@{thm
  left_inv}~@{command ".."}'' would become ``@{command "by"}~@{text
  "(simp only: left_inv)"}'' etc.
\<close>

end


subsection \<open>Propositional logic \label{sec:framework-ex-prop}\<close>

text \<open>
  We axiomatize basic connectives of propositional logic: implication,
  disjunction, and conjunction.  The associated rules are modeled
  after Gentzen's system of Natural Deduction @{cite "Gentzen:1935"}.
\<close>

axiomatization
  imp :: "o \<Rightarrow> o \<Rightarrow> o"  (infixr "\<longrightarrow>" 25) where
  impI [intro]: "(A \<Longrightarrow> B) \<Longrightarrow> A \<longrightarrow> B" and
  impD [dest]: "(A \<longrightarrow> B) \<Longrightarrow> A \<Longrightarrow> B"

axiomatization
  disj :: "o \<Rightarrow> o \<Rightarrow> o"  (infixr "\<or>" 30) where
  disjI\<^sub>1 [intro]: "A \<Longrightarrow> A \<or> B" and
  disjI\<^sub>2 [intro]: "B \<Longrightarrow> A \<or> B" and
  disjE [elim]: "A \<or> B \<Longrightarrow> (A \<Longrightarrow> C) \<Longrightarrow> (B \<Longrightarrow> C) \<Longrightarrow> C"

axiomatization
  conj :: "o \<Rightarrow> o \<Rightarrow> o"  (infixr "\<and>" 35) where
  conjI [intro]: "A \<Longrightarrow> B \<Longrightarrow> A \<and> B" and
  conjD\<^sub>1: "A \<and> B \<Longrightarrow> A" and
  conjD\<^sub>2: "A \<and> B \<Longrightarrow> B"

text \<open>
  \noindent The conjunctive destructions have the disadvantage that
  decomposing @{prop "A \<and> B"} involves an immediate decision which
  component should be projected.  The more convenient simultaneous
  elimination @{prop "A \<and> B \<Longrightarrow> (A \<Longrightarrow> B \<Longrightarrow> C) \<Longrightarrow> C"} can be derived as
  follows:
\<close>

theorem conjE [elim]:
  assumes "A \<and> B"
  obtains A and B
proof
  from \<open>A \<and> B\<close> show A by (rule conjD\<^sub>1)
  from \<open>A \<and> B\<close> show B by (rule conjD\<^sub>2)
qed

text \<open>
  \noindent Here is an example of swapping conjuncts with a single
  intermediate elimination step:
\<close>

(*<*)
lemma "\<And>A. PROP A \<Longrightarrow> PROP A"
proof -
(*>*)
  assume "A \<and> B"
  then obtain B and A ..
  then have "B \<and> A" ..
(*<*)
qed
(*>*)

text \<open>
  \noindent Note that the analogous elimination rule for disjunction
  ``@{text "\<ASSUMES> A \<or> B \<OBTAINS> A \<BBAR> B"}'' coincides with
  the original axiomatization of @{thm disjE}.

  \medskip We continue propositional logic by introducing absurdity
  with its characteristic elimination.  Plain truth may then be
  defined as a proposition that is trivially true.
\<close>

axiomatization
  false :: o  ("\<bottom>") where
  falseE [elim]: "\<bottom> \<Longrightarrow> A"

definition
  true :: o  ("\<top>") where
  "\<top> \<equiv> \<bottom> \<longrightarrow> \<bottom>"

theorem trueI [intro]: \<top>
  unfolding true_def ..

text \<open>
  \medskip\noindent Now negation represents an implication towards
  absurdity:
\<close>

definition
  not :: "o \<Rightarrow> o"  ("\<not> _" [40] 40) where
  "\<not> A \<equiv> A \<longrightarrow> \<bottom>"

theorem notI [intro]:
  assumes "A \<Longrightarrow> \<bottom>"
  shows "\<not> A"
unfolding not_def
proof
  assume A
  then show \<bottom> by (rule \<open>A \<Longrightarrow> \<bottom>\<close>)
qed

theorem notE [elim]:
  assumes "\<not> A" and A
  shows B
proof -
  from \<open>\<not> A\<close> have "A \<longrightarrow> \<bottom>" unfolding not_def .
  from \<open>A \<longrightarrow> \<bottom>\<close> and \<open>A\<close> have \<bottom> ..
  then show B ..
qed


subsection \<open>Classical logic\<close>

text \<open>
  Subsequently we state the principle of classical contradiction as a
  local assumption.  Thus we refrain from forcing the object-logic
  into the classical perspective.  Within that context, we may derive
  well-known consequences of the classical principle.
\<close>

locale classical =
  assumes classical: "(\<not> C \<Longrightarrow> C) \<Longrightarrow> C"
begin

theorem double_negation:
  assumes "\<not> \<not> C"
  shows C
proof (rule classical)
  assume "\<not> C"
  with \<open>\<not> \<not> C\<close> show C ..
qed

theorem tertium_non_datur: "C \<or> \<not> C"
proof (rule double_negation)
  show "\<not> \<not> (C \<or> \<not> C)"
  proof
    assume "\<not> (C \<or> \<not> C)"
    have "\<not> C"
    proof
      assume C then have "C \<or> \<not> C" ..
      with \<open>\<not> (C \<or> \<not> C)\<close> show \<bottom> ..
    qed
    then have "C \<or> \<not> C" ..
    with \<open>\<not> (C \<or> \<not> C)\<close> show \<bottom> ..
  qed
qed

text \<open>
  \noindent These examples illustrate both classical reasoning and
  non-trivial propositional proofs in general.  All three rules
  characterize classical logic independently, but the original rule is
  already the most convenient to use, because it leaves the conclusion
  unchanged.  Note that @{prop "(\<not> C \<Longrightarrow> C) \<Longrightarrow> C"} fits again into our
  format for eliminations, despite the additional twist that the
  context refers to the main conclusion.  So we may write @{thm
  classical} as the Isar statement ``@{text "\<OBTAINS> \<not> thesis"}''.
  This also explains nicely how classical reasoning really works:
  whatever the main @{text thesis} might be, we may always assume its
  negation!
\<close>

end


subsection \<open>Quantifiers \label{sec:framework-ex-quant}\<close>

text \<open>
  Representing quantifiers is easy, thanks to the higher-order nature
  of the underlying framework.  According to the well-known technique
  introduced by Church @{cite "church40"}, quantifiers are operators on
  predicates, which are syntactically represented as @{text "\<lambda>"}-terms
  of type @{typ "i \<Rightarrow> o"}.  Binder notation turns @{text "All (\<lambda>x. B
  x)"} into @{text "\<forall>x. B x"} etc.
\<close>

axiomatization
  All :: "(i \<Rightarrow> o) \<Rightarrow> o"  (binder "\<forall>" 10) where
  allI [intro]: "(\<And>x. B x) \<Longrightarrow> \<forall>x. B x" and
  allD [dest]: "(\<forall>x. B x) \<Longrightarrow> B a"

axiomatization
  Ex :: "(i \<Rightarrow> o) \<Rightarrow> o"  (binder "\<exists>" 10) where
  exI [intro]: "B a \<Longrightarrow> (\<exists>x. B x)" and
  exE [elim]: "(\<exists>x. B x) \<Longrightarrow> (\<And>x. B x \<Longrightarrow> C) \<Longrightarrow> C"

text \<open>
  \noindent The statement of @{thm exE} corresponds to ``@{text
  "\<ASSUMES> \<exists>x. B x \<OBTAINS> x \<WHERE> B x"}'' in Isar.  In the
  subsequent example we illustrate quantifier reasoning involving all
  four rules:
\<close>

theorem
  assumes "\<exists>x. \<forall>y. R x y"
  shows "\<forall>y. \<exists>x. R x y"
proof    -- \<open>@{text "\<forall>"} introduction\<close>
  obtain x where "\<forall>y. R x y" using \<open>\<exists>x. \<forall>y. R x y\<close> ..    -- \<open>@{text "\<exists>"} elimination\<close>
  fix y have "R x y" using \<open>\<forall>y. R x y\<close> ..    -- \<open>@{text "\<forall>"} destruction\<close>
  then show "\<exists>x. R x y" ..    -- \<open>@{text "\<exists>"} introduction\<close>
qed


subsection \<open>Canonical reasoning patterns\<close>

text \<open>
  The main rules of first-order predicate logic from
  \secref{sec:framework-ex-prop} and \secref{sec:framework-ex-quant}
  can now be summarized as follows, using the native Isar statement
  format of \secref{sec:framework-stmt}.

  \medskip
  \begin{tabular}{l}
  @{text "impI: \<ASSUMES> A \<Longrightarrow> B \<SHOWS> A \<longrightarrow> B"} \\
  @{text "impD: \<ASSUMES> A \<longrightarrow> B \<AND> A \<SHOWS> B"} \\[1ex]

  @{text "disjI\<^sub>1: \<ASSUMES> A \<SHOWS> A \<or> B"} \\
  @{text "disjI\<^sub>2: \<ASSUMES> B \<SHOWS> A \<or> B"} \\
  @{text "disjE: \<ASSUMES> A \<or> B \<OBTAINS> A \<BBAR> B"} \\[1ex]

  @{text "conjI: \<ASSUMES> A \<AND> B \<SHOWS> A \<and> B"} \\
  @{text "conjE: \<ASSUMES> A \<and> B \<OBTAINS> A \<AND> B"} \\[1ex]

  @{text "falseE: \<ASSUMES> \<bottom> \<SHOWS> A"} \\
  @{text "trueI: \<SHOWS> \<top>"} \\[1ex]

  @{text "notI: \<ASSUMES> A \<Longrightarrow> \<bottom> \<SHOWS> \<not> A"} \\
  @{text "notE: \<ASSUMES> \<not> A \<AND> A \<SHOWS> B"} \\[1ex]

  @{text "allI: \<ASSUMES> \<And>x. B x \<SHOWS> \<forall>x. B x"} \\
  @{text "allE: \<ASSUMES> \<forall>x. B x \<SHOWS> B a"} \\[1ex]

  @{text "exI: \<ASSUMES> B a \<SHOWS> \<exists>x. B x"} \\
  @{text "exE: \<ASSUMES> \<exists>x. B x \<OBTAINS> a \<WHERE> B a"}
  \end{tabular}
  \medskip

  \noindent This essentially provides a declarative reading of Pure
  rules as Isar reasoning patterns: the rule statements tells how a
  canonical proof outline shall look like.  Since the above rules have
  already been declared as @{attribute (Pure) intro}, @{attribute
  (Pure) elim}, @{attribute (Pure) dest} --- each according to its
  particular shape --- we can immediately write Isar proof texts as
  follows:
\<close>

(*<*)
theorem "\<And>A. PROP A \<Longrightarrow> PROP A"
proof -
(*>*)

  text_raw \<open>\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "A \<longrightarrow> B"
  proof
    assume A
    show B sorry %noproof
  qed

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "A \<longrightarrow> B" and A sorry %noproof
  then have B ..

  text_raw \<open>\end{minipage}\\[3ex]\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have A sorry %noproof
  then have "A \<or> B" ..

  have B sorry %noproof
  then have "A \<or> B" ..

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "A \<or> B" sorry %noproof
  then have C
  proof
    assume A
    then show C sorry %noproof
  next
    assume B
    then show C sorry %noproof
  qed

  text_raw \<open>\end{minipage}\\[3ex]\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have A and B sorry %noproof
  then have "A \<and> B" ..

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "A \<and> B" sorry %noproof
  then obtain A and B ..

  text_raw \<open>\end{minipage}\\[3ex]\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<bottom>" sorry %noproof
  then have A ..

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<top>" ..

  text_raw \<open>\end{minipage}\\[3ex]\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<not> A"
  proof
    assume A
    then show "\<bottom>" sorry %noproof
  qed

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<not> A" and A sorry %noproof
  then have B ..

  text_raw \<open>\end{minipage}\\[3ex]\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<forall>x. B x"
  proof
    fix x
    show "B x" sorry %noproof
  qed

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<forall>x. B x" sorry %noproof
  then have "B a" ..

  text_raw \<open>\end{minipage}\\[3ex]\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<exists>x. B x"
  proof
    show "B a" sorry %noproof
  qed

  text_raw \<open>\end{minipage}\qquad\begin{minipage}[t]{0.4\textwidth}\<close>(*<*)next(*>*)

  have "\<exists>x. B x" sorry %noproof
  then obtain a where "B a" ..

  text_raw \<open>\end{minipage}\<close>

(*<*)
qed
(*>*)

text \<open>
  \bigskip\noindent Of course, these proofs are merely examples.  As
  sketched in \secref{sec:framework-subproof}, there is a fair amount
  of flexibility in expressing Pure deductions in Isar.  Here the user
  is asked to express himself adequately, aiming at proof texts of
  literary quality.
\<close>

end %visible
