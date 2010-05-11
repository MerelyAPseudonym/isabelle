/*  Title:      Tools/jEdit/src/jedit/output_dockable.scala
    Author:     Makarius

Dockable window with result message output.
*/

package isabelle.jedit


import isabelle._

import scala.actors.Actor._

import javax.swing.JPanel
import java.awt.{BorderLayout, Dimension}

import org.gjt.sp.jedit.View
import org.gjt.sp.jedit.gui.DockableWindowManager



class Output_Dockable(view: View, position: String) extends JPanel(new BorderLayout)
{
  if (position == DockableWindowManager.FLOATING)
    setPreferredSize(new Dimension(500, 250))

  val html_panel =
    new HTML_Panel(Isabelle.system,
      Isabelle.font_size(), Isabelle.Int_Property("relative-margin"), null)
  add(html_panel, BorderLayout.CENTER)


  /* actor wiring */

  private val output_actor = actor {
    loop {
      react {
        case cmd: Command =>
          Swing_Thread.now { Document_Model(view.getBuffer) } match {
            case None =>
            case Some(model) =>
              val body = model.recent_document.current_state(cmd).map(_.results) getOrElse Nil
              html_panel.render(body)
          }

        case Session.Global_Settings =>
          html_panel.init(Isabelle.font_size(), Isabelle.Int_Property("relative-margin"))
          
        case bad => System.err.println("output_actor: ignoring bad message " + bad)
      }
    }
  }

  override def addNotify()
  {
    super.addNotify()
    Isabelle.session.results += output_actor
    Isabelle.session.global_settings += output_actor
  }

  override def removeNotify()
  {
    Isabelle.session.results -= output_actor
    Isabelle.session.global_settings -= output_actor
    super.removeNotify()
  }
}
