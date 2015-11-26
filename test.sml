
fun app_stream f stream =
    case TextIO.inputLine stream of
	SOME line => (f line; app_stream f stream)
      | NONE => ()

fun process_file f =
    let val stream = TextIO.openIn f
        val process = Utf8.toString o Utf8.implode o Utf8.explode o Utf8.fromString
    in
        app_stream (print o process) stream;
        TextIO.closeIn stream
    end
        
fun main () =
    (process_file "UTF-8-test.txt";
     process_file "simple.txt")
