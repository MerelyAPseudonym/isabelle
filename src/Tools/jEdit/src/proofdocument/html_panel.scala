/*
 * HTML panel based on Lobo/Cobra
 *
 * @author Makarius
 */

package isabelle.proofdocument


import java.io.StringReader
import java.awt.{BorderLayout, Dimension}
import javax.swing.{JButton, JPanel, JScrollPane}
import java.util.logging.{Logger, Level}

import org.w3c.dom.Document

import org.lobobrowser.html.parser.{DocumentBuilderImpl, InputSourceImpl}
import org.lobobrowser.html.gui.HtmlPanel
import org.lobobrowser.html.domimpl.{HTMLDocumentImpl, HTMLStyleElementImpl, NodeImpl}
import org.lobobrowser.html.test.{SimpleHtmlRendererContext, SimpleUserAgentContext}

import scala.io.Source
import scala.actors.Actor._


class HTML_Panel(sys: Isabelle_System, initial_font_size: Int) extends HtmlPanel
{
  // global logging
  Logger.getLogger("org.lobobrowser").setLevel(Level.WARNING)


  /* document template */

  private def try_file(name: String): String =
  {
    val file = sys.platform_file(name)
    if (file.exists) Source.fromFile(file).mkString else ""
  }

  private def template(font_size: Int): String =
    """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<style media="all" type="text/css">""" +
  try_file("$ISABELLE_HOME/lib/html/isabelle.css") + "\n" +
  "body { font-family: " + sys.font_family + "; font-size: " + font_size + "px }\n" +
  try_file("$ISABELLE_HOME_USER/etc/isabelle.css") + "\n" +
"""
</style>
</head>
<body/>
</html>
"""


  /* actor with local state */

  private val ucontext = new SimpleUserAgentContext
  private val rcontext = new SimpleHtmlRendererContext(this, ucontext)
  private val builder = new DocumentBuilderImpl(ucontext, rcontext)

  private case class Init(font_size: Int)
  private case class Render(body: List[XML.Tree])

  private val main_actor = actor {
    // double buffering
    var doc1: Document = null
    var doc2: Document = null

    loop {
      react {
        case Init(font_size) =>
          val src = template(font_size)
          def parse() = builder.parse(new InputSourceImpl(new StringReader(src)))
          doc1 = parse()
          doc2 = parse()
          Swing_Thread.now { setDocument(doc1, rcontext) }
          
        case Render(body) =>
          val doc = doc2
          val node =
            XML.document_node(doc,
              XML.elem(HTML.BODY, body.map((t: XML.Tree) => XML.elem(HTML.PRE, HTML.spans(t)))))
          doc.removeChild(doc.getLastChild())
          doc.appendChild(node)
          doc2 = doc1
          doc1 = doc
          Swing_Thread.now { setDocument(doc1, rcontext) }

        case bad => System.err.println("prover: ignoring bad message " + bad)
      }
    }
  }

  main_actor ! Init(initial_font_size)
  

  /* main method wrappers */
  
  def init(font_size: Int) { main_actor ! Init(font_size) }
  def render(body: List[XML.Tree]) { main_actor ! Render(body) }
}
