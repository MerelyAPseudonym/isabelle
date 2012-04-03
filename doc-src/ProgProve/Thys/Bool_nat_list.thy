(*<*)
theory Bool_nat_list
imports Main
begin
(*>*)

text{*
\vspace{-4ex}
\section{\texorpdfstring{Types @{typ bool}, @{typ nat} and @{text list}}{Types bool, nat and list}}

These are the most important predefined types. We go through them one by one.
Based on examples we learn how to define (possibly recursive) functions and
prove theorems about them by induction and simplification.

\subsection{Type @{typ bool}}

The type of boolean values is a predefined datatype
@{datatype[display] bool}
with the two values @{const True} and @{const False} and
with many predefined functions:  @{text "\<not>"}, @{text "\<and>"}, @{text "\<or>"}, @{text
"\<longrightarrow>"} etc. Here is how conjunction could be defined by pattern matching:
*}

fun conj :: "bool \<Rightarrow> bool \<Rightarrow> bool" where
"conj True True = True" |
"conj _ _ = False"

text{* Both the datatype and function definitions roughly follow the syntax
of functional programming languages.

\subsection{Type @{typ nat}}

Natural numbers are another predefined datatype:
@{datatype[display] nat}
All values of type @{typ nat} are generated by the constructors
@{text 0} and @{const Suc}. Thus the values of type @{typ nat} are
@{text 0}, @{term"Suc 0"}, @{term"Suc(Suc 0)"} etc.
There are many predefined functions: @{text "+"}, @{text "*"}, @{text
"\<le>"}, etc. Here is how you could define your own addition:
*}

fun add :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
"add 0 n = n" |
"add (Suc m) n = Suc(add m n)"

text{* And here is a proof of the fact that @{prop"add m 0 = m"}: *}

lemma add_02: "add m 0 = m"
apply(induction m)
apply(auto)
done
(*<*)
lemma "add m 0 = m"
apply(induction m)
(*>*)
txt{* The \isacom{lemma} command starts the proof and gives the lemma
a name, @{text add_02}. Properties of recursively defined functions
need to be established by induction in most cases.
Command \isacom{apply}@{text"(induction m)"} instructs Isabelle to
start a proof by induction on @{text m}. In response, it will show the
following proof state:
@{subgoals[display,indent=0]}
The numbered lines are known as \emph{subgoals}.
The first subgoal is the base case, the second one the induction step.
The prefix @{text"\<And>m."} is Isabelle's way of saying ``for an arbitrary but fixed @{text m}''. The @{text"\<Longrightarrow>"} separates assumptions from the conclusion.
The command \isacom{apply}@{text"(auto)"} instructs Isabelle to try
and prove all subgoals automatically, essentially by simplifying them.
Because both subgoals are easy, Isabelle can do it.
The base case @{prop"add 0 0 = 0"} holds by definition of @{const add},
and the induction step is almost as simple:
@{text"add\<^raw:~>(Suc m) 0 = Suc(add m 0) = Suc m"}
using first the definition of @{const add} and then the induction hypothesis.
In summary, both subproofs rely on simplification with function definitions and
the induction hypothesis.
As a result of that final \isacom{done}, Isabelle associates the lemma
just proved with its name. You can now inspect the lemma with the command
*}

thm add_02

txt{* which displays @{thm[show_question_marks,display] add_02} The free
variable @{text m} has been replaced by the \concept{unknown}
@{text"?m"}. There is no logical difference between the two but an
operational one: unknowns can be instantiated, which is what you want after
some lemma has been proved.

Note that there is also a proof method @{text induct}, which behaves almost
like @{text induction}; the difference is explained in \autoref{ch:Isar}.

\begin{warn}
Terminology: We use \concept{lemma}, \concept{theorem} and \concept{rule}
interchangeably for propositions that have been proved.
\end{warn}
\begin{warn}
  Numerals (@{text 0}, @{text 1}, @{text 2}, \dots) and most of the standard
  arithmetic operations (@{text "+"}, @{text "-"}, @{text "*"}, @{text"\<le>"},
  @{text"<"} etc) are overloaded: they are available
  not just for natural numbers but for other types as well.
  For example, given the goal @{text"x + 0 = x"}, there is nothing to indicate
  that you are talking about natural numbers. Hence Isabelle can only infer
  that @{term x} is of some arbitrary type where @{text 0} and @{text"+"}
  exist. As a consequence, you will be unable to prove the
  goal. To alert you to such pitfalls, Isabelle flags numerals without a
  fixed type in its output: @{prop"x+0 = x"}.  In this particular example,
  you need to include
  an explicit type constraint, for example @{text"x+0 = (x::nat)"}. If there
  is enough contextual information this may not be necessary: @{prop"Suc x =
  x"} automatically implies @{text"x::nat"} because @{term Suc} is not
  overloaded.
\end{warn}

\subsubsection{An informal proof}

Above we gave some terse informal explanation of the proof of
@{prop"add m 0 = m"}. A more detailed informal exposition of the lemma
might look like this:
\bigskip

\noindent
\textbf{Lemma} @{prop"add m 0 = m"}

\noindent
\textbf{Proof} by induction on @{text m}.
\begin{itemize}
\item Case @{text 0} (the base case): @{prop"add 0 0 = 0"}
  holds by definition of @{const add}.
\item Case @{term"Suc m"} (the induction step):
  We assume @{prop"add m 0 = m"}, the induction hypothesis (IH),
  and we need to show @{text"add (Suc m) 0 = Suc m"}.
  The proof is as follows:\smallskip

  \begin{tabular}{@ {}rcl@ {\quad}l@ {}}
  @{term "add (Suc m) 0"} &@{text"="}& @{term"Suc(add m 0)"}
  & by definition of @{text add}\\
              &@{text"="}& @{term "Suc m"} & by IH
  \end{tabular}
\end{itemize}
Throughout this book, \concept{IH} will stand for ``induction hypothesis''.

We have now seen three proofs of @{prop"add m 0 = 0"}: the Isabelle one, the
terse 4 lines explaining the base case and the induction step, and just now a
model of a traditional inductive proof. The three proofs differ in the level
of detail given and the intended reader: the Isabelle proof is for the
machine, the informal proofs are for humans. Although this book concentrates
of Isabelle proofs, it is important to be able to rephrase those proofs
as informal text comprehensible to a reader familiar with traditional
mathematical proofs. Later on we will introduce an Isabelle proof language
that is closer to traditional informal mathematical language and is often
directly readable.

\subsection{Type @{text list}}

Although lists are already predefined, we define our own copy just for
demonstration purposes:
*}
(*<*)
apply(auto)
done 
declare [[names_short]]
(*>*)
datatype 'a list = Nil | Cons 'a "'a list"

text{*
\begin{itemize}
\item Type @{typ "'a list"} is the type of list over elements of type @{typ 'a}. Because @{typ 'a} is a type variable, lists are in fact \concept{polymorphic}: the elements of a list can be of arbitrary type (but must all be of the same type).
\item Lists have two constructors: @{const Nil}, the empty list, and @{const Cons}, which puts an element (of type @{typ 'a}) in front of a list (of type @{typ "'a list"}).
Hence all lists are of the form @{const Nil}, or @{term"Cons x Nil"},
or @{term"Cons x (Cons y Nil)"} etc.
\item \isacom{datatype} requires no quotation marks on the
left-hand side, but on the right-hand side each of the argument
types of a constructor needs to be enclosed in quotation marks, unless
it is just an identifier (e.g.\ @{typ nat} or @{typ 'a}).
\end{itemize}
We also define two standard functions, append and reverse: *}

fun app :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
"app Nil ys = ys" |
"app (Cons x xs) ys = Cons x (app xs ys)"

fun rev :: "'a list \<Rightarrow> 'a list" where
"rev Nil = Nil" |
"rev (Cons x xs) = app (rev xs) (Cons x Nil)"

text{* By default, variables @{text xs}, @{text ys} and @{text zs} are of
@{text list} type.

Command \isacom{value} evaluates a term. For example, *}

value "rev(Cons True (Cons False Nil))"

text{* yields the result @{value "rev(Cons True (Cons False Nil))"}. This works symbolically, too: *}

value "rev(Cons a (Cons b Nil))"

text{* yields @{value "rev(Cons a (Cons b Nil))"}.
\medskip

Figure~\ref{fig:MyList} shows the theory created so far.
% Notice where the
%quotations marks are needed that we mostly sweep under the carpet.  In
%particular, notice that \isacom{datatype} requires no quotation marks on the
%left-hand side, but that on the right-hand side each of the argument
%types of a constructor needs to be enclosed in quotation marks.

\begin{figure}[htbp]
\begin{alltt}
\input{Thys/MyList.thy}\end{alltt}
\caption{A Theory of Lists}
\label{fig:MyList}
\end{figure}

\subsubsection{Structural Induction for Lists}

Just as for natural numbers, there is a proof principle of induction for
lists. Induction over a list is essentially induction over the length of
the list, although the length remains implicit. To prove that some property
@{text P} holds for all lists @{text xs}, i.e.\ \mbox{@{prop"P(xs)"}},
you need to prove
\begin{enumerate}
\item the base case @{prop"P(Nil)"} and
\item the inductive case @{prop"P(Cons x xs)"} under the assumption @{prop"P(xs)"}, for some arbitrary but fixed @{text xs}.
\end{enumerate}
This is often called \concept{structural induction}.

\subsection{The Proof Process}

We will now demonstrate the typical proof process, which involves
the formulation and proof of auxiliary lemmas.
Our goal is to show that reversing a list twice produces the original
list. *}

theorem rev_rev [simp]: "rev(rev xs) = xs"

txt{* Commands \isacom{theorem} and \isacom{lemma} are
interchangeable and merely indicate the importance we attach to a
proposition. Via the bracketed attribute @{text simp} we also tell Isabelle
to make the eventual theorem a \concept{simplification rule}: future proofs
involving simplification will replace occurrences of @{term"rev(rev xs)"} by
@{term"xs"}. The proof is by induction: *}

apply(induction xs)

txt{*
As explained above, we obtain two subgoals, namely the base case (@{const Nil}) and the induction step (@{const Cons}):
@{subgoals[display,indent=0,margin=65]}
Let us try to solve both goals automatically:
*}

apply(auto)

txt{*Subgoal~1 is proved, and disappears; the simplified version
of subgoal~2 becomes the new subgoal~1:
@{subgoals[display,indent=0,margin=70]}
In order to simplify this subgoal further, a lemma suggests itself.

\subsubsection{A First Lemma}

We insert the following lemma in front of the main theorem:
*}
(*<*)
oops
(*>*)
lemma rev_app [simp]: "rev(app xs ys) = app (rev ys) (rev xs)"

txt{* There are two variables that we could induct on: @{text xs} and
@{text ys}. Because @{const app} is defined by recursion on
the first argument, @{text xs} is the correct one:
*}

apply(induction xs)

txt{* This time not even the base case is solved automatically: *}
apply(auto)
txt{*
\vspace{-5ex}
@{subgoals[display,goals_limit=1]}
Again, we need to abandon this proof attempt and prove another simple lemma
first.

\subsubsection{A Second Lemma}

We again try the canonical proof procedure:
*}
(*<*)
oops
(*>*)
lemma app_Nil2 [simp]: "app xs Nil = xs"
apply(induction xs)
apply(auto)
done

text{*
Thankfully, this worked.
Now we can continue with our stuck proof attempt of the first lemma:
*}

lemma rev_app [simp]: "rev(app xs ys) = app (rev ys) (rev xs)"
apply(induction xs)
apply(auto)

txt{*
We find that this time @{text"auto"} solves the base case, but the
induction step merely simplifies to
@{subgoals[display,indent=0,goals_limit=1]}
The the missing lemma is associativity of @{const app},
which we insert in front of the failed lemma @{text rev_app}.

\subsubsection{Associativity of @{const app}}

The canonical proof procedure succeeds without further ado:
*}
(*<*)oops(*>*)
lemma app_assoc [simp]: "app (app xs ys) zs = app xs (app ys zs)"
apply(induction xs)
apply(auto)
done
(*<*)
lemma rev_app [simp]: "rev(app xs ys) = app (rev ys)(rev xs)"
apply(induction xs)
apply(auto)
done

theorem rev_rev [simp]: "rev(rev xs) = xs"
apply(induction xs)
apply(auto)
done
(*>*)
text{*
Finally the proofs of @{thm[source] rev_app} and @{thm[source] rev_rev}
succeed, too.

\subsubsection{Another informal proof}

Here is the informal proof of associativity of @{const app}
corresponding to the Isabelle proof above.
\bigskip

\noindent
\textbf{Lemma} @{prop"app (app xs ys) zs = app xs (app ys zs)"}

\noindent
\textbf{Proof} by induction on @{text xs}.
\begin{itemize}
\item Case @{text Nil}: \ @{prop"app (app Nil ys) zs = app ys zs"} @{text"="}
  \mbox{@{term"app Nil (app ys zs)"}} \ holds by definition of @{text app}.
\item Case @{text"Cons x xs"}: We assume
  \begin{center} \hfill @{term"app (app xs ys) zs"} @{text"="}
  @{term"app xs (app ys zs)"} \hfill (IH) \end{center}
  and we need to show
  \begin{center} @{prop"app (app (Cons x xs) ys) zs = app (Cons x xs) (app ys zs)"}.\end{center}
  The proof is as follows:\smallskip

  \begin{tabular}{@ {}l@ {\quad}l@ {}}
  @{term"app (app (Cons x xs) ys) zs"}\\
  @{text"= app (Cons x (app xs ys)) zs"} & by definition of @{text app}\\
  @{text"= Cons x (app (app xs ys) zs)"} & by definition of @{text app}\\
  @{text"= Cons x (app xs (app ys zs))"} & by IH\\
  @{text"= app (Cons x xs) (app ys zs)"} & by definition of @{text app}
  \end{tabular}
\end{itemize}
\medskip

\noindent Didn't we say earlier that all proofs are by simplification? But
in both cases, going from left to right, the last equality step is not a
simplification at all! In the base case it is @{prop"app ys zs = app Nil (app
ys zs)"}. It appears almost mysterious because we suddenly complicate the
term by appending @{text Nil} on the left. What is really going on is this:
when proving some equality \mbox{@{prop"s = t"}}, both @{text s} and @{text t} are
simplified to some common term @{text u}.  This heuristic for equality proofs
works well for a functional programming context like ours. In the base case
@{text s} is @{term"app (app Nil ys) zs"}, @{text t} is @{term"app Nil (app
ys zs)"}, and @{text u} is @{term"app ys zs"}.

\subsection{Predefined lists}
\label{sec:predeflists}

Isabelle's predefined lists are the same as the ones above, but with
more syntactic sugar:
\begin{itemize}
\item @{text "[]"} is @{const Nil},
\item @{term"x # xs"} is @{term"Cons x xs"},
\item @{text"[x\<^isub>1, \<dots>, x\<^isub>n]"} is @{text"x\<^isub>1 # \<dots> # x\<^isub>n # []"}, and
\item @{term "xs @ ys"} is @{term"app xs ys"}.
\end{itemize}
There is also a large library of predefined functions.
The most important ones are the length function
@{text"length :: 'a list \<Rightarrow> nat"} (with the obvious definition),
and the map function that applies a function to all elements of a list:
\begin{isabelle}
\isacom{fun} @{const map} @{text"::"} @{typ[source] "('a \<Rightarrow> 'b) \<Rightarrow> 'a list \<Rightarrow> 'b list"}\\
@{text"\""}@{thm map.simps(1)}@{text"\" |"}\\
@{text"\""}@{thm map.simps(2)}@{text"\""}
\end{isabelle}
\sem
Also useful are the \concept{head} of a list, its first element,
and the \concept{tail}, the rest of the list:
\begin{isabelle}
\isacom{fun} @{text"hd :: 'a list \<Rightarrow> 'a"}\\
@{prop"hd(x#xs) = x"}
\end{isabelle}
\begin{isabelle}
\isacom{fun} @{text"tl :: 'a list \<Rightarrow> 'a list"}\\
@{prop"tl [] = []"} @{text"|"}\\
@{prop"tl(x#xs) = xs"}
\end{isabelle}
Note that since HOL is a logic of total functions, @{term"hd []"} is defined,
but we do now know what the result is. That is, @{term"hd []"} is not undefined
but underdefined.
\endsem
%
*}
(*<*)
end
(*>*)
