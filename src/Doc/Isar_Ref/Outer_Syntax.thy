theory Outer_Syntax
imports Base Main
begin

chapter \<open>Outer syntax --- the theory language \label{ch:outer-syntax}\<close>

text \<open>
  The rather generic framework of Isabelle/Isar syntax emerges from
  three main syntactic categories: \emph{commands} of the top-level
  Isar engine (covering theory and proof elements), \emph{methods} for
  general goal refinements (analogous to traditional ``tactics''), and
  \emph{attributes} for operations on facts (within a certain
  context).  Subsequently we give a reference of basic syntactic
  entities underlying Isabelle/Isar syntax in a bottom-up manner.
  Concrete theory and proof language elements will be introduced later
  on.

  \medskip In order to get started with writing well-formed
  Isabelle/Isar documents, the most important aspect to be noted is
  the difference of \emph{inner} versus \emph{outer} syntax.  Inner
  syntax is that of Isabelle types and terms of the logic, while outer
  syntax is that of Isabelle/Isar theory sources (specifications and
  proofs).  As a general rule, inner syntax entities may occur only as
  \emph{atomic entities} within outer syntax.  For example, the string
  @{verbatim \<open>"x + y"\<close>} and identifier @{verbatim z} are legal term
  specifications within a theory, while @{verbatim "x + y"} without
  quotes is not.

  Printed theory documents usually omit quotes to gain readability
  (this is a matter of {\LaTeX} macro setup, say via @{verbatim
  "\\isabellestyle"}, see also @{cite "isabelle-sys"}).  Experienced
  users of Isabelle/Isar may easily reconstruct the lost technical
  information, while mere readers need not care about quotes at all.
\<close>


section \<open>Commands\<close>

text \<open>
  \begin{matharray}{rcl}
    @{command_def "print_commands"}@{text "\<^sup>*"} & : & @{text "any \<rightarrow>"} \\
    @{command_def "help"}@{text "\<^sup>*"} & : & @{text "any \<rightarrow>"} \\
  \end{matharray}

  @{rail \<open>
    @@{command help} (@{syntax name} * )
  \<close>}

  \begin{description}

  \item @{command "print_commands"} prints all outer syntax keywords
  and commands.

  \item @{command "help"}~@{text "pats"} retrieves outer syntax
  commands according to the specified name patterns.

  \end{description}
\<close>


subsubsection \<open>Examples\<close>

text \<open>Some common diagnostic commands are retrieved like this
  (according to usual naming conventions):\<close>

help "print"
help "find"


section \<open>Lexical matters \label{sec:outer-lex}\<close>

text \<open>The outer lexical syntax consists of three main categories of
  syntax tokens:

  \begin{enumerate}

  \item \emph{major keywords} --- the command names that are available
  in the present logic session;

  \item \emph{minor keywords} --- additional literal tokens required
  by the syntax of commands;

  \item \emph{named tokens} --- various categories of identifiers etc.

  \end{enumerate}

  Major keywords and minor keywords are guaranteed to be disjoint.
  This helps user-interfaces to determine the overall structure of a
  theory text, without knowing the full details of command syntax.
  Internally, there is some additional information about the kind of
  major keywords, which approximates the command type (theory command,
  proof command etc.).

  Keywords override named tokens.  For example, the presence of a
  command called @{verbatim term} inhibits the identifier @{verbatim
  term}, but the string @{verbatim \<open>"term"\<close>} can be used instead.
  By convention, the outer syntax always allows quoted strings in
  addition to identifiers, wherever a named entity is expected.

  When tokenizing a given input sequence, the lexer repeatedly takes
  the longest prefix of the input that forms a valid token.  Spaces,
  tabs, newlines and formfeeds between tokens serve as explicit
  separators.

  \medskip The categories for named tokens are defined once and for
  all as follows.

  \begin{center}
  \begin{supertabular}{rcl}
    @{syntax_def ident} & = & @{text "letter (subscript\<^sup>? quasiletter)\<^sup>*"} \\
    @{syntax_def longident} & = & @{text "ident("}@{verbatim "."}@{text "ident)\<^sup>+"} \\
    @{syntax_def symident} & = & @{text "sym\<^sup>+  |  "}@{verbatim \<open>\\<close>}@{verbatim "<"}@{text ident}@{verbatim ">"} \\
    @{syntax_def nat} & = & @{text "digit\<^sup>+"} \\
    @{syntax_def float} & = & @{syntax_ref nat}@{verbatim "."}@{syntax_ref nat}@{text "  |  "}@{verbatim "-"}@{syntax_ref nat}@{verbatim "."}@{syntax_ref nat} \\
    @{syntax_def var} & = & @{verbatim "?"}@{text "ident  |  "}@{verbatim "?"}@{text ident}@{verbatim "."}@{text nat} \\
    @{syntax_def typefree} & = & @{verbatim "'"}@{text ident} \\
    @{syntax_def typevar} & = & @{verbatim "?"}@{text "typefree  |  "}@{verbatim "?"}@{text typefree}@{verbatim "."}@{text nat} \\
    @{syntax_def string} & = & @{verbatim \<open>"\<close>} @{text "\<dots>"} @{verbatim \<open>"\<close>} \\
    @{syntax_def altstring} & = & @{verbatim "`"} @{text "\<dots>"} @{verbatim "`"} \\
    @{syntax_def cartouche} & = & @{verbatim "\<open>"} @{text "\<dots>"} @{verbatim "\<close>"} \\
    @{syntax_def verbatim} & = & @{verbatim "{*"} @{text "\<dots>"} @{verbatim "*}"} \\[1ex]

    @{text letter} & = & @{text "latin  |  "}@{verbatim \<open>\\<close>}@{verbatim "<"}@{text latin}@{verbatim ">"}@{text "  |  "}@{verbatim \<open>\\<close>}@{verbatim "<"}@{text "latin latin"}@{verbatim ">"}@{text "  |  greek  |"} \\
    @{text subscript} & = & @{verbatim "\<^sub>"} \\
    @{text quasiletter} & = & @{text "letter  |  digit  |  "}@{verbatim "_"}@{text "  |  "}@{verbatim "'"} \\
    @{text latin} & = & @{verbatim a}@{text "  | \<dots> |  "}@{verbatim z}@{text "  |  "}@{verbatim A}@{text "  |  \<dots> |  "}@{verbatim Z} \\
    @{text digit} & = & @{verbatim "0"}@{text "  |  \<dots> |  "}@{verbatim "9"} \\
    @{text sym} & = & @{verbatim "!"}@{text "  |  "}@{verbatim "#"}@{text "  |  "}@{verbatim "$"}@{text "  |  "}@{verbatim "%"}@{text "  |  "}@{verbatim "&"}@{text "  |  "}@{verbatim "*"}@{text "  |  "}@{verbatim "+"}@{text "  |  "}@{verbatim "-"}@{text "  |  "}@{verbatim "/"}@{text "  |"} \\
    & & @{verbatim "<"}@{text "  |  "}@{verbatim "="}@{text "  |  "}@{verbatim ">"}@{text "  |  "}@{verbatim "?"}@{text "  |  "}@{verbatim "@"}@{text "  |  "}@{verbatim "^"}@{text "  |  "}@{verbatim "_"}@{text "  |  "}@{verbatim "|"}@{text "  |  "}@{verbatim "~"} \\
    @{text greek} & = & @{verbatim "\<alpha>"}@{text "  |  "}@{verbatim "\<beta>"}@{text "  |  "}@{verbatim "\<gamma>"}@{text "  |  "}@{verbatim "\<delta>"}@{text "  |"} \\
          &   & @{verbatim "\<epsilon>"}@{text "  |  "}@{verbatim "\<zeta>"}@{text "  |  "}@{verbatim "\<eta>"}@{text "  |  "}@{verbatim "\<theta>"}@{text "  |"} \\
          &   & @{verbatim "\<iota>"}@{text "  |  "}@{verbatim "\<kappa>"}@{text "  |  "}@{verbatim "\<mu>"}@{text "  |  "}@{verbatim "\<nu>"}@{text "  |"} \\
          &   & @{verbatim "\<xi>"}@{text "  |  "}@{verbatim "\<pi>"}@{text "  |  "}@{verbatim "\<rho>"}@{text "  |  "}@{verbatim "\<sigma>"}@{text "  |  "}@{verbatim "\<tau>"}@{text "  |"} \\
          &   & @{verbatim "\<upsilon>"}@{text "  |  "}@{verbatim "\<phi>"}@{text "  |  "}@{verbatim "\<chi>"}@{text "  |  "}@{verbatim "\<psi>"}@{text "  |"} \\
          &   & @{verbatim "\<omega>"}@{text "  |  "}@{verbatim "\<Gamma>"}@{text "  |  "}@{verbatim "\<Delta>"}@{text "  |  "}@{verbatim "\<Theta>"}@{text "  |"} \\
          &   & @{verbatim "\<Lambda>"}@{text "  |  "}@{verbatim "\<Xi>"}@{text "  |  "}@{verbatim "\<Pi>"}@{text "  |  "}@{verbatim "\<Sigma>"}@{text "  |"} \\
          &   & @{verbatim "\<Upsilon>"}@{text "  |  "}@{verbatim "\<Phi>"}@{text "  |  "}@{verbatim "\<Psi>"}@{text "  |  "}@{verbatim "\<Omega>"} \\
  \end{supertabular}
  \end{center}

  A @{syntax_ref var} or @{syntax_ref typevar} describes an unknown,
  which is internally a pair of base name and index (ML type @{ML_type
  indexname}).  These components are either separated by a dot as in
  @{text "?x.1"} or @{text "?x7.3"} or run together as in @{text
  "?x1"}.  The latter form is possible if the base name does not end
  with digits.  If the index is 0, it may be dropped altogether:
  @{text "?x"} and @{text "?x0"} and @{text "?x.0"} all refer to the
  same unknown, with basename @{text "x"} and index 0.

  The syntax of @{syntax_ref string} admits any characters, including
  newlines; ``@{verbatim \<open>"\<close>}'' (double-quote) and ``@{verbatim \<open>\\<close>}''
  (backslash) need to be escaped by a backslash; arbitrary
  character codes may be specified as ``@{verbatim \<open>\\<close>}@{text ddd}'',
  with three decimal digits.  Alternative strings according to
  @{syntax_ref altstring} are analogous, using single back-quotes
  instead.

  The body of @{syntax_ref verbatim} may consist of any text not containing
  ``@{verbatim "*}"}''; this allows to include quotes without further
  escapes, but there is no way to escape ``@{verbatim "*}"}''. Cartouches
  do not have this limitation.

  A @{syntax_ref cartouche} consists of arbitrary text, with properly
  balanced blocks of ``@{verbatim "\<open>"}~@{text "\<dots>"}~@{verbatim
  "\<close>"}''.  Note that the rendering of cartouche delimiters is
  usually like this: ``@{text "\<open> \<dots> \<close>"}''.

  Source comments take the form @{verbatim "(*"}~@{text
  "\<dots>"}~@{verbatim "*)"} and may be nested, although the user-interface
  might prevent this.  Note that this form indicates source comments
  only, which are stripped after lexical analysis of the input.  The
  Isar syntax also provides proper \emph{document comments} that are
  considered as part of the text (see \secref{sec:comments}).

  Common mathematical symbols such as @{text \<forall>} are represented in
  Isabelle as @{verbatim \<forall>}.  There are infinitely many Isabelle
  symbols like this, although proper presentation is left to front-end
  tools such as {\LaTeX} or Isabelle/jEdit.  A list of
  predefined Isabelle symbols that work well with these tools is given
  in \appref{app:symbols}.  Note that @{verbatim "\<lambda>"} does not belong
  to the @{text letter} category, since it is already used differently
  in the Pure term language.\<close>


section \<open>Common syntax entities\<close>

text \<open>
  We now introduce several basic syntactic entities, such as names,
  terms, and theorem specifications, which are factored out of the
  actual Isar language elements to be described later.
\<close>


subsection \<open>Names\<close>

text \<open>Entity @{syntax name} usually refers to any name of types,
  constants, theorems etc.\ that are to be \emph{declared} or
  \emph{defined} (so qualified identifiers are excluded here).  Quoted
  strings provide an escape for non-identifier names or those ruled
  out by outer syntax keywords (e.g.\ quoted @{verbatim \<open>"let"\<close>}).
  Already existing objects are usually referenced by @{syntax
  nameref}.

  @{rail \<open>
    @{syntax_def name}: @{syntax ident} | @{syntax symident} |
      @{syntax string} | @{syntax nat}
    ;
    @{syntax_def parname}: '(' @{syntax name} ')'
    ;
    @{syntax_def nameref}: @{syntax name} | @{syntax longident}
  \<close>}
\<close>


subsection \<open>Numbers\<close>

text \<open>The outer lexical syntax (\secref{sec:outer-lex}) admits
  natural numbers and floating point numbers.  These are combined as
  @{syntax int} and @{syntax real} as follows.

  @{rail \<open>
    @{syntax_def int}: @{syntax nat} | '-' @{syntax nat}
    ;
    @{syntax_def real}: @{syntax float} | @{syntax int}
  \<close>}

  Note that there is an overlap with the category @{syntax name},
  which also includes @{syntax nat}.
\<close>


subsection \<open>Comments \label{sec:comments}\<close>

text \<open>Large chunks of plain @{syntax text} are usually given @{syntax
  verbatim}, i.e.\ enclosed in @{verbatim "{*"}~@{text "\<dots>"}~@{verbatim "*}"},
  or as @{syntax cartouche} @{text "\<open>\<dots>\<close>"}. For convenience, any of the
  smaller text units conforming to @{syntax nameref} are admitted as well. A
  marginal @{syntax comment} is of the form @{verbatim "--"}~@{syntax text}.
  Any number of these may occur within Isabelle/Isar commands.

  @{rail \<open>
    @{syntax_def text}: @{syntax verbatim} | @{syntax cartouche} | @{syntax nameref}
    ;
    @{syntax_def comment}: '--' @{syntax text}
  \<close>}
\<close>


subsection \<open>Type classes, sorts and arities\<close>

text \<open>
  Classes are specified by plain names.  Sorts have a very simple
  inner syntax, which is either a single class name @{text c} or a
  list @{text "{c\<^sub>1, \<dots>, c\<^sub>n}"} referring to the
  intersection of these classes.  The syntax of type arities is given
  directly at the outer level.

  @{rail \<open>
    @{syntax_def classdecl}: @{syntax name} (('<' | '\<subseteq>') (@{syntax nameref} + ','))?
    ;
    @{syntax_def sort}: @{syntax nameref}
    ;
    @{syntax_def arity}: ('(' (@{syntax sort} + ',') ')')? @{syntax sort}
  \<close>}
\<close>


subsection \<open>Types and terms \label{sec:types-terms}\<close>

text \<open>
  The actual inner Isabelle syntax, that of types and terms of the
  logic, is far too sophisticated in order to be modelled explicitly
  at the outer theory level.  Basically, any such entity has to be
  quoted to turn it into a single token (the parsing and type-checking
  is performed internally later).  For convenience, a slightly more
  liberal convention is adopted: quotes may be omitted for any type or
  term that is already atomic at the outer level.  For example, one
  may just write @{verbatim x} instead of quoted @{verbatim \<open>"x"\<close>}.
  Note that symbolic identifiers (e.g.\ @{verbatim "++"} or @{text
  "\<forall>"} are available as well, provided these have not been superseded
  by commands or other keywords already (such as @{verbatim "="} or
  @{verbatim "+"}).

  @{rail \<open>
    @{syntax_def type}: @{syntax nameref} | @{syntax typefree} |
      @{syntax typevar}
    ;
    @{syntax_def term}: @{syntax nameref} | @{syntax var}
    ;
    @{syntax_def prop}: @{syntax term}
  \<close>}

  Positional instantiations are indicated by giving a sequence of
  terms, or the placeholder ``@{text _}'' (underscore), which means to
  skip a position.

  @{rail \<open>
    @{syntax_def inst}: '_' | @{syntax term}
    ;
    @{syntax_def insts}: (@{syntax inst} *)
  \<close>}

  Type declarations and definitions usually refer to @{syntax
  typespec} on the left-hand side.  This models basic type constructor
  application at the outer syntax level.  Note that only plain postfix
  notation is available here, but no infixes.

  @{rail \<open>
    @{syntax_def typespec}:
      (() | @{syntax typefree} | '(' ( @{syntax typefree} + ',' ) ')') @{syntax name}
    ;
    @{syntax_def typespec_sorts}:
      (() | (@{syntax typefree} ('::' @{syntax sort})?) |
        '(' ( (@{syntax typefree} ('::' @{syntax sort})?) + ',' ) ')') @{syntax name}
  \<close>}
\<close>


subsection \<open>Term patterns and declarations \label{sec:term-decls}\<close>

text \<open>Wherever explicit propositions (or term fragments) occur in a
  proof text, casual binding of schematic term variables may be given
  specified via patterns of the form ``@{text "(\<IS> p\<^sub>1 \<dots> p\<^sub>n)"}''.
  This works both for @{syntax term} and @{syntax prop}.

  @{rail \<open>
    @{syntax_def term_pat}: '(' (@'is' @{syntax term} +) ')'
    ;
    @{syntax_def prop_pat}: '(' (@'is' @{syntax prop} +) ')'
  \<close>}

  \medskip Declarations of local variables @{text "x :: \<tau>"} and
  logical propositions @{text "a : \<phi>"} represent different views on
  the same principle of introducing a local scope.  In practice, one
  may usually omit the typing of @{syntax vars} (due to
  type-inference), and the naming of propositions (due to implicit
  references of current facts).  In any case, Isar proof elements
  usually admit to introduce multiple such items simultaneously.

  @{rail \<open>
    @{syntax_def vars}: (@{syntax name} +) ('::' @{syntax type})?
    ;
    @{syntax_def props}: @{syntax thmdecl}? (@{syntax prop} @{syntax prop_pat}? +)
  \<close>}

  The treatment of multiple declarations corresponds to the
  complementary focus of @{syntax vars} versus @{syntax props}.  In
  ``@{text "x\<^sub>1 \<dots> x\<^sub>n :: \<tau>"}'' the typing refers to all variables, while
  in @{text "a: \<phi>\<^sub>1 \<dots> \<phi>\<^sub>n"} the naming refers to all propositions
  collectively.  Isar language elements that refer to @{syntax vars}
  or @{syntax props} typically admit separate typings or namings via
  another level of iteration, with explicit @{keyword_ref "and"}
  separators; e.g.\ see @{command "fix"} and @{command "assume"} in
  \secref{sec:proof-context}.
\<close>


subsection \<open>Attributes and theorems \label{sec:syn-att}\<close>

text \<open>Attributes have their own ``semi-inner'' syntax, in the sense
  that input conforming to @{syntax args} below is parsed by the
  attribute a second time.  The attribute argument specifications may
  be any sequence of atomic entities (identifiers, strings etc.), or
  properly bracketed argument lists.  Below @{syntax atom} refers to
  any atomic entity, including any @{syntax keyword} conforming to
  @{syntax symident}.

  @{rail \<open>
    @{syntax_def atom}: @{syntax nameref} | @{syntax typefree} |
      @{syntax typevar} | @{syntax var} | @{syntax nat} | @{syntax float} |
      @{syntax keyword} | @{syntax cartouche}
    ;
    arg: @{syntax atom} | '(' @{syntax args} ')' | '[' @{syntax args} ']'
    ;
    @{syntax_def args}: arg *
    ;
    @{syntax_def attributes}: '[' (@{syntax nameref} @{syntax args} * ',') ']'
  \<close>}

  Theorem specifications come in several flavors: @{syntax axmdecl}
  and @{syntax thmdecl} usually refer to axioms, assumptions or
  results of goal statements, while @{syntax thmdef} collects lists of
  existing theorems.  Existing theorems are given by @{syntax thmref}
  and @{syntax thmrefs}, the former requires an actual singleton
  result.

  There are three forms of theorem references:
  \begin{enumerate}
  
  \item named facts @{text "a"},

  \item selections from named facts @{text "a(i)"} or @{text "a(j - k)"},

  \item literal fact propositions using token syntax @{syntax_ref altstring}
  @{verbatim "`"}@{text "\<phi>"}@{verbatim "`"} or @{syntax_ref cartouche}
  @{text "\<open>\<phi>\<close>"} (see also method @{method_ref fact}).

  \end{enumerate}

  Any kind of theorem specification may include lists of attributes
  both on the left and right hand sides; attributes are applied to any
  immediately preceding fact.  If names are omitted, the theorems are
  not stored within the theorem database of the theory or proof
  context, but any given attributes are applied nonetheless.

  An extra pair of brackets around attributes (like ``@{text
  "[[simproc a]]"}'') abbreviates a theorem reference involving an
  internal dummy fact, which will be ignored later on.  So only the
  effect of the attribute on the background context will persist.
  This form of in-place declarations is particularly useful with
  commands like @{command "declare"} and @{command "using"}.

  @{rail \<open>
    @{syntax_def axmdecl}: @{syntax name} @{syntax attributes}? ':'
    ;
    @{syntax_def thmdecl}: thmbind ':'
    ;
    @{syntax_def thmdef}: thmbind '='
    ;
    @{syntax_def thmref}:
      (@{syntax nameref} selection? | @{syntax altstring} | @{syntax cartouche})
        @{syntax attributes}? |
      '[' @{syntax attributes} ']'
    ;
    @{syntax_def thmrefs}: @{syntax thmref} +
    ;

    thmbind: @{syntax name} @{syntax attributes} | @{syntax name} | @{syntax attributes}
    ;
    selection: '(' ((@{syntax nat} | @{syntax nat} '-' @{syntax nat}?) + ',') ')'
  \<close>}
\<close>

end
