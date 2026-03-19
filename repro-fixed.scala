//> using platform native
//> using scala 3.3
//> using dep com.lihaoyi::os-lib::0.11.8

import scala.scalanative.unsafe._

@extern
private object PosixExit {
  @name("_exit")
  def posixExit(status: CInt): Unit = extern
}

object Repro {
  def main(args: Array[String]): Unit = {
    val result = os.proc("echo", "hello").call()
    println(result.out.trim())
    PosixExit.posixExit(0)
  }
}
