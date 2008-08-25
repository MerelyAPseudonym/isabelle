/*  Title:      Pure/Tools/isabelle_process.ML
    ID:         $Id$
    Author:     Makarius
    Options:    :folding=explicit:collapseFolds=1:

Isabelle process management -- always reactive due to multi-threaded I/O.
*/

package isabelle

import java.util.Properties
import java.util.concurrent.LinkedBlockingQueue
import java.io.{BufferedReader, BufferedWriter, InputStreamReader, OutputStreamWriter, IOException}

import isabelle.{Symbol, XML}


object IsabelleProcess {

  /* exception */

  class IsabelleProcessException(msg: String) extends Exception {
    override def toString = "IsabelleProcess: " + msg
  }


  /* results */

  object Kind extends Enumeration {
    //{{{ values
    // Posix channels/events
    val STDIN = Value("STDIN")
    val STDOUT = Value("STDOUT")
    val STDERR = Value("STDERR")
    val SIGNAL = Value("SIGNAL")
    val EXIT = Value("EXIT")
    // Isabelle messages
    val WRITELN = Value("WRITELN")
    val PRIORITY = Value("PRIORITY")
    val TRACING = Value("TRACING")
    val WARNING = Value("WARNING")
    val ERROR = Value("ERROR")
    val DEBUG = Value("DEBUG")
    val PROMPT = Value("PROMPT")
    val INIT = Value("INIT")
    val STATUS = Value("STATUS")
    // internal system notification
    val SYSTEM = Value("SYSTEM")
    //}}}
    def is_raw(kind: Value) =
      kind == STDOUT ||
      kind == STDERR
    def is_control(kind: Value) =
      kind == SIGNAL ||
      kind == EXIT ||
      kind == SYSTEM
    def is_system(kind: Value) =
      kind == STDIN ||
      kind == SIGNAL ||
      kind == EXIT ||
      kind == PROMPT ||
      kind == STATUS ||
      kind == SYSTEM
  }

  class Result(val kind: Kind.Value, val props: Properties, val result: String) {
    override def toString = {
      val res = XML.content(YXML.parse_failsafe(result)).mkString("")
      if (props == null) kind.toString + " [[" + res + "]]"
      else kind.toString + " " + props.toString + " [[" + res + "]]"
    }
    def is_raw() = Kind.is_raw(kind)
    def is_control() = Kind.is_control(kind)
    def is_system() = Kind.is_system(kind)
  }

}


class IsabelleProcess(args: String*) {

  import IsabelleProcess._


  /* process information */

  private var proc: Process = null
  private var closing = false
  private var pid: String = null
  private var the_session: String = null
  def session() = the_session


  /* symbols */

  val symbols = new Symbol.Interpretation
  def decode_result(result: Result) = YXML.parse_failsafe(symbols.decode(result.result))


  /* results */

  private val results = new LinkedBlockingQueue[Result]

  private def put_result(kind: Kind.Value, props: Properties, result: String) {
    if (kind == Kind.INIT && props != null) {
      pid = props.getProperty(Markup.PID)
      the_session = props.getProperty(Markup.SESSION)
    }
    results.put(new Result(kind, props, result))
  }

  def get_result() = results.take

  def try_result() = {
    val res = results.poll
    if (res != null) Some(res) else None
  }


  /* signals */

  def interrupt() = synchronized {
    if (proc == null) throw new IsabelleProcessException("Cannot interrupt: no process")
    if (pid == null) put_result(Kind.SYSTEM, null, "Cannot interrupt: unknown pid")
    else {
      try {
        if (IsabelleSystem.exec(List("kill", "-INT", pid)).waitFor == 0)
          put_result(Kind.SIGNAL, null, "INT")
        else
          put_result(Kind.SYSTEM, null, "Cannot interrupt: kill command failed")
      }
      catch { case e: IOException => throw new IsabelleProcessException(e.getMessage) }
    }
  }

  def kill() = synchronized {
    if (proc == 0) throw new IsabelleProcessException("Cannot kill: no process")
    else {
      try_close()
      Thread.sleep(500)
      put_result(Kind.SIGNAL, null, "KILL")
      proc.destroy
      proc = null
      pid = null
    }
  }


  /* output being piped into the process */

  private val output = new LinkedBlockingQueue[String]

  def output_raw(text: String) = synchronized {
    if (proc == null) throw new IsabelleProcessException("Cannot output: no process")
    if (closing) throw new IsabelleProcessException("Cannot output: already closing")
    output.put(text)
  }

  def output_sync(text: String) = output_raw(" \\<^sync>\n; " + text + " \\<^sync>;\n")


  def command(text: String) =
    output_sync("Isabelle.command " + IsabelleSyntax.encode_string(text))

  def command(props: Properties, text: String) =
    output_sync("Isabelle.command " + IsabelleSyntax.encode_properties(props) + " " +
      IsabelleSyntax.encode_string(text))

  def ML(text: String) =
    output_sync("ML_val " + IsabelleSyntax.encode_string(text))

  def close() = synchronized {    // FIXME watchdog/timeout
    output_raw("\u0000")
    closing = true
  }

  def try_close() = synchronized {
    if (proc != null && !closing) {
      try { close() }
      catch { case _: IsabelleProcessException => () }
    }
  }


  /* stdin */

  private class StdinThread(writer: BufferedWriter) extends Thread {
    override def run() = {
      var finished = false
      while (!finished) {
        try {
          //{{{
          val s = output.take
          if (s == "\u0000") {
            writer.close
            finished = true
          }
          else {
            put_result(Kind.STDIN, null, s)
            writer.write(s)
            writer.flush
          }
          //}}}
        }
        catch {
          case e: IOException => put_result(Kind.SYSTEM, null, "Stdin thread: " + e.getMessage)
        }
      }
      put_result(Kind.SYSTEM, null, "Stdin thread terminated")
    }
  }


  /* stdout */

  private class StdoutThread(reader: BufferedReader) extends Thread {
    override def run() = {
      var kind = Kind.STDOUT
      var props: Properties = null
      var result = new StringBuilder

      var finished = false
      while (!finished) {
        try {
          if (kind == Kind.STDOUT) {
            //{{{ Char mode
            var c = -1
            var done = false
            while (!done && (result.length == 0 || reader.ready)) {
              c = reader.read
              if (c > 0 && c != 2) result.append(c.asInstanceOf[Char])
              else done = true
            }
            if (result.length > 0) {
              put_result(kind, null, result.toString)
              result.length = 0
            }
            if (c == -1) {
              reader.close
              finished = true
              try_close()
            }
            else if (c == 2) {
              reader.read match {
                case 'A' => kind = Kind.WRITELN
                case 'B' => kind = Kind.PRIORITY
                case 'C' => kind = Kind.TRACING
                case 'D' => kind = Kind.WARNING
                case 'E' => kind = Kind.ERROR
                case 'F' => kind = Kind.DEBUG
                case 'G' => kind = Kind.PROMPT
                case 'H' => kind = Kind.INIT
                case 'I' => kind = Kind.STATUS
                case _ => kind = Kind.STDOUT
              }
              props = null
            }
            //}}}
          }
          else {
            //{{{ Line mode
            val line = reader.readLine
            if (line == null) {
              reader.close
              finished = true
              try_close()
            }
            else {
              val len = line.length
              // property
              if (line.endsWith("\u0002,")) {
                val i = line.indexOf('=')
                if (i > 0) {
                  val name = line.substring(0, i)
                  val value = line.substring(i + 1, len - 2)
                  if (props == null) props = new Properties
                  if (!props.containsKey(name)) props.setProperty(name, value)
                }
              }
              // last text line
              else if (line.endsWith("\u0002.")) {
                result.append(line.substring(0, len - 2))
                put_result(kind, props, result.toString)
                result.length = 0
                kind = Kind.STDOUT
              }
              // text line
              else {
                result.append(line)
                result.append('\n')
              }
            }
            //}}}
          }
        }
        catch {
          case e: IOException => put_result(Kind.SYSTEM, null, "Stdout thread: " + e.getMessage)
        }
      }
      put_result(Kind.SYSTEM, null, "Stdout thread terminated")
    }
  }


  /* stderr */

  private class StderrThread(reader: BufferedReader) extends Thread {
    override def run() = {
      var result = new StringBuilder(100)

      var finished = false
      while (!finished) {
        try {
          //{{{
          var c = -1
          var done = false
          while (!done && (result.length == 0 || reader.ready)) {
            c = reader.read
            if (c > 0) result.append(c.asInstanceOf[Char])
            else done = true
          }
          if (result.length > 0) {
            put_result(Kind.STDERR, null, result.toString)
            result.length = 0
          }
          else {
            reader.close
            finished = true
            try_close()
          }
          //}}}
        }
        catch {
          case e: IOException => put_result(Kind.SYSTEM, null, "Stderr thread: " + e.getMessage)
        }
      }
      put_result(Kind.SYSTEM, null, "Stderr thread terminated")
    }
  }


  /* exit */

  private class ExitThread extends Thread {
    override def run() = {
      val rc = proc.waitFor()
      Thread.sleep(300)
      put_result(Kind.SYSTEM, null, "Exit thread terminated")
      put_result(Kind.EXIT, null, Integer.toString(rc))
    }
  }



  /** main **/

  {
    /* exec process */

    try {
      proc = IsabelleSystem.exec(List(
        IsabelleSystem.getenv_strict("ISABELLE_HOME") + "/bin/isabelle-process", "-W") ++ args)
    }
    catch { case e: IOException => throw new IsabelleProcessException(e.getMessage) }


    /* control process via threads */

    val charset = "UTF-8"
    new StdinThread(new BufferedWriter(new OutputStreamWriter(proc.getOutputStream, charset))).start
    new StdoutThread(new BufferedReader(new InputStreamReader(proc.getInputStream, charset))).start
    new StderrThread(new BufferedReader(new InputStreamReader(proc.getErrorStream, charset))).start
    new ExitThread().start
  }

}
