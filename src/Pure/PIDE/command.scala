/*  Title:      Pure/PIDE/command.scala
    Author:     Fabian Immler, TU Munich
    Author:     Makarius

Prover commands with semantic state.
*/

package isabelle

import java.lang.System

import scala.collection.mutable
import scala.collection.immutable.SortedMap


object Command
{
  /** accumulated results from prover **/

  sealed case class State(
    val command: Command,
    val status: List[Markup] = Nil,
    val results: SortedMap[Long, XML.Tree] = SortedMap.empty,
    val markup: Markup_Tree = Markup_Tree.empty)
  {
    /* accumulate content */

    private def add_status(st: Markup): State = copy(status = st :: status)
    private def add_markup(m: Text.Markup): State = copy(markup = markup + m)

    def + (message: XML.Elem): Command.State =
      message match {
        case XML.Elem(Markup(Isabelle_Markup.STATUS, _), msgs) =>
          (this /: msgs)((state, msg) =>
            msg match {
              case elem @ XML.Elem(markup, Nil) =>
                state.add_status(markup).add_markup(Text.Info(command.proper_range, elem))

              case _ => System.err.println("Ignored status message: " + msg); state
            })

        case XML.Elem(Markup(Isabelle_Markup.REPORT, _), msgs) =>
          (this /: msgs)((state, msg) =>
            msg match {
              case XML.Elem(Markup(name, atts @ Position.Id_Range(id, raw_range)), args)
              if id == command.id && command.range.contains(command.decode(raw_range)) =>
                val range = command.decode(raw_range)
                val props = Position.purge(atts)
                val info: Text.Markup = Text.Info(range, XML.Elem(Markup(name, props), args))
                state.add_markup(info)
              case _ =>
                // FIXME System.err.println("Ignored report message: " + msg)
                state
            })
        case XML.Elem(Markup(name, atts), body) =>
          atts match {
            case Isabelle_Markup.Serial(i) =>
              val result = XML.Elem(Markup(name, Position.purge(atts)), body)
              val st0 = copy(results = results + (i -> result))
              val st1 =
                if (Protocol.is_tracing(message)) st0
                else
                  (st0 /: Protocol.message_positions(command, message))(
                    (st, range) => st.add_markup(Text.Info(range, result)))
              val st2 = (st1 /: Protocol.message_reports(message))(_ + _)
              st2
            case _ => System.err.println("Ignored message without serial number: " + message); this
          }
      }
  }


  /* make commands */

  type Span = List[Token]

  def apply(id: Document.Command_ID, node_name: Document.Node.Name, span: Span): Command =
  {
    val source: String =
      span match {
        case List(tok) => tok.source
        case _ => span.map(_.source).mkString
      }

    val span1 = new mutable.ListBuffer[Token]
    var i = 0
    for (Token(kind, s) <- span) {
      val n = s.length
      val s1 = source.substring(i, i + n)
      span1 += Token(kind, s1)
      i += n
    }

    new Command(id, node_name, span1.toList, source)
  }

  def unparsed(source: String): Command =
    Command(Document.no_id, Document.Node.Name.empty, List(Token(Token.Kind.UNPARSED, source)))


  /* perspective */

  object Perspective
  {
    val empty: Perspective = Perspective(Nil)
  }

  sealed case class Perspective(commands: List[Command])  // visible commands in canonical order
  {
    def same(that: Perspective): Boolean =
    {
      val cmds1 = this.commands
      val cmds2 = that.commands
      require(!cmds1.exists(_.is_undefined))
      require(!cmds2.exists(_.is_undefined))
      cmds1.length == cmds2.length &&
        (cmds1.iterator zip cmds2.iterator).forall({ case (c1, c2) => c1.id == c2.id })
    }
  }
}


final class Command private(
    val id: Document.Command_ID,
    val node_name: Document.Node.Name,
    val span: Command.Span,
    val source: String)
{
  /* classification */

  def is_undefined: Boolean = id == Document.no_id
  val is_unparsed: Boolean = span.exists(_.is_unparsed)
  val is_unfinished: Boolean = span.exists(_.is_unfinished)

  val is_ignored: Boolean = !span.exists(_.is_proper)
  val is_malformed: Boolean = !is_ignored && (!span.head.is_command || span.exists(_.is_error))
  def is_command: Boolean = !is_ignored && !is_malformed

  def name: String =
    span.find(_.is_command) match { case Some(tok) => tok.source case _ => "" }

  override def toString =
    id + "/" + (if (is_command) name else if (is_ignored) "IGNORED" else "MALFORMED")


  /* source text */

  def length: Int = source.length
  val range: Text.Range = Text.Range(0, length)

  val proper_range: Text.Range =
    Text.Range(0, (length /: span.reverse.iterator.takeWhile(_.is_space))(_ - _.source.length))

  def source(range: Text.Range): String = source.substring(range.start, range.stop)

  lazy val symbol_index = new Symbol.Index(source)
  def decode(i: Text.Offset): Text.Offset = symbol_index.decode(i)
  def decode(r: Text.Range): Text.Range = symbol_index.decode(r)


  /* accumulated results */

  val empty_state: Command.State = Command.State(this)
}
