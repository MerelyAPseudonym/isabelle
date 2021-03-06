(*  Title:      HOL/Tools/TFL/utils.ML
    Author:     Konrad Slind, Cambridge University Computer Laboratory

Basic utilities.
*)

signature UTILS =
sig
  exception ERR of {module: string, func: string, mesg: string}
  val C: ('a -> 'b -> 'c) -> 'b -> 'a -> 'c
  val end_itlist: ('a -> 'a -> 'a) -> 'a list -> 'a
  val itlist2: ('a -> 'b -> 'c -> 'c) -> 'a list -> 'b list -> 'c -> 'c
  val pluck: ('a -> bool) -> 'a list -> 'a * 'a list
  val zip3: 'a list -> 'b list -> 'c list -> ('a*'b*'c) list
  val take: ('a -> 'b) -> int * 'a list -> 'b list
end;

structure Utils: UTILS =
struct

(*standard exception for TFL*)
exception ERR of {module: string, func: string, mesg: string};

fun UTILS_ERR func mesg = ERR {module = "Utils", func = func, mesg = mesg};


fun C f x y = f y x

fun end_itlist f [] = raise (UTILS_ERR "end_itlist" "list too short")
  | end_itlist f [x] = x 
  | end_itlist f (x :: xs) = f x (end_itlist f xs);

fun itlist2 f L1 L2 base_value =
 let fun it ([],[]) = base_value
       | it ((a::rst1),(b::rst2)) = f a b (it (rst1,rst2))
       | it _ = raise UTILS_ERR "itlist2" "different length lists"
 in  it (L1,L2)
 end;

fun pluck p  =
  let fun remv ([],_) = raise UTILS_ERR "pluck" "item not found"
        | remv (h::t, A) = if p h then (h, rev A @ t) else remv (t,h::A)
  in fn L => remv(L,[])
  end;

fun take f =
  let fun grab(0,L) = []
        | grab(n, x::rst) = f x::grab(n-1,rst)
  in grab
  end;

fun zip3 [][][] = []
  | zip3 (x::l1) (y::l2) (z::l3) = (x,y,z)::zip3 l1 l2 l3
  | zip3 _ _ _ = raise UTILS_ERR "zip3" "different lengths";


end;
