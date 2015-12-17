
signature UTF8 = sig
    type t

    val foldl : (word * 'a -> 'a) -> 'a -> t -> 'a
    val foldr : (word * 'a -> 'a) -> 'a -> t -> 'a
    val concat : t list -> t
(*    val concatWith : t -> t list -> t *)
    val explode : t -> word list
    val explodeString : string -> word list
    val implode : word list -> t
    val implodeString : word list -> string
    val size : t -> int
    val fromString : string -> t
    val toString : t -> string
    val compare : t * t -> order
    val sub : t * int -> word                               
end
