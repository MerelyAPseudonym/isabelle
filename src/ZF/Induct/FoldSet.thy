(*  Title:      ZF/Induct/FoldSet.thy
    ID:         $Id$
    Author:     Sidi O Ehmety, Cambridge University Computer Laboratory


A "fold" functional for finite sets.  For n non-negative we have
fold f e {x1,...,xn} = f x1 (... (f xn e)) where f is at
least left-commutative.  
*)

FoldSet =  Main +

consts fold_set :: "[i, i, [i,i]=>i, i] => i"

inductive
  domains "fold_set(A, B, f,e)" <= "Fin(A)*B"
  intrs
  emptyI   "e:B ==> <0, e>:fold_set(A, B, f,e)"
  consI  "[| x:A; x ~:C;  <C,y> : fold_set(A, B,f,e); f(x,y):B |]
              ==>  <cons(x,C), f(x,y)>:fold_set(A, B, f, e)"
   type_intrs "Fin_intros"
  
constdefs
  
  fold :: "[i, [i,i]=>i, i, i] => i"  ("fold[_]'(_,_,_')")
  "fold[B](f,e, A) == THE x. <A, x>:fold_set(A, B, f,e)"

   setsum :: "[i=>i, i] => i"
  "setsum(g, C) == if Finite(C) then
                    fold[int](%x y. g(x) $+ y, #0, C) else #0"
end