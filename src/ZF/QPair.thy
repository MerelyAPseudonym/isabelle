(*  Title: 	ZF/qpair.thy
    ID:         $Id$
    Author: 	Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1993  University of Cambridge

Quine-inspired ordered pairs and disjoint sums, for non-well-founded data
structures in ZF.  Does not precisely follow Quine's construction.  Thanks
to Thomas Forster for suggesting this approach!

W. V. Quine, On Ordered Pairs and Relations, in Selected Logic Papers,
1966.
*)

QPair = Sum +
consts
  QPair     :: "[i, i] => i"               	("<(_;/ _)>")
  qsplit    :: "[[i,i] => i, i] => i"
  qfsplit   :: "[[i,i] => o, i] => o"
  qconverse :: "i => i"
  "@QSUM"   :: "[idt, i, i] => i"               ("(3QSUM _:_./ _)" 10)
  " <*>"    :: "[i, i] => i"         		("(_ <*>/ _)" [81, 80] 80)
  QSigma    :: "[i, i => i] => i"

  "<+>"     :: "[i,i]=>i"      			(infixr 65)
  QInl,QInr :: "i=>i"
  qcase     :: "[i=>i, i=>i, i]=>i"

translations
  "QSUM x:A. B"  => "QSigma(A, %x. B)"

rules
  QPair_def       "<a;b> == a+b"
  qsplit_def      "qsplit(c,p)  ==  THE y. EX a b. p=<a;b> & y=c(a,b)"
  qfsplit_def     "qfsplit(R,z) == EX x y. z=<x;y> & R(x,y)"
  qconverse_def   "qconverse(r) == {z. w:r, EX x y. w=<x;y> & z=<y;x>}"
  QSigma_def      "QSigma(A,B)  ==  UN x:A. UN y:B(x). {<x;y>}"

  qsum_def        "A <+> B      == QSigma({0}, %x.A) Un QSigma({1}, %x.B)"
  QInl_def        "QInl(a)      == <0;a>"
  QInr_def        "QInr(b)      == <1;b>"
  qcase_def       "qcase(c,d)   == qsplit(%y z. cond(y, d(z), c(z)))"
end

ML

(* 'Dependent' type operators *)

val parse_translation =
  [(" <*>", ndependent_tr "QSigma")];

val print_translation =
  [("QSigma", dependent_tr' ("@QSUM", " <*>"))];
