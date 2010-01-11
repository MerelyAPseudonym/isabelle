(*<*)theory Mutual imports Main begin(*>*)

subsection{*Mutually Inductive Definitions*}

text{*
Just as there are datatypes defined by mutual recursion, there are sets defined
by mutual induction. As a trivial example we consider the even and odd
natural numbers:
*}

inductive_set
  Even :: "nat set" and
  Odd  :: "nat set"
where
  zero:  "0 \<in> Even"
| EvenI: "n \<in> Odd \<Longrightarrow> Suc n \<in> Even"
| OddI:  "n \<in> Even \<Longrightarrow> Suc n \<in> Odd"

text{*\noindent
The mutually inductive definition of multiple sets is no different from
that of a single set, except for induction: just as for mutually recursive
datatypes, induction needs to involve all the simultaneously defined sets. In
the above case, the induction rule is called @{thm[source]Even_Odd.induct}
(simply concatenate the names of the sets involved) and has the conclusion
@{text[display]"(?x \<in> Even \<longrightarrow> ?P ?x) \<and> (?y \<in> Odd \<longrightarrow> ?Q ?y)"}

If we want to prove that all even numbers are divisible by two, we have to
generalize the statement as follows:
*}

lemma "(m \<in> Even \<longrightarrow> 2 dvd m) \<and> (n \<in> Odd \<longrightarrow> 2 dvd (Suc n))"

txt{*\noindent
The proof is by rule induction. Because of the form of the induction theorem,
it is applied by @{text rule} rather than @{text erule} as for ordinary
inductive definitions:
*}

apply(rule Even_Odd.induct)

txt{*
@{subgoals[display,indent=0]}
The first two subgoals are proved by simplification and the final one can be
proved in the same manner as in \S\ref{sec:rule-induction}
where the same subgoal was encountered before.
We do not show the proof script.
*}
(*<*)
  apply simp
 apply simp
apply(simp add: dvd_def)
apply(clarify)
apply(rule_tac x = "Suc k" in exI)
apply simp
done
(*>*)

subsection{*Inductively Defined Predicates\label{sec:ind-predicates}*}

text{*\index{inductive predicates|(}
Instead of a set of even numbers one can also define a predicate on @{typ nat}:
*}

inductive evn :: "nat \<Rightarrow> bool" where
zero: "evn 0" |
step: "evn n \<Longrightarrow> evn(Suc(Suc n))"

text{*\noindent Everything works as before, except that
you write \commdx{inductive} instead of \isacommand{inductive\_set} and
@{prop"evn n"} instead of @{prop"n : even"}. The notation is more
lightweight but the usual set-theoretic operations, e.g. @{term"Even \<union> Odd"},
are not directly available on predicates.

When defining an n-ary relation as a predicate it is recommended to curry
the predicate: its type should be @{text"\<tau>\<^isub>1 \<Rightarrow> \<dots> \<Rightarrow> \<tau>\<^isub>n \<Rightarrow> bool"} rather than
@{text"\<tau>\<^isub>1 \<times> \<dots> \<times> \<tau>\<^isub>n \<Rightarrow> bool"}. The curried version facilitates inductions.
\index{inductive predicates|)}
*}

(*<*)end(*>*)
