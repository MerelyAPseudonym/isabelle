/*
 * Hyperlink setup for Isabelle proof documents
 *
 * @author Fabian Immler, TU Munich
 */

package isabelle.jedit


import java.io.File

import gatchan.jedit.hyperlinks.Hyperlink
import gatchan.jedit.hyperlinks.HyperlinkSource
import gatchan.jedit.hyperlinks.AbstractHyperlink

import org.gjt.sp.jedit.View
import org.gjt.sp.jedit.jEdit
import org.gjt.sp.jedit.Buffer
import org.gjt.sp.jedit.TextUtilities

import isabelle.proofdocument.Command


private class Internal_Hyperlink(start: Int, end: Int, line: Int, ref_offset: Int)
  extends AbstractHyperlink(start, end, line, "")
{
  override def click(view: View) {
    view.getTextArea.moveCaretPosition(ref_offset)
  }
}

class External_Hyperlink(start: Int, end: Int, line: Int, ref_file: String, ref_line: Int)
  extends AbstractHyperlink(start, end, line, "")
{
  override def click(view: View) = {
    Isabelle.system.source_file(ref_file) match {
      case None => System.err.println("Could not find source file " + ref_file)  // FIXME ??
      case Some(file) =>
        jEdit.openFiles(view, file.getParent, Array(file.getName, "+line:" + ref_line))
    }
  }
}

class Isabelle_Hyperlinks extends HyperlinkSource
{
	def getHyperlink(buffer: Buffer, original_offset: Int): Hyperlink =
	{
    val prover = Isabelle.prover_setup(buffer).map(_.prover)
    val theory_view_opt = Isabelle.prover_setup(buffer).map(_.theory_view)
    if (prover.isEmpty || theory_view_opt.isEmpty) null
    else if (prover.get == null || theory_view_opt.get == null) null
    else {
      val theory_view = theory_view_opt.get
      val document = theory_view.current_document()
      val offset = theory_view.from_current(document, original_offset)
      document.command_at(offset) match {
        case Some(command) =>
          command.ref_at(document, offset - command.start(document)) match {
            case Some(ref) =>
              val command_start = command.start(document)
              val begin = theory_view.to_current(document, command_start + ref.start)
              val line = buffer.getLineOfOffset(begin)
              val end = theory_view.to_current(document, command_start + ref.stop)
              ref.info match {
                case Command.RefInfo(Some(ref_file), Some(ref_line), _, _) =>
                  new External_Hyperlink(begin, end, line, ref_file, ref_line)
                case Command.RefInfo(_, _, Some(id), Some(offset)) =>
                  prover.get.command(id) match {
                    case Some(ref_cmd) =>
                      new Internal_Hyperlink(begin, end, line,
                        theory_view.to_current(document, ref_cmd.start(document) + offset - 1))
                    case None => null
                  }
                case _ => null
              }
            case None => null
          }
        case None => null
      }
    }
  }
}
