/*  Title:      Pure/Isar/isar_document.scala
    Author:     Makarius

Interactive Isar documents.
*/

package isabelle


object Isar_Document
{
  /* protocol messages */

  object Assign {
    def unapply(msg: XML.Tree): Option[List[XML.Tree]] =
      msg match {
        case XML.Elem(Markup.Assign, edits) => Some(edits)
        case _ => None
      }
  }

  object Edit {
    def unapply(msg: XML.Tree): Option[(Document.Command_ID, Document.State_ID)] =
      msg match {
        case XML.Elem(Markup(Markup.EDIT, List((Markup.ID, cmd_id), (Markup.STATE, state_id))), Nil) =>
          Some(cmd_id, state_id)
        case _ => None
      }
  }
}


trait Isar_Document extends Isabelle_Process
{
  import Isar_Document._


  /* commands */

  def define_command(id: Document.Command_ID, text: String): Unit =
    input("Isar_Document.define_command", id, text)


  /* documents */

  def edit_document(old_id: Document.Version_ID, new_id: Document.Version_ID,
      edits: List[Document.Edit[Document.Command_ID]])
  {
    def make_id1(id1: Option[Document.Command_ID]): XML.Body =
      XML_Data.make_string(id1 getOrElse Document.NO_ID)
    val arg =
      XML_Data.make_list(
        XML_Data.make_pair(XML_Data.make_string)(
          XML_Data.make_option(XML_Data.make_list(
              XML_Data.make_pair(make_id1)(XML_Data.make_option(XML_Data.make_string))))))(edits)

    input("Isar_Document.edit_document", old_id, new_id, YXML.string_of_body(arg))
  }
}
