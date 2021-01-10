
(* Copyright 2015-2017 Chris Cannam.
   MIT/X11 licence. See the file COPYING for details. *)

signature SIMPLE_WIDE_STRING = sig

    eqtype t

    (** Obtain the number of ISO-10646 codepoints in the string. *)
    val size : t -> int

    (** Obtain a single ISO-10646 codepoint by index within the
        string. This may not correspond to a printable character, as we
        have simple codepoints, not Unicode grapheme clusters. *)
    val sub : t * int -> word
                             
    (** Concatenate a list of strings. *)
    val concat : t list -> t

    (** Concatenate a list of strings with the given separator. *)
    val concatWith : t -> t list -> t

    (** Compare two strings and return LESS, GREATER, or EQUAL. The
        comparison is based on codepoint numbers, not on any
        meaningful collation order. *)
    val compare : t * t -> order

    (** The empty string. *)
    val empty : t

    (** Apply the given function returning unit to each codepoint in
        the string in turn. *)
    val app : (word -> unit) -> t -> unit

    (** Apply the given function to each codepoint in the string in
        turn, and return the string comprised of the codepoints returned,
        in order. *)
    val map : (word -> word) -> t -> t

    (** Apply a fold function over the codepoints in the string, from
        the left. *)
    val foldl : (word * 'a -> 'a) -> 'a -> t -> 'a
                                                    
    (** Apply a fold function over the codepoints in the string, from 
        the right. *)
    val foldr : (word * 'a -> 'a) -> 'a -> t -> 'a

    (** Generate a new string by supplying successive indices to a
        function that returns a codepoint based on index *)
    val tabulate : int * (int -> word) -> t
                                                    
    (** Convert a list of codepoints to a simple wide string. *)
    val implode : word list -> t

    (** Convert a simple wide string to a list of codepoints. *)
    val explode : t -> word list

    (** Convert a vector of codepoints to a simple wide string. (The
        string is a vector of codepoints internally, so this is a
        trivial conversion.) *)
    val fromVector : word vector -> t

    (** Convert a simple wide string to a vector of codepoints. (The
        string is a vector of codepoints internally, so this is a
        trivial conversion.) *)
    val toVector : t -> word vector

    (** Convert a narrow string in UTF-8 encoding into a simple wide
        string. That is, decode the UTF-8. *)
    val fromUtf8 : string -> t
                                 
    (** Convert a simple wide string into a narrow string in UTF-8
        encoding. That is, encode in UTF-8. *)
    val toUtf8 : t -> string

    (** Convert a narrow string in UTF-8 encoding into a list of
        ISO-10646 codepoints. *)
    val explodeUtf8 : string -> word list
                                     
    (** Convert a list of ISO-10646 codepoints into a narrow string in
        UTF-8 encoding. *)
    val implodeToUtf8 : word list -> string
                                       
end
