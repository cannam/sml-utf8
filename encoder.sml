
(* Copyright 2015-2017 Chris Cannam.
   MIT/X11 licence. See the file COPYING for details. *)

structure Utf8Encoder :> sig

    (* Given a container (e.g. a list) of ISO-10646 codepoint values and
       a matching right-fold function (e.g. List.foldr), produce a UTF-8
       encoding as a string. *)
    val codepoints_to_utf8 :
        ((word * char list -> char list) -> char list -> 'a -> char list)
        -> 'a
        -> string

    val codepoint_to_utf8 :
        word -> char list
               
end = struct

    open Word
    infix 6 orb andb >>
    val char_of = Char.chr o toInt
    val codepoint_limit = 0wx10ffff

    fun prepend_utf8 (cp, acc) =
        if cp < 0wx80 then
            char_of cp :: acc
        else if cp < 0wx800 then
	    char_of (0wxc0 orb (cp >> 0w6)) ::
	    char_of (0wx80 orb (cp andb 0wx3f)) ::
            acc
        else if cp < 0wx10000 then
	    char_of (0wxe0 orb (cp >> 0w12)) ::
	    char_of (0wx80 orb ((cp >> 0w6) andb 0wx3f)) ::
	    char_of (0wx80 orb (cp andb 0wx3f)) ::
            acc
        else if cp < codepoint_limit then
	    char_of (0wxf0 orb (cp >> 0w18)) ::
	    char_of (0wx80 orb ((cp >> 0w12) andb 0wx3f)) ::
	    char_of (0wx80 orb ((cp >> 0w6) andb 0wx3f)) ::
	    char_of (0wx80 orb (cp andb 0wx3f)) ::
            acc
        else acc
                              
    fun codepoint_to_utf8 cp =
        prepend_utf8 (cp, [])
                              
    fun codepoints_to_utf8 folder cps =
        String.implode
            (* folder is the foldr function for whichever
               container cps is. We use foldr to ensure the string
               is built up in the right order using only conses *)
            (folder prepend_utf8 [] cps)

end


