(*  ID:         $Id$
    Authors:    Klaus Aehlig, Tobias Nipkow

Test of normalization function
*)

theory NormalForm
imports Main
begin

normal_form "True \<longrightarrow> p"

(* FIXME Eventually the code generator should be able to handle this
by re-generating the existing code for "or":

declare disj_assoc[code]

normal_form "(P | Q) | R"

*)


datatype n = Z | S n
consts
 add :: "n \<Rightarrow> n \<Rightarrow> n"
 add2 :: "n \<Rightarrow> n \<Rightarrow> n"
 mul :: "n \<Rightarrow> n \<Rightarrow> n"
 mul2 :: "n \<Rightarrow> n \<Rightarrow> n"
 exp :: "n \<Rightarrow> n \<Rightarrow> n"
primrec
"add Z = id"
"add (S m) = S o add m"
primrec
"add2 Z n = n"
"add2 (S m) n = S(add2 m n)"

lemma [code]: "add2 (add2 n m) k = add2 n (add2 m k)"
by(induct n, auto)
lemma [code]: "add2 n (S m) =  S(add2 n m)"
by(induct n, auto)
lemma [code]: "add2 n Z = n"
by(induct n, auto)
 
normal_form "add2 (add2 n m) k"
normal_form "add2 (add2 (S n) (S m)) (S k)"
normal_form "add2 (add2 (S n)(add2 (S m) Z)) (S k)"

primrec
"mul Z = (%n. Z)"
"mul (S m) = (%n. add (mul m n) n)"
primrec
"mul2 Z n = Z"
"mul2 (S m) n = add2 n (mul2 m n)"
primrec
"exp m Z = S Z"
"exp m (S n) = mul (exp m n) m"

normal_form "mul2 (S(S(S(S(S(S(S Z))))))) (S(S(S(S(S Z)))))"
normal_form "mul (S(S(S(S(S(S(S Z))))))) (S(S(S(S(S Z)))))"
normal_form "exp (S(S Z)) (S(S(S(S(S Z)))))"

normal_form "[] @ []"
normal_form "[] @ xs"
normal_form "[] @ (xs:: 'b list)"
normal_form "[a::'d,b,c] @ xs"
normal_form "[%a::'x. a, %b. b, c] @ xs"
normal_form "[%a::'x. a, %b. b, c] @ [u,v]"
normal_form "map f (xs::'c list)"
normal_form "map f [x,y,z::'x]"
normal_form "map (%f. f True) [id,g,Not]"
normal_form "map (%f. f True) ([id,g,Not] @ fs)"
normal_form "rev[a,b,c]"
normal_form "rev(a#b#cs)"
normal_form "map map [f,g,h]"
normal_form "map (%F. F [a,b,c::'x]) (map map [f,g,h])"
normal_form "map (%F. F ([a,b,c] @ ds)) (map map ([f,g,h]@fs))"
normal_form "map (%F. F [Z,S Z,S(S Z)]) (map map [S,add (S Z),mul (S(S Z)),id])"
normal_form "map (%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True) [None, Some ()]"
normal_form "case xs of [] \<Rightarrow> True | x#xs \<Rightarrow> False"
normal_form "case Z of Z \<Rightarrow> True | S x \<Rightarrow> False"
normal_form "map (%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True) xs"
normal_form "let x = y::'x in [x,x]"
normal_form "Let y (%x. [x,x])"
normal_form "case n of Z \<Rightarrow> True | S x \<Rightarrow> False"
normal_form "(%(x,y). add x y) (S z,S z)"
normal_form "filter (%x. x) ([True,False,x]@xs)"
normal_form "filter Not ([True,False,x]@xs)"

normal_form "0 + (n::nat)"
normal_form "0 + Suc(n)"
normal_form "0::nat"
normal_form "Suc(n) + Suc m"
normal_form "[] @ xs"
normal_form "(x#xs) @ ys"
normal_form "[x,y,z] @ [a,b,c]"
normal_form "%(xs, ys). xs @ ys"
normal_form "(%(xs, ys). xs @ ys) ([a, b, c], [d, e, f])"
normal_form "%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True"
normal_form "map (%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True) [None, Some ()]"

normal_form "case n of None \<Rightarrow> True | Some((x,y),(u,v)) \<Rightarrow> False"
normal_form "let ((x,y),(u,v)) = ((Z,Z),(Z,Z)) in add (add x y) (add u v)"
normal_form "(%((x,y),(u,v)). add (add x y) (add u v)) ((Z,Z),(Z,Z))"
normal_form "last[a,b,c]"
normal_form "last([a,b,c]@xs)"
normal_form " (0::nat) < (0::nat)"

(* FIXME
  won't work since it relies on 
  polymorphically used ad-hoc overloaded function:
  normal_form "max 0 (0::nat)"
*)

text {*
  Numerals still take their time\<dots>
*}

end
