(*  Title:      HOL/MicroJava/BV/Semilat.thy
    ID:         $Id$
    Author:     Tobias Nipkow
    Copyright   2000 TUM

Semilattices
*)

header {* 
  \chapter{Bytecode Verifier}\label{cha:bv}
  \isaheader{Semilattices} 
*}

theory Semilat = While_Combinator:

types 'a ord    = "'a \<Rightarrow> 'a \<Rightarrow> bool"
      'a binop  = "'a \<Rightarrow> 'a \<Rightarrow> 'a"
      'a sl     = "'a set * 'a ord * 'a binop"

consts
 "@lesub"   :: "'a \<Rightarrow> 'a ord \<Rightarrow> 'a \<Rightarrow> bool" ("(_ /<='__ _)" [50, 1000, 51] 50)
 "@lesssub" :: "'a \<Rightarrow> 'a ord \<Rightarrow> 'a \<Rightarrow> bool" ("(_ /<'__ _)" [50, 1000, 51] 50)
defs
lesub_def:   "x <=_r y == r x y"
lesssub_def: "x <_r y  == x <=_r y & x ~= y"

consts
 "@plussub" :: "'a \<Rightarrow> ('a \<Rightarrow> 'b \<Rightarrow> 'c) \<Rightarrow> 'b \<Rightarrow> 'c" ("(_ /+'__ _)" [65, 1000, 66] 65)
defs
plussub_def: "x +_f y == f x y"


constdefs
 ord :: "('a*'a)set \<Rightarrow> 'a ord"
"ord r == %x y. (x,y):r"

 order :: "'a ord \<Rightarrow> bool"
"order r == (!x. x <=_r x) &
            (!x y. x <=_r y & y <=_r x \<longrightarrow> x=y) &
            (!x y z. x <=_r y & y <=_r z \<longrightarrow> x <=_r z)"

 acc :: "'a ord \<Rightarrow> bool"
"acc r == wf{(y,x) . x <_r y}"

 top :: "'a ord \<Rightarrow> 'a \<Rightarrow> bool"
"top r T == !x. x <=_r T"

 closed :: "'a set \<Rightarrow> 'a binop \<Rightarrow> bool"
"closed A f == !x:A. !y:A. x +_f y : A"

 semilat :: "'a sl \<Rightarrow> bool"
"semilat == %(A,r,f). order r & closed A f &
                (!x:A. !y:A. x <=_r x +_f y)  &
                (!x:A. !y:A. y <=_r x +_f y)  &
                (!x:A. !y:A. !z:A. x <=_r z & y <=_r z \<longrightarrow> x +_f y <=_r z)"

 is_ub :: "('a*'a)set \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> bool"
"is_ub r x y u == (x,u):r & (y,u):r"

 is_lub :: "('a*'a)set \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> bool"
"is_lub r x y u == is_ub r x y u & (!z. is_ub r x y z \<longrightarrow> (u,z):r)"

 some_lub :: "('a*'a)set \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'a"
"some_lub r x y == SOME z. is_lub r x y z"


lemma order_refl [simp, intro]:
  "order r \<Longrightarrow> x <=_r x";
  by (simp add: order_def)

lemma order_antisym:
  "\<lbrakk> order r; x <=_r y; y <=_r x \<rbrakk> \<Longrightarrow> x = y"
apply (unfold order_def)
apply (simp (no_asm_simp))  
done

lemma order_trans:
   "\<lbrakk> order r; x <=_r y; y <=_r z \<rbrakk> \<Longrightarrow> x <=_r z"
apply (unfold order_def)
apply blast
done 

lemma order_less_irrefl [intro, simp]:
   "order r \<Longrightarrow> ~ x <_r x"
apply (unfold order_def lesssub_def)
apply blast
done 

lemma order_less_trans:
  "\<lbrakk> order r; x <_r y; y <_r z \<rbrakk> \<Longrightarrow> x <_r z"
apply (unfold order_def lesssub_def)
apply blast
done 

lemma topD [simp, intro]:
  "top r T \<Longrightarrow> x <=_r T"
  by (simp add: top_def)

lemma top_le_conv [simp]:
  "\<lbrakk> order r; top r T \<rbrakk> \<Longrightarrow> (T <=_r x) = (x = T)"
  by (blast intro: order_antisym)

lemma semilat_Def:
"semilat(A,r,f) == order r & closed A f & 
                 (!x:A. !y:A. x <=_r x +_f y) & 
                 (!x:A. !y:A. y <=_r x +_f y) & 
                 (!x:A. !y:A. !z:A. x <=_r z & y <=_r z \<longrightarrow> x +_f y <=_r z)"
apply (unfold semilat_def split_conv [THEN eq_reflection])
apply (rule refl [THEN eq_reflection])
done

lemma semilatDorderI [simp, intro]:
  "semilat(A,r,f) \<Longrightarrow> order r"
  by (simp add: semilat_Def)

lemma semilatDclosedI [simp, intro]:
  "semilat(A,r,f) \<Longrightarrow> closed A f"
apply (unfold semilat_Def)
apply simp
done

lemma semilat_ub1 [simp]:
  "\<lbrakk> semilat(A,r,f); x:A; y:A \<rbrakk> \<Longrightarrow> x <=_r x +_f y"
  by (unfold semilat_Def, simp)

lemma semilat_ub2 [simp]:
  "\<lbrakk> semilat(A,r,f); x:A; y:A \<rbrakk> \<Longrightarrow> y <=_r x +_f y"
  by (unfold semilat_Def, simp)

lemma semilat_lub [simp]:
 "\<lbrakk> x <=_r z; y <=_r z; semilat(A,r,f); x:A; y:A; z:A \<rbrakk> \<Longrightarrow> x +_f y <=_r z";
  by (unfold semilat_Def, simp)


lemma plus_le_conv [simp]:
  "\<lbrakk> x:A; y:A; z:A; semilat(A,r,f) \<rbrakk> 
  \<Longrightarrow> (x +_f y <=_r z) = (x <=_r z & y <=_r z)"
apply (unfold semilat_Def)
apply (blast intro: semilat_ub1 semilat_ub2 semilat_lub order_trans)
done

lemma le_iff_plus_unchanged:
  "\<lbrakk> x:A; y:A; semilat(A,r,f) \<rbrakk> \<Longrightarrow> (x <=_r y) = (x +_f y = y)"
apply (rule iffI)
 apply (intro semilatDorderI order_antisym semilat_lub order_refl semilat_ub2, assumption+)
apply (erule subst)
apply simp
done 

lemma le_iff_plus_unchanged2:
  "\<lbrakk> x:A; y:A; semilat(A,r,f) \<rbrakk> \<Longrightarrow> (x <=_r y) = (y +_f x = y)"
apply (rule iffI)
 apply (intro semilatDorderI order_antisym semilat_lub order_refl semilat_ub1, assumption+)
apply (erule subst)
apply simp
done 


lemma closedD:
  "\<lbrakk> closed A f; x:A; y:A \<rbrakk> \<Longrightarrow> x +_f y : A"
apply (unfold closed_def)
apply blast
done 

lemma closed_UNIV [simp]: "closed UNIV f"
  by (simp add: closed_def)


lemma is_lubD:
  "is_lub r x y u \<Longrightarrow> is_ub r x y u & (!z. is_ub r x y z \<longrightarrow> (u,z):r)"
  by (simp add: is_lub_def)

lemma is_ubI:
  "\<lbrakk> (x,u) : r; (y,u) : r \<rbrakk> \<Longrightarrow> is_ub r x y u"
  by (simp add: is_ub_def)

lemma is_ubD:
  "is_ub r x y u \<Longrightarrow> (x,u) : r & (y,u) : r"
  by (simp add: is_ub_def)


lemma is_lub_bigger1 [iff]:  
  "is_lub (r^* ) x y y = ((x,y):r^* )"
apply (unfold is_lub_def is_ub_def)
apply blast
done

lemma is_lub_bigger2 [iff]:
  "is_lub (r^* ) x y x = ((y,x):r^* )"
apply (unfold is_lub_def is_ub_def)
apply blast 
done

lemma extend_lub:
  "\<lbrakk> single_valued r; is_lub (r^* ) x y u; (x',x) : r \<rbrakk> 
  \<Longrightarrow> EX v. is_lub (r^* ) x' y v"
apply (unfold is_lub_def is_ub_def)
apply (case_tac "(y,x) : r^*")
 apply (case_tac "(y,x') : r^*")
  apply blast
 apply (blast elim: converse_rtranclE dest: single_valuedD)
apply (rule exI)
apply (rule conjI)
 apply (blast intro: converse_rtrancl_into_rtrancl dest: single_valuedD)
apply (blast intro: rtrancl_into_rtrancl converse_rtrancl_into_rtrancl 
             elim: converse_rtranclE dest: single_valuedD)
done

lemma single_valued_has_lubs [rule_format]:
  "\<lbrakk> single_valued r; (x,u) : r^* \<rbrakk> \<Longrightarrow> (!y. (y,u) : r^* \<longrightarrow> 
  (EX z. is_lub (r^* ) x y z))"
apply (erule converse_rtrancl_induct)
 apply clarify
 apply (erule converse_rtrancl_induct)
  apply blast
 apply (blast intro: converse_rtrancl_into_rtrancl)
apply (blast intro: extend_lub)
done

lemma some_lub_conv:
  "\<lbrakk> acyclic r; is_lub (r^* ) x y u \<rbrakk> \<Longrightarrow> some_lub (r^* ) x y = u"
apply (unfold some_lub_def is_lub_def)
apply (rule someI2)
 apply assumption
apply (blast intro: antisymD dest!: acyclic_impl_antisym_rtrancl)
done

lemma is_lub_some_lub:
  "\<lbrakk> single_valued r; acyclic r; (x,u):r^*; (y,u):r^* \<rbrakk> 
  \<Longrightarrow> is_lub (r^* ) x y (some_lub (r^* ) x y)";
  by (fastsimp dest: single_valued_has_lubs simp add: some_lub_conv)

subsection{*An executable lub-finder*}

constdefs
 exec_lub :: "('a * 'a) set \<Rightarrow> ('a \<Rightarrow> 'a) \<Rightarrow> 'a binop"
"exec_lub r f x y == while (\<lambda>z. (x,z) \<notin> r\<^sup>*) f y"


lemma acyclic_single_valued_finite:
 "\<lbrakk>acyclic r; single_valued r; (x,y) \<in> r\<^sup>*\<rbrakk>
  \<Longrightarrow> finite (r \<inter> {a. (x, a) \<in> r\<^sup>*} \<times> {b. (b, y) \<in> r\<^sup>*})"
apply(erule converse_rtrancl_induct)
 apply(rule_tac B = "{}" in finite_subset)
  apply(simp only:acyclic_def)
  apply(blast intro:rtrancl_into_trancl2 rtrancl_trancl_trancl)
 apply simp
apply(rename_tac x x')
apply(subgoal_tac "r \<inter> {a. (x,a) \<in> r\<^sup>*} \<times> {b. (b,y) \<in> r\<^sup>*} =
                   insert (x,x') (r \<inter> {a. (x', a) \<in> r\<^sup>*} \<times> {b. (b, y) \<in> r\<^sup>*})")
 apply simp
apply(blast intro:converse_rtrancl_into_rtrancl
            elim:converse_rtranclE dest:single_valuedD)
done


lemma exec_lub_conv:
  "\<lbrakk> acyclic r; !x y. (x,y) \<in> r \<longrightarrow> f x = y; is_lub (r\<^sup>*) x y u \<rbrakk> \<Longrightarrow>
  exec_lub r f x y = u";
apply(unfold exec_lub_def)
apply(rule_tac P = "\<lambda>z. (y,z) \<in> r\<^sup>* \<and> (z,u) \<in> r\<^sup>*" and
               r = "(r \<inter> {(a,b). (y,a) \<in> r\<^sup>* \<and> (b,u) \<in> r\<^sup>*})^-1" in while_rule)
    apply(blast dest: is_lubD is_ubD)
   apply(erule conjE)
   apply(erule_tac z = u in converse_rtranclE)
    apply(blast dest: is_lubD is_ubD)
   apply(blast dest:rtrancl_into_rtrancl)
  apply(rename_tac s)
  apply(subgoal_tac "is_ub (r\<^sup>*) x y s")
   prefer 2; apply(simp add:is_ub_def)
  apply(subgoal_tac "(u, s) \<in> r\<^sup>*")
   prefer 2; apply(blast dest:is_lubD)
  apply(erule converse_rtranclE)
   apply blast
  apply(simp only:acyclic_def)
  apply(blast intro:rtrancl_into_trancl2 rtrancl_trancl_trancl)
 apply(rule finite_acyclic_wf)
  apply simp
  apply(erule acyclic_single_valued_finite)
   apply(blast intro:single_valuedI)
  apply(simp add:is_lub_def is_ub_def)
 apply simp
 apply(erule acyclic_subset)
 apply blast
apply simp
apply(erule conjE)
apply(erule_tac z = u in converse_rtranclE)
 apply(blast dest: is_lubD is_ubD)
apply(blast dest:rtrancl_into_rtrancl)
done

lemma is_lub_exec_lub:
  "\<lbrakk> single_valued r; acyclic r; (x,u):r^*; (y,u):r^*; !x y. (x,y) \<in> r \<longrightarrow> f x = y \<rbrakk>
  \<Longrightarrow> is_lub (r^* ) x y (exec_lub r f x y)"
  by (fastsimp dest: single_valued_has_lubs simp add: exec_lub_conv)

end
