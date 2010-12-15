(*  Title:      HOL/SMT.thy
    Author:     Sascha Boehme, TU Muenchen
*)

header {* Bindings to Satisfiability Modulo Theories (SMT) solvers *}

theory SMT
imports List
uses
  "Tools/Datatype/datatype_selectors.ML"
  "Tools/SMT/smt_utils.ML"
  "Tools/SMT/smt_failure.ML"
  "Tools/SMT/smt_config.ML"
  "Tools/SMT/smt_monomorph.ML"
  ("Tools/SMT/smt_builtin.ML")
  ("Tools/SMT/smt_normalize.ML")
  ("Tools/SMT/smt_translate.ML")
  ("Tools/SMT/smt_solver.ML")
  ("Tools/SMT/smtlib_interface.ML")
  ("Tools/SMT/z3_proof_parser.ML")
  ("Tools/SMT/z3_proof_tools.ML")
  ("Tools/SMT/z3_proof_literals.ML")
  ("Tools/SMT/z3_proof_methods.ML")
  ("Tools/SMT/z3_proof_reconstruction.ML")
  ("Tools/SMT/z3_model.ML")
  ("Tools/SMT/z3_interface.ML")
  ("Tools/SMT/smt_setup_solvers.ML")
begin



subsection {* Triggers for quantifier instantiation *}

text {*
Some SMT solvers support patterns as a quantifier instantiation
heuristics.  Patterns may either be positive terms (tagged by "pat")
triggering quantifier instantiations -- when the solver finds a
term matching a positive pattern, it instantiates the corresponding
quantifier accordingly -- or negative terms (tagged by "nopat")
inhibiting quantifier instantiations.  A list of patterns
of the same kind is called a multipattern, and all patterns in a
multipattern are considered conjunctively for quantifier instantiation.
A list of multipatterns is called a trigger, and their multipatterns
act disjunctively during quantifier instantiation.  Each multipattern
should mention at least all quantified variables of the preceding
quantifier block.
*}

datatype pattern = Pattern

definition pat :: "'a \<Rightarrow> pattern" where "pat _ = Pattern"
definition nopat :: "'a \<Rightarrow> pattern" where "nopat _ = Pattern"

definition trigger :: "pattern list list \<Rightarrow> bool \<Rightarrow> bool"
where "trigger _ P = P"



subsection {* Quantifier weights *}

text {*
Weight annotations to quantifiers influence the priority of quantifier
instantiations.  They should be handled with care for solvers, which support
them, because incorrect choices of weights might render a problem unsolvable.
*}

definition weight :: "int \<Rightarrow> bool \<Rightarrow> bool" where "weight _ P = P"

text {*
Weights must be non-negative.  The value @{text 0} is equivalent to providing
no weight at all.

Weights should only be used at quantifiers and only inside triggers (if the
quantifier has triggers).  Valid usages of weights are as follows:

\begin{itemize}
\item
@{term "\<forall>x. trigger [[pat (P x)]] (weight 2 (P x))"}
\item
@{term "\<forall>x. weight 3 (P x)"}
\end{itemize}
*}



subsection {* Higher-order encoding *}

text {*
Application is made explicit for constants occurring with varying
numbers of arguments.  This is achieved by the introduction of the
following constant.
*}

definition fun_app where "fun_app f = f"

text {*
Some solvers support a theory of arrays which can be used to encode
higher-order functions.  The following set of lemmas specifies the
properties of such (extensional) arrays.
*}

lemmas array_rules = ext fun_upd_apply fun_upd_same fun_upd_other
  fun_upd_upd fun_app_def



subsection {* First-order logic *}

text {*
Some SMT solvers only accept problems in first-order logic, i.e.,
where formulas and terms are syntactically separated. When
translating higher-order into first-order problems, all
uninterpreted constants (those not built-in in the target solver)
are treated as function symbols in the first-order sense.  Their
occurrences as head symbols in atoms (i.e., as predicate symbols) are
turned into terms by equating such atoms with @{term True}.
Whenever the boolean type occurs in first-order terms, it is replaced
by the following type.
*}

typedecl term_bool



subsection {* Integer division and modulo for Z3 *}

definition z3div :: "int \<Rightarrow> int \<Rightarrow> int" where
  "z3div k l = (if 0 \<le> l then k div l else -(k div (-l)))"

definition z3mod :: "int \<Rightarrow> int \<Rightarrow> int" where
  "z3mod k l = (if 0 \<le> l then k mod l else k mod (-l))"

lemma div_by_z3div:
  "\<forall>k l. k div l = (
    if k = 0 \<or> l = 0 then 0
    else if (0 < k \<and> 0 < l) \<or> (k < 0 \<and> 0 < l) then z3div k l
    else z3div (-k) (-l))"
  by (auto simp add: z3div_def trigger_def)

lemma mod_by_z3mod:
  "\<forall>k l. k mod l = (
    if l = 0 then k
    else if k = 0 then 0
    else if (0 < k \<and> 0 < l) \<or> (k < 0 \<and> 0 < l) then z3mod k l
    else - z3mod (-k) (-l))"
  by (auto simp add: z3mod_def trigger_def)



subsection {* Setup *}

use "Tools/SMT/smt_builtin.ML"
use "Tools/SMT/smt_normalize.ML"
use "Tools/SMT/smt_translate.ML"
use "Tools/SMT/smt_solver.ML"
use "Tools/SMT/smtlib_interface.ML"
use "Tools/SMT/z3_interface.ML"
use "Tools/SMT/z3_proof_parser.ML"
use "Tools/SMT/z3_proof_tools.ML"
use "Tools/SMT/z3_proof_literals.ML"
use "Tools/SMT/z3_proof_methods.ML"
use "Tools/SMT/z3_proof_reconstruction.ML"
use "Tools/SMT/z3_model.ML"
use "Tools/SMT/smt_setup_solvers.ML"

setup {*
  SMT_Config.setup #>
  SMT_Normalize.setup #>
  SMT_Solver.setup #>
  SMTLIB_Interface.setup #>
  Z3_Interface.setup #>
  Z3_Proof_Reconstruction.setup #>
  SMT_Setup_Solvers.setup
*}



subsection {* Configuration *}

text {*
The current configuration can be printed by the command
@{text smt_status}, which shows the values of most options.
*}



subsection {* General configuration options *}

text {*
The option @{text smt_solver} can be used to change the target SMT
solver.  The possible values are @{text cvc3}, @{text yices}, and
@{text z3}.  It is advisable to locally install the selected solver,
although this is not necessary for @{text cvc3} and @{text z3}, which
can also be used over an Internet-based service.

When using local SMT solvers, the path to their binaries should be
declared by setting the following environment variables:
@{text CVC3_SOLVER}, @{text YICES_SOLVER}, and @{text Z3_SOLVER}.
*}

declare [[ smt_solver = z3 ]]

text {*
Since SMT solvers are potentially non-terminating, there is a timeout
(given in seconds) to restrict their runtime.  A value greater than
120 (seconds) is in most cases not advisable.
*}

declare [[ smt_timeout = 20 ]]

text {*
SMT solvers apply randomized heuristics.  In case a problem is not
solvable by an SMT solver, changing the following option might help.
*}

declare [[ smt_random_seed = 1 ]]

text {*
In general, the binding to SMT solvers runs as an oracle, i.e, the SMT
solvers are fully trusted without additional checks.  The following
option can cause the SMT solver to run in proof-producing mode, giving
a checkable certificate.  This is currently only implemented for Z3.
*}

declare [[ smt_oracle = false ]]

text {*
Each SMT solver provides several commandline options to tweak its
behaviour.  They can be passed to the solver by setting the following
options.
*}

declare [[ cvc3_options = "", yices_options = "", z3_options = "" ]]

text {*
Enable the following option to use built-in support for datatypes and
records.  Currently, this is only implemented for Z3 running in oracle
mode.
*}

declare [[ smt_datatypes = false ]]

text {*
The SMT method provides an inference mechanism to detect simple triggers
in quantified formulas, which might increase the number of problems
solvable by SMT solvers (note: triggers guide quantifier instantiations
in the SMT solver).  To turn it on, set the following option.
*}

declare [[ smt_infer_triggers = false ]]

text {*
The SMT method monomorphizes the given facts, that is, it tries to
instantiate all schematic type variables with fixed types occurring
in the problem.  This is a (possibly nonterminating) fixed-point
construction whose cycles are limited by the following option.
*}

declare [[ smt_monomorph_limit = 10 ]]



subsection {* Certificates *}

text {*
By setting the option @{text smt_certificates} to the name of a file,
all following applications of an SMT solver a cached in that file.
Any further application of the same SMT solver (using the very same
configuration) re-uses the cached certificate instead of invoking the
solver.  An empty string disables caching certificates.

The filename should be given as an explicit path.  It is good
practice to use the name of the current theory (with ending
@{text ".certs"} instead of @{text ".thy"}) as the certificates file.
*}

declare [[ smt_certificates = "" ]]

text {*
The option @{text smt_fixed} controls whether only stored
certificates are should be used or invocation of an SMT solver is
allowed.  When set to @{text true}, no SMT solver will ever be
invoked and only the existing certificates found in the configured
cache are used;  when set to @{text false} and there is no cached
certificate for some proposition, then the configured SMT solver is
invoked.
*}

declare [[ smt_fixed = false ]]



subsection {* Tracing *}

text {*
The SMT method, when applied, traces important information.  To
make it entirely silent, set the following option to @{text false}.
*}

declare [[ smt_verbose = true ]]

text {*
For tracing the generated problem file given to the SMT solver as
well as the returned result of the solver, the option
@{text smt_trace} should be set to @{text true}.
*}

declare [[ smt_trace = false ]]

text {*
From the set of assumptions given to the SMT solver, those assumptions
used in the proof are traced when the following option is set to
@{term true}.  This only works for Z3 when it runs in non-oracle mode
(see options @{text smt_solver} and @{text smt_oracle} above).
*}

declare [[ smt_trace_used_facts = false ]]



subsection {* Schematic rules for Z3 proof reconstruction *}

text {*
Several prof rules of Z3 are not very well documented.  There are two
lemma groups which can turn failing Z3 proof reconstruction attempts
into succeeding ones: the facts in @{text z3_rule} are tried prior to
any implemented reconstruction procedure for all uncertain Z3 proof
rules;  the facts in @{text z3_simp} are only fed to invocations of
the simplifier when reconstructing theory-specific proof steps.
*}

lemmas [z3_rule] =
  refl eq_commute conj_commute disj_commute simp_thms nnf_simps
  ring_distribs field_simps times_divide_eq_right times_divide_eq_left
  if_True if_False not_not

lemma [z3_rule]:
  "(P \<longrightarrow> Q) = (Q \<or> \<not>P)"
  "(\<not>P \<longrightarrow> Q) = (P \<or> Q)"
  "(\<not>P \<longrightarrow> Q) = (Q \<or> P)"
  by auto

lemma [z3_rule]:
  "((P = Q) \<longrightarrow> R) = (R | (Q = (\<not>P)))"
  by auto

lemma [z3_rule]:
  "((\<not>P) = P) = False"
  "(P = (\<not>P)) = False"
  "(P \<noteq> Q) = (Q = (\<not>P))"
  "(P = Q) = ((\<not>P \<or> Q) \<and> (P \<or> \<not>Q))"
  "(P \<noteq> Q) = ((\<not>P \<or> \<not>Q) \<and> (P \<or> Q))"
  by auto

lemma [z3_rule]:
  "(if P then P else \<not>P) = True"
  "(if \<not>P then \<not>P else P) = True"
  "(if P then True else False) = P"
  "(if P then False else True) = (\<not>P)"
  "(if \<not>P then x else y) = (if P then y else x)"
  "f (if P then x else y) = (if P then f x else f y)"
  by auto

lemma [z3_rule]:
  "P = Q \<or> P \<or> Q"
  "P = Q \<or> \<not>P \<or> \<not>Q"
  "(\<not>P) = Q \<or> \<not>P \<or> Q"
  "(\<not>P) = Q \<or> P \<or> \<not>Q"
  "P = (\<not>Q) \<or> \<not>P \<or> Q"
  "P = (\<not>Q) \<or> P \<or> \<not>Q"
  "P \<noteq> Q \<or> P \<or> \<not>Q"
  "P \<noteq> Q \<or> \<not>P \<or> Q"
  "P \<noteq> (\<not>Q) \<or> P \<or> Q"
  "(\<not>P) \<noteq> Q \<or> P \<or> Q"
  "P \<or> Q \<or> P \<noteq> (\<not>Q)"
  "P \<or> Q \<or> (\<not>P) \<noteq> Q"
  "P \<or> \<not>Q \<or> P \<noteq> Q"
  "\<not>P \<or> Q \<or> P \<noteq> Q"
  by auto

lemma [z3_rule]:
  "0 + (x::int) = x"
  "x + 0 = x"
  "0 * x = 0"
  "1 * x = x"
  "x + y = y + x"
  by auto



hide_type term_bool
hide_type (open) pattern
hide_const Pattern fun_app
hide_const (open) trigger pat nopat weight z3div z3mod



subsection {* Selectors for datatypes *}

setup {* Datatype_Selectors.setup *}

declare [[ selector Pair 1 = fst, selector Pair 2 = snd ]]
declare [[ selector Cons 1 = hd, selector Cons 2 = tl ]]

end
