theory Sessions
imports Base
begin

chapter {* Isabelle sessions and build management \label{ch:session} *}

text {* An Isabelle \emph{session} consists of a collection of related
  theories that may be associated with formal documents (see also
  \chref{ch:present}).  There is also a notion of \emph{persistent
  heap} image to capture the state of a session, similar to
  object-code in compiled programming languages.  Thus the concept of
  session resembles that of a ``project'' in common IDE environments,
  but the specific name emphasizes the connection to interactive
  theorem proving: the session wraps-up the results of
  user-interaction with the prover in a persistent form.

  Application sessions are built on a given parent session, which may
  be built recursively on other parents.  Following this path in the
  hierarchy eventually leads to some major object-logic session like
  @{text "HOL"}, which itself is based on @{text "Pure"} as the common
  root of all sessions.

  Processing sessions may take considerable time.  Isabelle build
  management helps to organize this efficiently.  This includes
  support for parallel build jobs, in addition to the multithreaded
  theory and proof checking that is already provided by the prover
  process itself.  *}


section {* Session ROOT specifications \label{sec:session-root} *}

text {* Session specifications reside in files called @{verbatim ROOT}
  within certain directories, such as the home locations of registered
  Isabelle components or additional project directories given by the
  user.

  The ROOT file format follows the lexical conventions of the
  \emph{outer syntax} of Isabelle/Isar, see also
  \cite{isabelle-isar-ref}.  This defines common forms like
  identifiers, names, quoted strings, verbatim text, nested comments
  etc.  The grammar for a single @{syntax session_entry} is given as
  syntax diagram below; each ROOT file may contain multiple session
  specifications like this.

  Isabelle/jEdit (\secref{sec:tool-jedit}) includes a simple editing
  mode @{verbatim "isabelle-root"} for session ROOT files.

  @{rail "
    @{syntax_def session_entry}: @'session' spec '=' (@{syntax name} '+')? body
    ;
    body: description? options? ( theories * ) files?
    ;
    spec: @{syntax name} '!'? groups? dir?
    ;
    groups: '(' (@{syntax name} +) ')'
    ;
    dir: @'in' @{syntax name}
    ;
    description: @'description' @{syntax text}
    ;
    options: @'options' opts
    ;
    opts: '[' ( (@{syntax name} '=' value | @{syntax name}) + ',' ) ']'
    ;
    value: @{syntax name} | @{syntax real}
    ;
    theories: @'theories' opts? ( @{syntax name} + )
    ;
    files: @'files' ( @{syntax name} + )
    "}

  \begin{description}

  \item \isakeyword{session}~@{text "A = B + body"} defines a new
  session @{text "A"} based on parent session @{text "B"}, with its
  content given in @{text body} (theories and auxiliary source files).
  Note that a parent (like @{text "HOL"}) is mandatory in practical
  applications: only Isabelle/Pure can bootstrap itself from nothing.

  All such session specifications together describe a hierarchy (tree)
  of sessions, with globally unique names.  By default, names are
  derived from parent ones by concatenation, i.e.\ @{text "B\<dash>A"}
  above.  Cumulatively, this leads to session paths of the form @{text
  "X\<dash>Y\<dash>Z\<dash>W"}.  Note that in the specification,
  @{text B} is already such a fully-qualified name, while @{text "A"}
  is the new base name.

  \item \isakeyword{session}~@{text "A! = B"} indicates a fresh start
  in the naming scheme: the session is called just @{text "A"} instead
  of @{text "B\<dash>A"}.  Here the name @{text "A"} should be
  sufficiently long to stand on its own in a potentially large
  library.

  \item \isakeyword{session}~@{text "A (groups)"} indicates a
  collection of groups where the new session is a member.  Group names
  are uninterpreted and merely follow certain conventions.  For
  example, the Isabelle distribution tags some important sessions by
  the group name called ``@{text "main"}''.  Other projects may invent
  their own conventions, but this requires some care to avoid clashes
  within this unchecked name space.

  \item \isakeyword{session}~@{text "A"}~\isakeyword{in}~@{text "dir"}
  specifies an explicit directory for this session.  By default,
  \isakeyword{session}~@{text "A"} abbreviates
  \isakeyword{session}~@{text "A"}~\isakeyword{in}~@{text "A"}.  This
  accommodates the common scheme where some base directory contains
  several sessions in sub-directories of corresponding names.  Another
  common scheme is \isakeyword{session}~@{text
  "A"}~\isakeyword{in}~@{verbatim "\".\""} to refer to the current
  directory of the ROOT file.

  All theories and auxiliary source files are located relatively to
  the session directory.  The prover process is run within the same as
  its current working directory.

  \item \isakeyword{description}~@{text "text"} is a free-form
  annotation for this session.

  \item \isakeyword{options}~@{text "[x = a, y = b, z]"} defines
  separate options (\secref{sec:system-options}) that are used when
  processing this session, but \emph{without} propagation to child
  sessions.  Note that @{text "z"} abbreviates @{text "z = true"} for
  Boolean options.

  \item \isakeyword{theories}~@{text "options names"} specifies a
  block of theories that are processed within an environment that is
  augmented by the given options, in addition to the global session
  options given before.  Any number of blocks of \isakeyword{theories}
  may be given.  Options are only active for each
  \isakeyword{theories} block separately.

  \item \isakeyword{files}~@{text "files"} lists additional source
  files that are involved in the processing of this session.  This
  should cover anything outside the formal content of the theory
  sources, say some auxiliary {\TeX} files that are required for
  document processing.  In contrast, files that are specified in
  formal theory headers as @{keyword "uses"} need not be declared
  again.

  \end{description}
*}

subsubsection {* Examples *}

text {* See @{file "~~/src/HOL/ROOT"} for a diversity of practically
  relevant situations. *}


section {* System build options \label{sec:system-options} *}

text {* See @{file "~~/etc/options"} for the main defaults provided by
  the Isabelle distribution.  Isabelle/jEdit (\secref{sec:tool-jedit})
  includes a simple editing mode @{verbatim "isabelle-options"} for
  this file-format.
*}


section {* Invoking the build process \label{sec:tool-build} *}

text {* The @{tool_def build} tool invokes the build process for
  Isabelle sessions.  It manages dependencies between sessions,
  related sources of theories and auxiliary files, and target heap
  images.  Accordingly, it runs instances of the prover process with
  optional document preparation.  Its command-line usage
  is:\footnote{Isabelle/Scala provides the same functionality via
  \texttt{isabelle.Build.build}.}
\begin{ttbox}
Usage: isabelle build [OPTIONS] [SESSIONS ...]

  Options are:
    -a           select all sessions
    -b           build heap images
    -c           clean build
    -d DIR       include session directory with ROOT file
    -g NAME      select session group NAME
    -j INT       maximum number of parallel jobs (default 1)
    -n           no build -- test dependencies only
    -o OPTION    override session configuration OPTION
                 (via NAME=VAL or NAME)
    -s           system build mode: produce output in ISABELLE_HOME
    -v           verbose

  Build and manage Isabelle sessions, depending on implicit
  ISABELLE_BUILD_OPTIONS="..."

  ML_PLATFORM="..."
  ML_HOME="..."
  ML_SYSTEM="..."
  ML_OPTIONS="..."
\end{ttbox}

  \medskip Isabelle sessions are defined via session ROOT files as
  described in (\secref{sec:session-root}).  The totality of sessions
  is determined by collecting such specifications from all Isabelle
  component directories (\secref{sec:components}), augmented by more
  directories given via options @{verbatim "-d"}~@{text "DIR"} on the
  command line.  Each such directory may contain a session
  \texttt{ROOT} file and an additional catalog file @{verbatim
  "etc/sessions"} with further sub-directories (list of lines).  Note
  that a single \texttt{ROOT} file usually defines many sessions;
  catalogs are only required for extra scalability and modularity
  of large libraries.

  \medskip The subset of sessions to be managed is determined via
  individual @{text "SESSIONS"} given as command-line arguments, or
  session groups that are given via one or more options @{verbatim
  "-g"}~@{text "NAME"}.  Option @{verbatim "-a"} selects all sessions.
  The build tool takes session dependencies into account: the set of
  selected sessions is completed by including all ancestors.

  \medskip The build process depends on additional options
  (\secref{sec:system-options}) that are passed to the prover
  eventually.  The settings variable @{setting_ref
  ISABELLE_BUILD_OPTIONS} allows to provide additional defaults, e.g.\
  \texttt{ISABELLE_BUILD_OPTIONS="document=pdf threads=4"}. Moreover,
  the environment of system build options may be augmented on the
  command line via @{verbatim "-o"}~@{text "name"}@{verbatim
  "="}@{text "value"} or @{verbatim "-o"}~@{text "name"}, which
  abbreviates @{verbatim "-o"}~@{text "name"}@{verbatim"=true"} for
  Boolean options.  Multiple occurrences of @{verbatim "-o"} on the
  command-line are applied in the given order.

  \medskip Option @{verbatim "-b"} ensures that heap images are
  produced for all selected sessions.  By default, images are only
  saved for inner nodes of the hierarchy of sessions, as required for
  other sessions to continue later on.

  \medskip Option @{verbatim "-c"} cleans all descendants of the
  selected sessions before performing the specified build operation.

  \medskip Option @{verbatim "-n"} omits the actual build process
  after the preparatory stage (including optional cleanup).  Note that
  the return code always indicates the status of the set of selected
  sessions.

  \medskip Option @{verbatim "-j"} specifies the maximum number of
  parallel build jobs (prover processes).  Each prover process is
  subject to a separate limit of parallel worker threads, cf.\ system
  option @{system_option_ref threads}.

  \medskip Option @{verbatim "-s"} enables \emph{system mode}, which
  means that resulting heap images and log files are stored in
  @{verbatim "$ISABELLE_HOME/heaps"} instead of the default location
  @{setting ISABELLE_OUTPUT} (which is normally in @{setting
  ISABELLE_HOME_USER}, i.e.\ the user's home directory).

  \medskip Option @{verbatim "-v"} enables verbose mode.
*}

subsubsection {* Examples *}

text {*
  Build a specific logic image:
\begin{ttbox}
isabelle build -b HOLCF
\end{ttbox}

  \smallskip Build the main group of logic images:
\begin{ttbox}
isabelle build -b -g main
\end{ttbox}

  \smallskip Provide a general overview of the status of all Isabelle
  sessions, without building anything:
\begin{ttbox}
isabelle build -a -n -v
\end{ttbox}

  \smallskip Build all sessions with HTML browser info and PDF
  document preparation:
\begin{ttbox}
isabelle build -a -o browser_info -o document=pdf
\end{ttbox}

  \smallskip Build all sessions with a maximum of 8 parallel prover
  processes and 4 worker threads each (on a machine with many cores):
\begin{ttbox}
isabelle build -a -j8 -o threads=4
\end{ttbox}

  \smallskip Build some session images with cleanup of their
  descendants, while retaining their ancestry:
\begin{ttbox}
isabelle build -b -c HOL-Boogie HOL-SPARK
\end{ttbox}

  \smallskip Clean all sessions without building anything:
\begin{ttbox}
isabelle build -a -n -c
\end{ttbox}
*}

end
