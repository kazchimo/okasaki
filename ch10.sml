(** 10.1 Structural Decomposition **)

(* Exercise 10.1 *)
(** fun update (0, e, ONE (x, ps)) = ONE (e, ps)
  *   | update (i, e, ONE (x, ps)) = cons (x, update (i - 1, e ZERO ps))
  *   | update (i, e, ZERO ps) =
  *   let val (x, y) = lookup (i div 2, ps)
  *       val p = if i mod 2 = 0 then (e, y) else (x, e)
  *   in ZERO (update i div 2, p, ps) end
  *
  * Let k = log(i + 1). The cost of update is
  *     k + (k - 1) + (k - 2) + ... + 1
  *     = k(k + 1)/2 = ((log(i + 1))^2 + log(i + 1)) / 2 = O((log(n))^2).
  * *)

structure AltBinaryRandomAccessList : RANDOMACCESSLIST =
struct
  datatype 'a RList =
    NIL | ZERO of ('a * 'a) RList | ONE of 'a * ('a * 'a) RList

  val empty = NIL
  fun isEmpty NIL = true | isEmpty _ = false

  fun cons (x, NIL) = ONE (a, NIL)
    | cons (x, ZERO ps) = ONE (x, ps)
    | cons (x, ONE (y, ps)) = ZERO (cons ((x, y), ps))

  fun uncons NIL = raise EMPTY
    | uncons (ONE (x, ps)) = (x, ZERO ps)
    | uncons (ZERO ps) = let val ((x, y), ps') = uncons ps
                         in (x, ONE (y, ps')) end

  fun head xs = let val (x, _) = uncons xs in x end
  fun tail xs = let val (_, xs') = uncons xs in xs' end

  fun lookup (i, NIL) = raise SUBSCRIPT
    | lookup (0, ONE (x, ps)) = x
    | lookup (i, ONE (x, ps)) = lookup (i - 1, ZERO ps)
    | lookup (i, ZERO ps) = let val (x, y) = lookup (i div 2, ps)
                            in if i mod 2 = 0 then x else y end

  fun fupdate (f, i, NIL) = raise SUBSCRIPT
    | fupdate (f, 0, ONE (x, ps)) = ONE (f x, ps)
    | fupdate (f, i, ONE (x, ps)) = cons (x, fupdate (f, i - 1, ZERO ps))
    | fupdate (f, i, ZERO ps) =
    let fun f' (x, y) = if i mod 2 then (f x, y) else (x, f y)
    in ZERO (fupdate (f', i div 2, ps)) end

  fun update (i, y, xs) = fupdate (fn x => y, i, xs)
end

(* Exercise 10.2 *)
structure LazyAltBinaryRandomAccessList : RANDOMACCESSLIST =
struct
  datatype 'a RList = NIL
                    | ONE of 'a * ('a * 'a) RList susp
                    | TWO of 'a * 'a * ('a * 'a) RList susp
                    | THREE of 'a * 'a * 'a * ('a * 'a) RList susp

  val empty = NIL
  fun isEmpty NIL = true | isEmpty _ = false

  fun cons (x, NIL) = ONE (x, $ NIL)
    | cons (x, ONE (y, ps)) = TWO (x, y, ps)
    | cons (x, TWO (y, z, ps)) = THREE (x, y, z, ps)
    | cons (x1, THREE (x2, y, z, ps)) = TWO (x1, x2, $ cons ((y, z), ps))

  fun uncons NIL = raise EMPTY
    | uncons (ONE (x, $ NIL)) = (x, NIL)
    | uncons (ONE (x, $ ps)) =
    let val ((y, z), ps') = uncons ps in (x, TWO (y, z, $ ps')) end
    | uncons (TWO (x, y, ps)) = (x, ONE (y, ps))
    | uncons (THREE (x, y, z, ps)) = (x, TWO (y, z, ps))

  fun head NIL = raise EMPTY
    | head (ONE (x, ps)) = x
    | head (TWO (x, y, ps)) = x
    | head (THREE (x, y, z, ps)) = x
  fun tail xs = let val (_, xs') = uncons xs in xs' end

  fun lookup (i, NIL) = raise SUBSCRIPT
    | lookup (i, ONE (x, ps)) =
    if i = 0 then x
    else let val (x', y') = lookup ((i - 1) div 2, force ps)
         in if (i - 1) mod 2 = 0 then x' else y' end
    | lookup (i, TWO (x, y, ps)) =
    if i = 0 then x else lookup (i - 1, ONE (y, ps))
    | lookup (i, THREE (x, y, z, ps)) =
    if i = 0 then x else lookup (i - 1, TWO (y, z, ps))

  fun fupdate (f, i, ONE (x, ps)) =
    if i = 0 then ONE (f x, ps)
    else
      let
        fun f' (x, y) = if i mod 2 = 0 then (f x, y) else (x, f y)
        val ps' = fupdate (f', i div 2, force ps)
      in ONE (x, $ ps') end
    | fupdate (f, i, TWO (x, y, ps)) =
    if i = 0 then TWO (f x, y, ps)
    else cons (x, fupdate (f, i - 1, ONE (y, ps)))
    | fupdate (f, i, THREE (x, y, z, ps)) =
    if i = 0 then THREE (f x, y, z, ps)
    else cons (x, fupdate (f, i - 1, TWO (y, z, ps)))

  fun update (i, y, xs) = fupdate (fn x => y, i, xs)

  (** Proof is same as exercise 9.9 *)
end

