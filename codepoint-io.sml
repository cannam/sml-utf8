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

structure CodepointIO :> CODEPOINT_IO = struct

    datatype istr = BIN_ISTREAM of BinIO.instream
                  | TEXT_ISTREAM of TextIO.instream

    datatype ostr = BIN_OSTREAM of BinIO.outstream
                  | TEXT_OSTREAM of TextIO.outstream

    val read_buffer_size = 8192
    val misc_block_size = 1024

    (* A byte masked with bb_mask yields bb_marker if and only if it
       is a continuation byte *)
    val bb_mask   = Word8.fromLargeWord 0wxc0 (* 11000000 *)
    val bb_marker = Word8.fromLargeWord 0wx80 (* 10000000 *)
                                         
    type instream = {
        stream : istr,
        buffer : WdString.t ref,
        index : int ref
    }
                                         
    type outstream = ostr

    fun openIn filename = {
        stream = BIN_ISTREAM (BinIO.openIn filename),
        buffer = ref WdString.empty,
        index = ref 0
    }
            
    fun openString string = {
        stream = TEXT_ISTREAM (TextIO.openString string),
        buffer = ref WdString.empty,
        index = ref 0
    }

    fun fromTextInStream str = {
        stream = TEXT_ISTREAM str,
        buffer = ref WdString.empty,
        index = ref 0
    }

    fun fromBinInStream str = {
        stream = BIN_ISTREAM str,
        buffer = ref WdString.empty,
        index = ref 0
    }

    fun openOut filename =
        BIN_OSTREAM (BinIO.openOut filename)

    fun fromTextOutStream str =
        TEXT_OSTREAM str

    fun fromBinOutStream str =
        BIN_OSTREAM str
                                  
    fun closeIn ({ stream, ... } : instream) =
        case stream of
            BIN_ISTREAM s => BinIO.closeIn s
          | TEXT_ISTREAM s => TextIO.closeIn s

    (*!!! to do: functorise or factorise *)
                                            
    fun readBin (stream, n) : string =
        let val main_buffer = BinIO.inputN (stream, n)
            fun read_to_sync acc stream =
                case BinIO.lookahead stream of
                    NONE => acc
                  | SOME b =>
                    if Word8.andb (b, bb_mask) = bb_marker
                    then (ignore (BinIO.input1 stream);
                          read_to_sync (Byte.byteToChar b :: acc) stream)
                    else acc
            val sync_stub = String.implode (rev (read_to_sync [] stream))
        in
            Byte.bytesToString main_buffer ^ sync_stub
        end

    fun readText (stream, n) : string =
        let val main_buffer = TextIO.inputN (stream, n)
            fun read_to_sync acc stream =
                case TextIO.lookahead stream of
                    NONE => acc
                  | SOME c =>
                    if Word8.andb (Byte.charToByte c, bb_mask) = bb_marker
                    then (ignore (TextIO.input1 stream);
                          read_to_sync (c :: acc) stream)
                    else acc
            val sync_stub = String.implode (rev (read_to_sync [] stream))
        in
            main_buffer ^ sync_stub
        end

    fun readAndConvert (instream : instream, n) : WdString.t =
        WdString.fromUtf8
            (case (#stream instream) of
                 BIN_ISTREAM s => readBin (s, n)
               | TEXT_ISTREAM s => readText (s, n))
            
    datatype load_result = EOF
                         | HAVE of int

    fun available (instream : instream) =
        WdString.size (!(#buffer instream)) - !(#index instream)

    fun shorten (instream as { buffer, index, ... } : instream) =
        if !index > 0
        then let val len = available instream
                 val new_buffer =
                     WdString.tabulate
                         (len, fn i => WdString.sub (!buffer, i + !index))
             in
                 buffer := new_buffer;
                 index := 0
             end
        else ()

    (* Attempt to load enough into the buffer to have n codepoints to
       read. Return EOF if the buffer is empty and nothing is
       available to load. Return HAVE m if we have m codepoints in the
       buffer after loading. If m < n then only partial data was
       available before EOF and no subsequent loadFor call will load
       any more after that. Note that m may be greater than n.
     *)
    fun loadFor (instream, n) : load_result =
        let val have = available instream
        in
            if have >= n
            then HAVE have
            else let val _ = shorten instream
                     val new = readAndConvert (instream, read_buffer_size)
                     val { buffer, index, ... } = instream
                 in
                     buffer := WdString.concat [!buffer, new];
                     case (WdString.size new, available instream) of
                         (0, 0) => EOF
                       | (0, have) => HAVE have
                       | (_, have) => 
                         if have >= n
                         then HAVE have
                         else loadFor (instream, n)
                 end
        end

    fun inRange ({ buffer, index, ... } : instream) =
        !index < WdString.size (!buffer)

    fun endOfStream (instream : instream) =
        (not (inRange instream)) andalso
        case (#stream instream) of
            BIN_ISTREAM s => BinIO.endOfStream s
          | TEXT_ISTREAM s => TextIO.endOfStream s

    fun peek1 (instream : instream) =
        case loadFor (instream, 1) of
            EOF => NONE
          | HAVE _ => SOME (WdString.sub (!(#buffer instream),
                                          !(#index instream)))
        
    fun peekN (instream : instream, n) =
        case loadFor (instream, n) of
            EOF => WdString.empty
          | HAVE m => WdString.tabulate
                          (if m < n then m else n,
                           fn i => WdString.sub
                                       (!(#buffer instream),
                                        i + !(#index instream)))

    fun input1 (instream : instream) =
        case peek1 instream of
            NONE => NONE
          | rv => 
            ((#index instream) := !(#index instream) + 1;
             rv)

    fun inputN (instream : instream, n) =
        case peekN (instream, n) of
            rv =>
            ((#index instream) := !(#index instream) + WdString.size rv;
             rv)
        
    fun inputAll (instream : instream) =
        let val bs = misc_block_size
            fun inputAll' acc =
                let val v = inputN (instream, bs)
                in
                    if WdString.size v = bs
                    then inputAll' (v :: acc)
                    else WdString.concat (rev (v :: acc))
                end
        in
            inputAll' []
        end
                             
    fun inputLine (instream : instream) =
        let val nl = Word.fromInt (Char.ord #"\n")
            fun inputLine' acc =
                case input1 instream of
                    NONE => nl :: acc
                  | SOME c =>
                    if c = nl
                    then c :: acc
                    else inputLine' (c :: acc)
        in
            if endOfStream instream
            then NONE
            else SOME (WdString.implode (rev (inputLine' [])))
        end

    fun output (outstream : outstream, ws : WdString.t) =
        case outstream of
            TEXT_OSTREAM s =>
            TextIO.output (s, WdString.toUtf8 ws)
          | BIN_OSTREAM s =>
            BinIO.output (s, Byte.stringToBytes (WdString.toUtf8 ws))

    fun output1 (outstream : outstream, w : word) =
        case outstream of
            TEXT_OSTREAM s =>
            TextIO.output (s, String.implode (Utf8Encoder.codepointToUtf8 w))
          | BIN_OSTREAM s =>
            BinIO.output (s, Byte.stringToBytes
                                 (String.implode
                                      (Utf8Encoder.codepointToUtf8 w)))

    fun outputUtf8 (outstream : outstream, us : string) =
        case outstream of
            TEXT_OSTREAM s =>
            TextIO.output (s, us)
          | BIN_OSTREAM s =>
            BinIO.output (s, Byte.stringToBytes us)
        
    fun flushOut (outstream : outstream) =
        case outstream of
            TEXT_OSTREAM s => TextIO.flushOut s
          | BIN_OSTREAM s => BinIO.flushOut s
        
    fun closeOut (outstream : outstream) =
        case outstream of
            TEXT_OSTREAM s => TextIO.closeOut s
          | BIN_OSTREAM s => BinIO.closeOut s
                         
end
          
