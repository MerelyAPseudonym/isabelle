(*  Title:      HOL/Tools/SMT/smt_systems.ML
    Author:     Sascha Boehme, TU Muenchen

Setup SMT solvers.
*)

signature SMT_SYSTEMS =
sig
  datatype z3_non_commercial =
    Z3_Non_Commercial_Unknown |
    Z3_Non_Commercial_Accepted |
    Z3_Non_Commercial_Declined
  val z3_non_commercial: unit -> z3_non_commercial
  val z3_extensions: bool Config.T
end;

structure SMT_Systems: SMT_SYSTEMS =
struct

(* helper functions *)

fun make_avail name () = getenv (name ^ "_SOLVER") <> ""

fun make_command name () = [getenv (name ^ "_SOLVER")]

fun outcome_of unsat sat unknown solver_name line =
  if String.isPrefix unsat line then SMT_Solver.Unsat
  else if String.isPrefix sat line then SMT_Solver.Sat
  else if String.isPrefix unknown line then SMT_Solver.Unknown
  else raise SMT_Failure.SMT (SMT_Failure.Other_Failure ("Solver " ^ quote solver_name ^
    " failed -- enable tracing using the " ^ quote (Config.name_of SMT_Config.trace) ^
    " option for details"))

fun on_first_line test_outcome solver_name lines =
  let
    val split_first = (fn [] => ("", []) | l :: ls => (l, ls))
    val (l, ls) = split_first (snd (take_prefix (curry (op =) "") lines))
  in (test_outcome solver_name l, ls) end

fun on_first_non_unsupported_line test_outcome solver_name lines =
  on_first_line test_outcome solver_name (filter (curry (op <>) "unsupported") lines)

(* CVC3 *)

local
  fun cvc3_options ctxt = [
    "-seed", string_of_int (Config.get ctxt SMT_Config.random_seed),
    "-lang", "smt2",
    "-timeout", string_of_int (Real.ceil (Config.get ctxt SMT_Config.timeout))]
in

val cvc3: SMT_Solver.solver_config = {
  name = "cvc3",
  class = K SMTLIB_Interface.smtlibC,
  avail = make_avail "CVC3",
  command = make_command "CVC3",
  options = cvc3_options,
  smt_options = [],
  default_max_relevant = 400 (* FUDGE *),
  outcome = on_first_line (outcome_of "unsat" "sat" "unknown"),
  parse_proof = NONE,
  replay = NONE }

end


(* CVC4 *)

val cvc4_extensions = Attrib.setup_config_bool @{binding cvc4_extensions} (K false)

local
  fun cvc4_options ctxt = [
    "--random-seed=" ^ string_of_int (Config.get ctxt SMT_Config.random_seed),
    "--lang=smt2",
    "--tlimit", string_of_int (Real.ceil (1000.0 * Config.get ctxt SMT_Config.timeout))]

  fun select_class ctxt =
    if Config.get ctxt cvc4_extensions then CVC4_Interface.smtlib_cvc4C
    else SMTLIB_Interface.smtlibC
in

val cvc4: SMT_Solver.solver_config = {
  name = "cvc4",
  class = select_class,
  avail = make_avail "CVC4",
  command = make_command "CVC4",
  options = cvc4_options,
  smt_options = [(":produce-unsat-cores", "true")],
  default_max_relevant = 400 (* FUDGE *),
  outcome = on_first_line (outcome_of "unsat" "sat" "unknown"),
  parse_proof = SOME (K CVC4_Proof_Parse.parse_proof),
  replay = NONE }

end

(* veriT *)

val veriT: SMT_Solver.solver_config = {
  name = "verit",
  class = K SMTLIB_Interface.smtlibC,
  avail = make_avail "VERIT",
  command = make_command "VERIT",
  options = (fn ctxt => [
    "--proof-version=1",
    "--proof=-",
    "--proof-prune",
    "--proof-merge",
    "--disable-print-success",
    "--disable-banner",
    "--max-time=" ^ string_of_int (Real.ceil (Config.get ctxt SMT_Config.timeout))]),
  smt_options = [],
  default_max_relevant = 200 (* FUDGE *),
  outcome = on_first_non_unsupported_line (outcome_of "unsat" "sat"
    "warning : proof_done: status is still open"),
  parse_proof = SOME (K VeriT_Proof_Parse.parse_proof),
  replay = NONE }

(* Z3 *)

datatype z3_non_commercial =
  Z3_Non_Commercial_Unknown |
  Z3_Non_Commercial_Accepted |
  Z3_Non_Commercial_Declined

local
  val accepted = member (op =) ["yes", "Yes", "YES"]
  val declined = member (op =) ["no", "No", "NO"]
in

fun z3_non_commercial () =
  let
    val flag1 = Options.default_string @{system_option z3_non_commercial}
    val flag2 = getenv "Z3_NON_COMMERCIAL"
  in
    if accepted flag1 then Z3_Non_Commercial_Accepted
    else if declined flag1 then Z3_Non_Commercial_Declined
    else if accepted flag2 then Z3_Non_Commercial_Accepted
    else if declined flag2 then Z3_Non_Commercial_Declined
    else Z3_Non_Commercial_Unknown
  end

fun if_z3_non_commercial f =
  (case z3_non_commercial () of
    Z3_Non_Commercial_Accepted => f ()
  | Z3_Non_Commercial_Declined =>
      error (Pretty.string_of (Pretty.para
        "The SMT solver Z3 may be used only for non-commercial applications."))
  | Z3_Non_Commercial_Unknown =>
      error (Pretty.string_of (Pretty.para
        ("The SMT solver Z3 is not activated. To activate it, set the Isabelle \
         \system option \"z3_non_commercial\" to \"yes\" (e.g. via \
         \the Isabelle/jEdit menu Plugin Options / Isabelle / General)."))))

end

val z3_extensions = Attrib.setup_config_bool @{binding z3_extensions} (K false)

local
  fun z3_make_command name () = if_z3_non_commercial (make_command name)

  fun z3_options ctxt =
    ["smt.random_seed=" ^ string_of_int (Config.get ctxt SMT_Config.random_seed),
     "smt.refine_inj_axioms=false",
     "-T:" ^ string_of_int (Real.ceil (Config.get ctxt SMT_Config.timeout)),
     "-smt2"]

  fun select_class ctxt =
    if Config.get ctxt z3_extensions then Z3_Interface.smtlib_z3C else SMTLIB_Interface.smtlibC
in

val z3: SMT_Solver.solver_config = {
  name = "z3",
  class = select_class,
  avail = make_avail "Z3_NEW",
  command = z3_make_command "Z3_NEW",
  options = z3_options,
  smt_options = [(":produce-proofs", "true")],
  default_max_relevant = 350 (* FUDGE *),
  outcome = on_first_line (outcome_of "unsat" "sat" "unknown"),
  parse_proof = SOME Z3_Replay.parse_proof,
  replay = SOME Z3_Replay.replay }

end


(* overall setup *)

val _ = Theory.setup (
  SMT_Solver.add_solver cvc3 #>
  SMT_Solver.add_solver cvc4 #>
  SMT_Solver.add_solver veriT #>
  SMT_Solver.add_solver z3)

end;
