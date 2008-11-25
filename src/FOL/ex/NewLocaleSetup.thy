(*  Title:      FOL/ex/NewLocaleSetup.thy
    ID:         $Id$
    Author:     Clemens Ballarin, TU Muenchen

Testing environment for locale expressions --- experimental.
*)

theory NewLocaleSetup
imports FOL
begin

ML {*

local

structure P = OuterParse and K = OuterKeyword;
val opt_bang = Scan.optional (P.$$$ "!" >> K true) false;

val locale_val =
  Expression.parse_expression --
    Scan.optional (P.$$$ "+" |-- P.!!! (Scan.repeat1 SpecParse.context_element)) [] ||
  Scan.repeat1 SpecParse.context_element >> pair ([], []);

in

val _ =
  OuterSyntax.command "locale" "define named proof context" K.thy_decl
    (P.name -- Scan.optional (P.$$$ "=" |-- P.!!! locale_val) (([], []), []) -- P.opt_begin
      >> (fn ((name, (expr, elems)), begin) =>
          (begin ? Toplevel.print) o Toplevel.begin_local_theory begin
            (Expression.add_locale name name expr elems #-> TheoryTarget.begin)));

val _ =
  OuterSyntax.improper_command "print_locales" "print locales of this theory" K.diag
    (Scan.succeed (Toplevel.no_timing o (Toplevel.unknown_theory o
  Toplevel.keep (NewLocale.print_locales o Toplevel.theory_of))));

val _ = OuterSyntax.improper_command "print_locale" "print named locale in this theory" K.diag
  (opt_bang -- P.xname >> (Toplevel.no_timing oo (fn (show_facts, name) =>
   Toplevel.unknown_theory o Toplevel.keep (fn state =>
     NewLocale.print_locale (Toplevel.theory_of state) show_facts name))));

end

*}

end
