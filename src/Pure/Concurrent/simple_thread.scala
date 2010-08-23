/*  Title:      Pure/Concurrent/simple_thread.scala
    Author:     Makarius

Simplified thread operations.
*/

package isabelle


import java.lang.Thread

import scala.actors.Actor


object Simple_Thread
{
  /* plain thread */

  def fork(name: String)(body: => Unit): Thread =
  {
    val thread = new Thread(name) { override def run = body }
    thread.start
    thread
  }


  /* thread as actor */

  def actor(name: String)(body: => Unit): Actor =
  {
    val actor = Future.promise[Actor]
    val thread = fork(name) { actor.fulfill(Actor.self); body }
    actor.join
  }
}

