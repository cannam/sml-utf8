
(* Copyright 2015-2016 Chris Cannam.
   MIT/X11 licence. See the file COPYING for details. *)
                     
structure WdString :> SIMPLE_WIDE_STRING = struct

    type t = word vector

    val _ = if Word.wordSize < 22 then raise Fail "Inadequate word size" else ()

    val size = Vector.length
    val sub = Vector.sub
            
    val concat = Vector.concat

    fun concatWith u uu =
        Vector.concat
            (List.foldr
                 (fn (w, []) => [w]
                   | (w, a) => w::u::a) [] uu)

    val foldl = Vector.foldl
    val foldr = Vector.foldr
    val app = Vector.app
    val map = Vector.map
                   
    fun explode u = rev (foldl (op ::) [] u)
    val implode = Vector.fromList

    fun fromVector u = u
    fun toVector u = u

    fun explodeUtf8 s = rev (Utf8Decoder.foldl_string (op ::) [] s)
    fun fromUtf8 s = Vector.fromList (explodeUtf8 s)

    val toUtf8 = Utf8Encoder.codepoints_to_utf8 Vector.foldr
    val implodeToUtf8 = Utf8Encoder.codepoints_to_utf8 List.foldr

    val compare = Vector.collate Word.compare

    val empty : word vector = implode []
                  
end
