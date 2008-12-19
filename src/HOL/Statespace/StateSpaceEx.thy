(*  Title:      StateSpaceEx.thy
    ID:         $Id$
    Author:     Norbert Schirmer, TU Muenchen
*)

header {* Examples \label{sec:Examples} *}
theory StateSpaceEx
imports StateSpaceLocale StateSpaceSyntax

begin
(* FIXME: Use proper keywords file *)
(*<*)
syntax
 "_statespace_updates" :: "('a \<Rightarrow> 'b) \<Rightarrow> updbinds \<Rightarrow> ('a \<Rightarrow> 'b)" ("_\<langle>_\<rangle>" [900,0] 900)
(*>*)

text {* Did you ever dream about records with multiple inheritance.
Then you should definitely have a look at statespaces. They may be
what you are dreaming of. Or at least almost...
*}




text {* Isabelle allows to add new top-level commands to the
system. Building on the locale infrastructure, we provide a command
\isacommand{statespace} like this:*}

statespace vars =
  n::nat
  b::bool

print_locale vars_namespace
print_locale vars_valuetypes
print_locale vars

text {* \noindent This resembles a \isacommand{record} definition, 
but introduces sophisticated locale
infrastructure instead of HOL type schemes.  The resulting context
postulates two distinct names @{term "n"} and @{term "b"} and
projection~/ injection functions that convert from abstract values to
@{typ "nat"} and @{text "bool"}. The logical content of the locale is: *}

class_locale vars' =
  fixes n::'name and b::'name
  assumes "distinct [n, b]" 

  fixes project_nat::"'value \<Rightarrow> nat" and inject_nat::"nat \<Rightarrow> 'value"
  assumes "\<And>n. project_nat (inject_nat n) = n" 

  fixes project_bool::"'value \<Rightarrow> bool" and inject_bool::"bool \<Rightarrow> 'value"
  assumes "\<And>b. project_bool (inject_bool b) = b"
 
text {* \noindent The HOL predicate @{const "distinct"} describes
distinctness of all names in the context.  Locale @{text "vars'"}
defines the raw logical content that is defined in the state space
locale. We also maintain non-logical context information to support
the user:

\begin{itemize}

\item Syntax for state lookup and updates that automatically inserts
the corresponding projection and injection functions.

\item Setup for the proof tools that exploit the distinctness
information and the cancellation of projections and injections in
deductions and simplifications.

\end{itemize}

This extra-logical information is added to the locale in form of
declarations, which associate the name of a variable to the
corresponding projection and injection functions to handle the syntax
transformations, and a link from the variable name to the
corresponding distinctness theorem. As state spaces are merged or
extended there are multiple distinctness theorems in the context. Our
declarations take care that the link always points to the strongest
distinctness assumption.  With these declarations in place, a lookup
can be written as @{text "s\<cdot>n"}, which is translated to @{text
"project_nat (s n)"}, and an update as @{text "s\<langle>n := 2\<rangle>"}, which is
translated to @{text "s(n := inject_nat 2)"}. We can now establish the
following lemma: *}

lemma (in vars) foo: "s<n := 2>\<cdot>b = s\<cdot>b" by simp

text {* \noindent Here the simplifier was able to refer to
distinctness of @{term "b"} and @{term "n"} to solve the equation.
The resulting lemma is also recorded in locale @{text "vars"} for
later use and is automatically propagated to all its interpretations.
Here is another example: *}

statespace 'a varsX = vars [n=N, b=B] + vars + x::'a

text {* \noindent The state space @{text "varsX"} imports two copies
of the state space @{text "vars"}, where one has the variables renamed
to upper-case letters, and adds another variable @{term "x"} of type
@{typ "'a"}. This type is fixed inside the state space but may get
instantiated later on, analogous to type parameters of an ML-functor.
The distinctness assumption is now @{text "distinct [N, B, n, b, x]"},
from this we can derive both @{term "distinct [N,B]"} and @{term
"distinct [n,b]"}, the distinction assumptions for the two versions of
locale @{text "vars"} above.  Moreover we have all necessary
projection and injection assumptions available. These assumptions
together allow us to establish state space @{term "varsX"} as an
interpretation of both instances of locale @{term "vars"}. Hence we
inherit both variants of theorem @{text "foo"}: @{text "s\<langle>N := 2\<rangle>\<cdot>B =
s\<cdot>B"} as well as @{text "s\<langle>n := 2\<rangle>\<cdot>b = s\<cdot>b"}. These are immediate
consequences of the locale interpretation action.

The declarations for syntax and the distinctness theorems also observe
the morphisms generated by the locale package due to the renaming
@{term "n = N"}: *}

lemma (in varsX) foo: "s\<langle>N := 2\<rangle>\<cdot>x = s\<cdot>x" by simp

text {* To assure scalability towards many distinct names, the
distinctness predicate is refined to operate on balanced trees. Thus
we get logarithmic certificates for the distinctness of two names by
the distinctness of the paths in the tree. Asked for the distinctness
of two names, our tool produces the paths of the variables in the tree
(this is implemented in SML, outside the logic) and returns a
certificate corresponding to the different paths.  Merging state
spaces requires to prove that the combined distinctness assumption
implies the distinctness assumptions of the components.  Such a proof
is of the order $m \cdot \log n$, where $n$ and $m$ are the number of
nodes in the larger and smaller tree, respectively.*}

text {* We continue with more examples. *}

statespace 'a foo = 
  f::"nat\<Rightarrow>nat"
  a::int
  b::nat
  c::'a



lemma (in foo) foo1: 
  shows "s\<langle>a := i\<rangle>\<cdot>a = i"
  by simp

lemma (in foo) foo2: 
  shows "(s\<langle>a:=i\<rangle>)\<cdot>a = i"
  by simp

lemma (in foo) foo3: 
  shows "(s\<langle>a:=i\<rangle>)\<cdot>b = s\<cdot>b"
  by simp

lemma (in foo) foo4: 
  shows "(s\<langle>a:=i,b:=j,c:=k,a:=x\<rangle>) = (s\<langle>b:=j,c:=k,a:=x\<rangle>)"
  by simp

statespace bar =
  b::bool
  c::string

lemma (in bar) bar1: 
  shows "(s\<langle>b:=True\<rangle>)\<cdot>c = s\<cdot>c"
  by simp

text {* You can define a derived state space by inheriting existing state spaces, renaming
of components if you like, and by declaring new components.
*}

statespace ('a,'b) loo = 'a foo + bar [b=B,c=C] +
  X::'b

lemma (in loo) loo1: 
  shows "s\<langle>a:=i\<rangle>\<cdot>B = s\<cdot>B"
proof -
  thm foo1
  txt {* The Lemma @{thm [source] foo1} from the parent state space 
         is also available here: \begin{center}@{thm foo1}\end{center}.*}
  have "s<a:=i>\<cdot>a = i"
    by (rule foo1)
  thm bar1
  txt {* Note the renaming of the parameters in Lemma @{thm [source] bar1}: 
         \begin{center}@{thm bar1}\end{center}.*}
  have "s<B:=True>\<cdot>C = s\<cdot>C"
    by (rule bar1)
  show ?thesis
    by simp
qed


statespace 'a dup = 'a foo [f=F, a=A] + 'a foo +
  x::int

lemma (in dup)
 shows "s<a := i>\<cdot>x = s\<cdot>x"
  by simp

lemma (in dup)
 shows "s<A := i>\<cdot>a = s\<cdot>a"
  by simp

lemma (in dup)
 shows "s<A := i>\<cdot>x = s\<cdot>x"
  by simp


text {* Hmm, I hoped this would work now...*}

(*
locale fooX = foo +
 assumes "s<a:=i>\<cdot>b = k"
*)

(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)
text {* There are known problems with syntax-declarations. They currently
only work, when the context is already built. Hopefully this will be 
implemented correctly in future Isabelle versions. *}

(*
lemma 
  assumes "foo f a b c p1 i1 p2 i2 p3 i3 p4 i4"
  shows True
proof
  interpret foo [f a b c p1 i1 p2 i2 p3 i3 p4 i4] by fact
  term "s<a := i>\<cdot>a = i"
qed
*)
(*
lemma 
  includes foo
  shows "s<a := i>\<cdot>a = i"
*)

text {* It would be nice to have nested state spaces. This is
logically no problem. From the locale-implementation side this may be
something like an 'includes' into a locale. When there is a more
elaborate locale infrastructure in place this may be an easy exercise.
*} 

end
