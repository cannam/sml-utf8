
(* Take an input file and pass it through a utf8 decoder/encoder
   chain, writing the result to stdout. Used for integrity checks. *)

fun app_stream f stream =
    case TextIO.inputLine stream of
	SOME line => (f line; app_stream f stream)
      | NONE => ()

fun process_file f =
    let val stream = TextIO.openIn f
        val process = WdString.toUtf8 o WdString.implode o
                      WdString.explode o WdString.fromUtf8
    in
        app_stream (print o process) stream;
        TextIO.closeIn stream
    end
        
fun main () =
    case CommandLine.arguments () of
        [infile] => process_file infile
      | _ => (TextIO.output (TextIO.stdErr, "Usage: process file.txt\n");
              raise Fail "Incorrect arguments specified")

                 
