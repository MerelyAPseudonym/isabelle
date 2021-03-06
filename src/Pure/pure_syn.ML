(*  Title:      Pure/pure_syn.ML
    Author:     Makarius

Outer syntax for bootstrapping Isabelle/Pure.
*)

structure Pure_Syn: sig end =
struct

val _ =
  Outer_Syntax.command ("header", @{here}) "theory header"
    (Parse.document_source >> Thy_Output.old_header_command);

val _ =
  Outer_Syntax.command ("chapter", @{here}) "chapter heading"
    (Parse.opt_target -- Parse.document_source >> Thy_Output.document_command);

val _ =
  Outer_Syntax.command ("section", @{here}) "section heading"
    (Parse.opt_target -- Parse.document_source >> Thy_Output.document_command);

val _ =
  Outer_Syntax.command ("subsection", @{here}) "subsection heading"
    (Parse.opt_target -- Parse.document_source >> Thy_Output.document_command);

val _ =
  Outer_Syntax.command ("subsubsection", @{here}) "subsubsection heading"
    (Parse.opt_target -- Parse.document_source >> Thy_Output.document_command);

val _ =
  Outer_Syntax.command ("text", @{here}) "formal comment (primary style)"
    (Parse.opt_target -- Parse.document_source >> Thy_Output.document_command);

val _ =
  Outer_Syntax.command ("txt", @{here}) "formal comment (secondary style)"
    (Parse.opt_target -- Parse.document_source >> Thy_Output.document_command);

val _ =
  Outer_Syntax.command ("text_raw", @{here}) "raw LaTeX text"
    (Parse.document_source >> K (Toplevel.imperative I));

val _ =
  Outer_Syntax.command ("theory", @{here}) "begin theory"
    (Thy_Header.args >>
      (fn _ => Toplevel.init_theory (fn () => error "Missing theory initialization")));

end;

