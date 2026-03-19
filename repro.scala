//> using platform native
//> using scala 3.3
//> using dep com.lihaoyi::os-lib::0.11.8

object Repro {
  def main(args: Array[String]): Unit = {
    val result = os.proc("echo", "hello").call()
    println(result.out.trim())
  }
}
