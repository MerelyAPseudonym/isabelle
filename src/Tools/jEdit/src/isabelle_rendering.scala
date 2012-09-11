/*  Title:      Tools/jEdit/src/isabelle_rendering.scala
    Author:     Makarius

Isabelle specific physical rendering and markup selection.
*/

package isabelle.jedit


import isabelle._

import java.awt.Color
import javax.swing.Icon
import java.io.{File => JFile}

import org.gjt.sp.jedit.syntax.{Token => JEditToken}

import scala.collection.immutable.SortedMap


object Isabelle_Rendering
{
  /* physical rendering */

  def color_value(s: String): Color = Color_Value(Isabelle.options.value.string(s))

  private val writeln_pri = 1
  private val warning_pri = 2
  private val legacy_pri = 3
  private val error_pri = 4


  /* command overview */

  def overview_color(snapshot: Document.Snapshot, range: Text.Range): Option[Color] =
  {
    if (snapshot.is_outdated) None
    else {
      val results =
        snapshot.cumulate_markup[(Protocol.Status, Int)](
          range, (Protocol.Status.init, 0),
          Some(Protocol.command_status_markup + Isabelle_Markup.WARNING + Isabelle_Markup.ERROR),
          {
            case ((status, pri), Text.Info(_, XML.Elem(markup, _))) =>
              if (markup.name == Isabelle_Markup.WARNING) (status, pri max warning_pri)
              else if (markup.name == Isabelle_Markup.ERROR) (status, pri max error_pri)
              else (Protocol.command_status(status, markup), pri)
          })
      if (results.isEmpty) None
      else {
        val (status, pri) =
          ((Protocol.Status.init, 0) /: results) {
            case ((s1, p1), Text.Info(_, (s2, p2))) => (s1 + s2, p1 max p2) }

        if (pri == warning_pri) Some(color_value("color_warning"))
        else if (pri == error_pri) Some(color_value("color_error"))
        else if (status.is_unprocessed) Some(color_value("color_unprocessed"))
        else if (status.is_running) Some(color_value("color_running"))
        else if (status.is_failed) Some(color_value("color_error"))
        else None
      }
    }
  }


  /* markup selectors */

  private val subexp_include =
    Set(Isabelle_Markup.SORT, Isabelle_Markup.TYP, Isabelle_Markup.TERM, Isabelle_Markup.PROP,
      Isabelle_Markup.ML_TYPING, Isabelle_Markup.TOKEN_RANGE, Isabelle_Markup.ENTITY,
      Isabelle_Markup.PATH, Isabelle_Markup.TYPING, Isabelle_Markup.FREE, Isabelle_Markup.SKOLEM,
      Isabelle_Markup.BOUND, Isabelle_Markup.VAR, Isabelle_Markup.TFREE, Isabelle_Markup.TVAR,
      Isabelle_Markup.ML_SOURCE, Isabelle_Markup.DOC_SOURCE)

  def subexp(snapshot: Document.Snapshot, range: Text.Range): Option[Text.Info[Color]] =
  {
    snapshot.select_markup(range, Some(subexp_include),
        {
          case Text.Info(info_range, XML.Elem(Markup(name, _), _)) if subexp_include(name) =>
            Text.Info(snapshot.convert(info_range), color_value("color_subexp"))
        }) match { case Text.Info(_, info) #:: _ => Some(info) case _ => None }
  }


  private val hyperlink_include = Set(Isabelle_Markup.ENTITY, Isabelle_Markup.PATH)

  def hyperlink(snapshot: Document.Snapshot, range: Text.Range): Option[Text.Info[Hyperlink]] =
  {
    snapshot.cumulate_markup[List[Text.Info[Hyperlink]]](range, Nil, Some(hyperlink_include),
        {
          case (links, Text.Info(info_range, XML.Elem(Isabelle_Markup.Path(name), _)))
          if Path.is_ok(name) =>
            val jedit_file = Isabelle.thy_load.append(snapshot.node_name.dir, Path.explode(name))
            Text.Info(snapshot.convert(info_range), Hyperlink(jedit_file, 0, 0)) :: links

          case (links, Text.Info(info_range, XML.Elem(Markup(Isabelle_Markup.ENTITY, props), _)))
          if (props.find(
            { case (Markup.KIND, Isabelle_Markup.ML_OPEN) => true
              case (Markup.KIND, Isabelle_Markup.ML_STRUCT) => true
              case _ => false }).isEmpty) =>

            props match {
              case Position.Line_File(line, name) if Path.is_ok(name) =>
                Isabelle_System.source_file(Path.explode(name)) match {
                  case Some(path) =>
                    val jedit_file = Isabelle_System.platform_path(path)
                    Text.Info(snapshot.convert(info_range), Hyperlink(jedit_file, line, 0)) :: links
                  case None => links
                }

              case Position.Id_Offset(id, offset) if !snapshot.is_outdated =>
                snapshot.state.find_command(snapshot.version, id) match {
                  case Some((node, command)) =>
                    val sources =
                      node.commands.iterator.takeWhile(_ != command).map(_.source) ++
                        Iterator.single(command.source(Text.Range(0, command.decode(offset))))
                    val (line, column) = ((1, 1) /: sources)(Symbol.advance_line_column)
                    Text.Info(snapshot.convert(info_range),
                      Hyperlink(command.node_name.node, line, column)) :: links
                  case None => links
                }

              case _ => links
            }
        }) match { case Text.Info(_, info :: _) #:: _ => Some(info) case _ => None }
  }


  private def tooltip_text(msg: XML.Tree): String =
    Pretty.string_of(List(msg), margin = Isabelle.options.int("jedit_tooltip_margin"))

  def tooltip_message(snapshot: Document.Snapshot, range: Text.Range): Option[String] =
  {
    val msgs =
      snapshot.cumulate_markup[SortedMap[Long, String]](range, SortedMap.empty,
        Some(Set(Isabelle_Markup.WRITELN, Isabelle_Markup.WARNING, Isabelle_Markup.ERROR,
          Isabelle_Markup.BAD)),
        {
          case (msgs, Text.Info(_, msg @
              XML.Elem(Markup(markup, Isabelle_Markup.Serial(serial)), _)))
          if markup == Isabelle_Markup.WRITELN ||
              markup == Isabelle_Markup.WARNING ||
              markup == Isabelle_Markup.ERROR =>
            msgs + (serial -> tooltip_text(msg))
          case (msgs, Text.Info(_, msg @ XML.Elem(Markup(Isabelle_Markup.BAD, _), body)))
          if !body.isEmpty => msgs + (Document.new_id() -> tooltip_text(msg))
        }).toList.flatMap(_.info)
    if (msgs.isEmpty) None else Some(cat_lines(msgs.iterator.map(_._2)))
  }


  private val tooltips: Map[String, String] =
    Map(
      Isabelle_Markup.SORT -> "sort",
      Isabelle_Markup.TYP -> "type",
      Isabelle_Markup.TERM -> "term",
      Isabelle_Markup.PROP -> "proposition",
      Isabelle_Markup.TOKEN_RANGE -> "inner syntax token",
      Isabelle_Markup.FREE -> "free variable",
      Isabelle_Markup.SKOLEM -> "skolem variable",
      Isabelle_Markup.BOUND -> "bound variable",
      Isabelle_Markup.VAR -> "schematic variable",
      Isabelle_Markup.TFREE -> "free type variable",
      Isabelle_Markup.TVAR -> "schematic type variable",
      Isabelle_Markup.ML_SOURCE -> "ML source",
      Isabelle_Markup.DOC_SOURCE -> "document source")

  private val tooltip_elements =
    Set(Isabelle_Markup.ENTITY, Isabelle_Markup.TYPING, Isabelle_Markup.ML_TYPING,
      Isabelle_Markup.PATH) ++ tooltips.keys

  private def string_of_typing(kind: String, body: XML.Body): String =
    Pretty.string_of(List(Pretty.block(XML.Text(kind) :: Pretty.Break(1) :: body)),
      margin = Isabelle.options.int("jedit_tooltip_margin"))

  def tooltip(snapshot: Document.Snapshot, range: Text.Range): Option[String] =
  {
    def add(prev: Text.Info[List[(Boolean, String)]], r: Text.Range, p: (Boolean, String)) =
      if (prev.range == r) Text.Info(r, p :: prev.info) else Text.Info(r, List(p))

    val tips =
      snapshot.cumulate_markup[Text.Info[(List[(Boolean, String)])]](
        range, Text.Info(range, Nil), Some(tooltip_elements),
        {
          case (prev, Text.Info(r, XML.Elem(Isabelle_Markup.Entity(kind, name), _))) =>
            add(prev, r, (true, kind + " " + quote(name)))
          case (prev, Text.Info(r, XML.Elem(Isabelle_Markup.Path(name), _)))
          if Path.is_ok(name) =>
            val jedit_file = Isabelle.thy_load.append(snapshot.node_name.dir, Path.explode(name))
            add(prev, r, (true, "file " + quote(jedit_file)))
          case (prev, Text.Info(r, XML.Elem(Markup(Isabelle_Markup.TYPING, _), body))) =>
            add(prev, r, (true, string_of_typing("::", body)))
          case (prev, Text.Info(r, XML.Elem(Markup(Isabelle_Markup.ML_TYPING, _), body))) =>
            add(prev, r, (false, string_of_typing("ML:", body)))
          case (prev, Text.Info(r, XML.Elem(Markup(name, _), _)))
          if tooltips.isDefinedAt(name) => add(prev, r, (true, tooltips(name)))
        }).toList.flatMap(_.info.info)

    val all_tips =
      (tips.filter(_._1) ++ tips.filter(!_._1).lastOption.toList).map(_._2)
    if (all_tips.isEmpty) None else Some(cat_lines(all_tips))
  }


  private val gutter_icons = Map(
    warning_pri -> Isabelle.load_icon("16x16/status/dialog-information.png"),
    legacy_pri -> Isabelle.load_icon("16x16/status/dialog-warning.png"),
    error_pri -> Isabelle.load_icon("16x16/status/dialog-error.png"))

  def gutter_message(snapshot: Document.Snapshot, range: Text.Range): Option[Icon] =
  {
    val results =
      snapshot.cumulate_markup[Int](range, 0,
        Some(Set(Isabelle_Markup.WARNING, Isabelle_Markup.ERROR)),
        {
          case (pri, Text.Info(_, XML.Elem(Markup(Isabelle_Markup.WARNING, _), body))) =>
            body match {
              case List(XML.Elem(Markup(Isabelle_Markup.LEGACY, _), _)) => pri max legacy_pri
              case _ => pri max warning_pri
            }
          case (pri, Text.Info(_, XML.Elem(Markup(Isabelle_Markup.ERROR, _), _))) =>
            pri max error_pri
        })
    val pri = (0 /: results) { case (p1, Text.Info(_, p2)) => p1 max p2 }
    gutter_icons.get(pri)
  }


  def squiggly_underline(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
  {
    val squiggly_colors = Map(
      writeln_pri -> color_value("color_writeln"),
      warning_pri -> color_value("color_warning"),
      error_pri -> color_value("color_error"))

    val results =
      snapshot.cumulate_markup[Int](range, 0,
        Some(Set(Isabelle_Markup.WRITELN, Isabelle_Markup.WARNING, Isabelle_Markup.ERROR)),
        {
          case (pri, Text.Info(_, XML.Elem(Markup(name, _), _))) =>
            name match {
              case Isabelle_Markup.WRITELN => pri max writeln_pri
              case Isabelle_Markup.WARNING => pri max warning_pri
              case Isabelle_Markup.ERROR => pri max error_pri
              case _ => pri
            }
        })
    for {
      Text.Info(r, pri) <- results
      color <- squiggly_colors.get(pri)
    } yield Text.Info(r, color)
  }


  def background1(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
  {
    if (snapshot.is_outdated) Stream(Text.Info(range, color_value("color_outdated")))
    else
      for {
        Text.Info(r, result) <-
          snapshot.cumulate_markup[(Option[Protocol.Status], Option[Color])](
            range, (Some(Protocol.Status.init), None),
            Some(Protocol.command_status_markup + Isabelle_Markup.BAD + Isabelle_Markup.HILITE),
            {
              case (((Some(status), color), Text.Info(_, XML.Elem(markup, _))))
              if (Protocol.command_status_markup(markup.name)) =>
                (Some(Protocol.command_status(status, markup)), color)
              case (_, Text.Info(_, XML.Elem(Markup(Isabelle_Markup.BAD, _), _))) =>
                (None, Some(color_value("color_bad")))
              case (_, Text.Info(_, XML.Elem(Markup(Isabelle_Markup.HILITE, _), _))) =>
                (None, Some(color_value("color_hilite")))
            })
        color <-
          (result match {
            case (Some(status), opt_color) =>
              if (status.is_unprocessed) Some(color_value("color_unprocessed1"))
              else if (status.is_running) Some(color_value("color_running1"))
              else opt_color
            case (_, opt_color) => opt_color
          })
      } yield Text.Info(r, color)
  }


  def background2(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
    snapshot.select_markup(range,
      Some(Set(Isabelle_Markup.TOKEN_RANGE)),
      {
        case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.TOKEN_RANGE, _), _)) =>
          color_value("color_light")
      })


  def foreground(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
    snapshot.select_markup(range,
      Some(Set(Isabelle_Markup.STRING, Isabelle_Markup.ALTSTRING, Isabelle_Markup.VERBATIM)),
      {
        case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.STRING, _), _)) =>
          color_value("color_quoted")
        case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.ALTSTRING, _), _)) =>
          color_value("color_quoted")
        case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.VERBATIM, _), _)) =>
          color_value("color_quoted")
      })


  def text_color(snapshot: Document.Snapshot, range: Text.Range, color: Color)
      : Stream[Text.Info[Color]] =
  {
    val text_colors: Map[String, Color] = Map(
      Isabelle_Markup.STRING -> Color.BLACK,
      Isabelle_Markup.ALTSTRING -> Color.BLACK,
      Isabelle_Markup.VERBATIM -> Color.BLACK,
      Isabelle_Markup.LITERAL -> color_value("color_keyword1"),
      Isabelle_Markup.DELIMITER -> Color.BLACK,
      Isabelle_Markup.TFREE -> color_value("color_variable_type"),
      Isabelle_Markup.TVAR -> color_value("color_variable_type"),
      Isabelle_Markup.FREE -> color_value("color_variable_free"),
      Isabelle_Markup.SKOLEM -> color_value("color_variable_skolem"),
      Isabelle_Markup.BOUND -> color_value("color_variable_bound"),
      Isabelle_Markup.VAR -> color_value("color_variable_schematic"),
      Isabelle_Markup.INNER_STRING -> color_value("color_inner_quoted"),
      Isabelle_Markup.INNER_COMMENT -> color_value("color_inner_comment"),
      Isabelle_Markup.DYNAMIC_FACT -> color_value("color_dynamic"),
      Isabelle_Markup.ML_KEYWORD -> color_value("color_keyword1"),
      Isabelle_Markup.ML_DELIMITER -> Color.BLACK,
      Isabelle_Markup.ML_NUMERAL -> color_value("color_inner_numeral"),
      Isabelle_Markup.ML_CHAR -> color_value("color_inner_quoted"),
      Isabelle_Markup.ML_STRING -> color_value("color_inner_quoted"),
      Isabelle_Markup.ML_COMMENT -> color_value("color_inner_comment"),
      Isabelle_Markup.ANTIQ -> color_value("color_antiquotation"))

    val text_color_elements = Set.empty[String] ++ text_colors.keys

    snapshot.cumulate_markup(range, color, Some(text_color_elements),
      {
        case (_, Text.Info(_, XML.Elem(Markup(m, _), _)))
        if text_colors.isDefinedAt(m) => text_colors(m)
      })
  }


  /* token markup -- text styles */

  private val command_style: Map[String, Byte] =
  {
    import JEditToken._
    Map[String, Byte](
      Keyword.THY_END -> KEYWORD2,
      Keyword.THY_SCRIPT -> LABEL,
      Keyword.PRF_SCRIPT -> LABEL,
      Keyword.PRF_ASM -> KEYWORD3,
      Keyword.PRF_ASM_GOAL -> KEYWORD3
    ).withDefaultValue(KEYWORD1)
  }

  private val token_style: Map[Token.Kind.Value, Byte] =
  {
    import JEditToken._
    Map[Token.Kind.Value, Byte](
      Token.Kind.KEYWORD -> KEYWORD2,
      Token.Kind.IDENT -> NULL,
      Token.Kind.LONG_IDENT -> NULL,
      Token.Kind.SYM_IDENT -> NULL,
      Token.Kind.VAR -> NULL,
      Token.Kind.TYPE_IDENT -> NULL,
      Token.Kind.TYPE_VAR -> NULL,
      Token.Kind.NAT -> NULL,
      Token.Kind.FLOAT -> NULL,
      Token.Kind.STRING -> LITERAL1,
      Token.Kind.ALT_STRING -> LITERAL2,
      Token.Kind.VERBATIM -> COMMENT3,
      Token.Kind.SPACE -> NULL,
      Token.Kind.COMMENT -> COMMENT1,
      Token.Kind.ERROR -> INVALID
    ).withDefaultValue(NULL)
  }

  def token_markup(syntax: Outer_Syntax, token: Token): Byte =
    if (token.is_command) command_style(syntax.keyword_kind(token.content).getOrElse(""))
    else if (token.is_operator) JEditToken.OPERATOR
    else token_style(token.kind)
}
