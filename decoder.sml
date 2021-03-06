
(* Copyright 2015-2017 Chris Cannam.
   MIT/X11 licence. See the file COPYING for details. *)

structure Utf8Decoder :> sig

    (** Left fold over a UTF-8 string, yielding a series of ISO-10646
        codepoint values. *)
    val foldlString :
        (word * word list -> word list) -> word list -> string
        -> word list

    (** Return true if the given string is valid UTF-8, false
        otherwise. *)
    val isValidUtf8 :
        string -> bool
        
    (** Return true if the given string can be the start of a valid
        UTF-8 string, i.e. if it is valid UTF-8 with the possible
        exception that it may end in the middle of a codepoint. *)
    val isValidUtf8Prefix :
        string -> bool
        
end = struct

    val codepoint_limit = 0wx10ffff

    (* Replace invalid encodings with the replacement character - this
       is current recommended practice rather than using an exception *)
    val replacement = 0wxfffd

    val b1_mask = 0wx80 (* 10000000 *)
    val b2_mask = 0wxe0 (* 11100000 *)
    val b3_mask = 0wxf0 (* 11110000 *)
    val b4_mask = 0wxf8 (* 11111000 *)
    val bb_mask = 0wxc0 (* 11000000 *)

    val b2_marker = 0wxc0 (* 11000000 *)
    val b3_marker = 0wxe0 (* 11100000 *)
    val b4_marker = 0wxf0 (* 11110000 *)
    val bb_marker = 0wx80 (* 10000000 *)

    fun overlong n =
        (* A codepoint obtained from an n-byte encoding should be at
           least this number; if smaller, it is an overlong encoding *)
        case n of
            2 => 0wx0080
          | 3 => 0wx0800
          | 4 => 0wx10000
          | _ => 0wx0

    val surrogate_start = 0wxd800
    val surrogate_end   = 0wxdfff
                     
    fun foldlString f a s =
        let open Word
	    infix 6 orb andb xorb <<

            fun decode (byte, (n, i, cp, a)) =

                (* 
                   byte is the next byte in the encoding.

                   n is the total number of bytes being decoded for
                   the pending codepoint (if any, otherwise 0). It's
                   used after the codepoint has been decoded, to
                   confirm that it was a high enough codepoint for the
                   byte count so as to reject overlong encodings.

                   i is the number of bytes remaining to be decoded
                   for the pending codepoint, counting down with each
                   byte.

                   cp is the pending codepoint in the process of being
                   decoded.

                   a is the accumulator value from the outer foldl, so
                   the value that will be passed to a call to the fold
                   function along with each new codepoint.
                *)

                let val w = Word.fromLargeWord (Word8.toLargeWord byte)
                in
                    case i of
                        0 => if w andb b1_mask = 0wx0 then
                                 (0, 0, 0wx0, f (w, a))
                             else if w andb b2_mask = b2_marker then
                                 (2, 1, w xorb b2_marker, a)
                             else if w andb b3_mask = b3_marker then
                                 (3, 2, w xorb b3_marker, a)
                             else if w andb b4_mask = b4_marker then
                                 (4, 3, w xorb b4_marker, a)
                             else
                                 (0, 0, 0wx0, f (replacement, a))

                      | 1 => if w andb bb_mask = bb_marker then
                                 let val cp = (cp << 0w6) orb (w xorb bb_marker)
                                 in
                                     if cp < overlong n then
                                         (0, 0, 0wx0, f (replacement, a))
                                     else if cp > codepoint_limit then
                                         (0, 0, 0wx0, f (replacement, a))
                                     else if cp >= surrogate_start andalso
                                             cp <= surrogate_end then
                                         (0, 0, 0wx0, f (replacement, a))
                                     else
                                         (0, 0, 0wx0, f (cp, a))
                                 end
                             else
                                 decode (byte, (0, 0, 0wx0, f (replacement, a)))

                      | i => if w andb bb_mask = bb_marker then
                                 let val cp = (cp << 0w6) orb (w xorb bb_marker)
                                 in (n, Int.-(i, 1), cp, a)
                                 end
                             else
                                 decode (byte, (0, 0, 0wx0, f (replacement, a)))
                end
        in
            case Word8Vector.foldl decode (0, 0, 0wx0, a)
                                   (Byte.stringToBytes s) of
                (n, 0, 0wx0, result) => result
              | (n, i, cp, result) => f (replacement, result)
        end
                     
    fun isValidUtf8' mayBePrefix s =
        let open Word
	    infix 6 orb andb xorb <<

            (* Similar naming to "decode" within foldlString above.
               See introductory comment there. This is directly tail-
               recursive rather than a fold function *)
                    
            fun check [] (_, _, 0wx0) = true
              | check [] (_, _, cp)   = mayBePrefix
              | check (char :: chars) (n, i, cp) =
                let val w = Word.fromLargeWord
                                (Word8.toLargeWord(Byte.charToByte char))
                    val check' = check chars
                in
                    case i of
                        0 => if w andb b1_mask = 0wx0 then
                                 check' (0, 0, 0wx0)
                             else if w andb b2_mask = b2_marker then
                                 check' (2, 1, w xorb b2_marker)
                             else if w andb b3_mask = b3_marker then
                                 check' (3, 2, w xorb b3_marker)
                             else if w andb b4_mask = b4_marker then
                                 check' (4, 3, w xorb b4_marker)
                             else
                                 false

                      | 1 => if w andb bb_mask = bb_marker then
                                 let val cp = (cp << 0w6) orb (w xorb bb_marker)
                                 in
                                     if cp < overlong n then
                                         false
                                     else if cp > codepoint_limit then
                                         false
                                     else if cp >= surrogate_start andalso
                                             cp <= surrogate_end then
                                         false
                                     else
                                         check' (0, 0, 0wx0)
                                 end
                             else
                                 false

                      | i => if w andb bb_mask = bb_marker then
                                 let val cp = (cp << 0w6) orb (w xorb bb_marker)
                                 in check' (n, Int.-(i, 1), cp)
                                 end
                             else
                                 false
                end
        in
            check (explode s) (0, 0, 0wx0)
        end
                           
    val isValidUtf8 = isValidUtf8' false
    val isValidUtf8Prefix = isValidUtf8' true
      
end
                        
