
signature SIMPLE_WIDE_STRING = sig

    eqtype t

    val size : t -> int
    val sub : t * int -> word
    val concat : t list -> t
    val concatWith : t -> t list -> t
    val explode : t -> word list
    val implode : word list -> t
    val compare : t * t -> order
    val empty : t

    val map : (word -> word) -> t -> t
    val foldl : (word * 'a -> 'a) -> 'a -> t -> 'a
    val foldr : (word * 'a -> 'a) -> 'a -> t -> 'a

    val fromUtf8 : string -> t
    val toUtf8 : t -> string

    val explodeUtf8 : string -> word list
    val implodeUtf8 : word list -> string
                                       
end
