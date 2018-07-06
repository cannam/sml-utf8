signature CODEPOINT_IO = sig

    type instream
    type outstream
                       
    val openIn : string -> instream
    val openString : string -> instream
    val fromTextInStream : TextIO.instream -> instream
    val fromBinInStream : BinIO.instream -> instream

    val peek1 : instream -> word option
    val peekN : instream * int -> WdString.t

    val input1 : instream -> word option
    val inputN : instream * int -> WdString.t

    val inputAll : instream -> WdString.t
    val inputLine : instream -> WdString.t option

    val closeIn : instream -> unit
    val endOfStream : instream -> bool

    val openOut : string -> outstream
    val fromTextOutStream : TextIO.outstream -> outstream
    val fromBinOutStream : BinIO.outstream -> outstream

    val output : outstream * WdString.t -> unit
    val output1 : outstream * word -> unit
    val outputUtf8 : outstream * string -> unit

    val flushOut : outstream -> unit
    val closeOut : outstream -> unit
                                    
end
