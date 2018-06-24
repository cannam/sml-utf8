signature IN_STREAM = sig

    type instream
                       
    val openIn : string -> instream
    val openString : string -> instream

    val fromTextStream : TextIO.instream -> instream
    val fromBinStream : BinIO.instream -> instream

    val closeIn : instream -> unit
    val endOfStream : instream -> bool

    val peek1 : instream -> word option
    val peekN : instream * int -> WdString.t

    val input1 : instream -> word option
    val inputN : instream * int -> WdString.t

    val inputAll : instream -> WdString.t
    val inputLine : instream -> WdString.t option

end

(*!!! better name please *)
structure CodepointInStream :> IN_STREAM = struct

    datatype stream = BIN_STREAM of BinIO.instream
                    | TEXT_STREAM of TextIO.instream

    (*!!!    val read_buffer_size = 8192 -- to be restored *)

(*!!! Turtle tests pass with 50 & 1000 but fail with 1 & 2 -- they
should pass with any values *)
                                         
    val read_buffer_size = 50
    val misc_block_size = 1000

    (* A byte masked with bb_mask yields bb_marker if and only if it
       is a continuation byte *)
    val bb_mask   = Word8.fromLargeWord 0wxc0 (* 11000000 *)
    val bb_marker = Word8.fromLargeWord 0wx80 (* 10000000 *)
                                         
    type instream = {
        stream : stream,
        buffer : WdString.t ref,
        index : int ref
    }

    fun openIn filename = {
        stream = BIN_STREAM (BinIO.openIn filename),
        buffer = ref WdString.empty,
        index = ref 0
    }
            
    fun openString string = {
        stream = TEXT_STREAM (TextIO.openString string),
        buffer = ref WdString.empty,
        index = ref 0
    }

    fun fromTextStream str = {
        stream = TEXT_STREAM str,
        buffer = ref WdString.empty,
        index = ref 0
    }

    fun fromBinStream str = {
        stream = BIN_STREAM str,
        buffer = ref WdString.empty,
        index = ref 0
    }
                                
    fun closeIn ({ stream, ... } : instream) =
        case stream of
            BIN_STREAM s => BinIO.closeIn s
          | TEXT_STREAM s => TextIO.closeIn s

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
                 BIN_STREAM s => readBin (s, n)
               | TEXT_STREAM s => readText (s, n))
            
    datatype load_result = EOF
                         | HAVE of int

    fun available (instream : instream) =
        WdString.size (!(#buffer instream)) - !(#index instream)

    fun shorten (instream as { buffer, index, ... } : instream) =
        let val len = available instream
            val new_buffer =
                WdString.implode
                    (List.tabulate
                         (len,
                          fn i => WdString.sub (!buffer, i + !index)))
        in
            buffer := new_buffer;
            index := 0
        end

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
                         else loadFor (instream, n - have)
                 end
        end

    fun inRange ({ buffer, index, ... } : instream) =
        !index < WdString.size (!buffer)

    fun endOfStream (instream : instream) =
        (not (inRange instream)) andalso
        case (#stream instream) of
            BIN_STREAM s => BinIO.endOfStream s
          | TEXT_STREAM s => TextIO.endOfStream s

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
                                          
end
          
