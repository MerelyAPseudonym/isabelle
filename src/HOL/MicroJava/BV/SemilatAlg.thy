(*  Title:      HOL/MicroJava/BV/SemilatAlg.thy
    ID:         $Id$
    Author:     Gerwin Klein
    Copyright   2002 Technische Universitaet Muenchen
*)

header {* \isaheader{More on Semilattices} *}

theory SemilatAlg = Typing_Framework + Product:


constdefs 
  lesubstep_type :: "(nat \<times> 's) list \<Rightarrow> 's ord \<Rightarrow> (nat \<times> 's) list \<Rightarrow> bool"
                    ("(_ /<=|_| _)" [50, 0, 51] 50)
  "x <=|r| y \<equiv> \<forall>(p,s) \<in> set x. \<exists>s'. (p,s') \<in> set y \<and> s <=_r s'"

consts
 "@plusplussub" :: "'a list \<Rightarrow> ('a \<Rightarrow> 'a \<Rightarrow> 'a) \<Rightarrow> 'a \<Rightarrow> 'a" ("(_ /++'__ _)" [65, 1000, 66] 65)
primrec
  "[] ++_f y = y"
  "(x#xs) ++_f y = xs ++_f (x +_f y)"

constdefs
 bounded :: "'s step_type \<Rightarrow> nat \<Rightarrow> bool"
"bounded step n == !p<n. !s. !(q,t):set(step p s). q<n"  

 pres_type :: "'s step_type \<Rightarrow> nat \<Rightarrow> 's set \<Rightarrow> bool"
"pres_type step n A == \<forall>s\<in>A. \<forall>p<n. \<forall>(q,s')\<in>set (step p s). s' \<in> A"

 mono :: "'s ord \<Rightarrow> 's step_type \<Rightarrow> nat \<Rightarrow> 's set \<Rightarrow> bool"
"mono r step n A ==
 \<forall>s p t. s \<in> A \<and> p < n \<and> s <=_r t \<longrightarrow> step p s <=|r| step p t"


lemma pres_typeD:
  "\<lbrakk> pres_type step n A; s\<in>A; p<n; (q,s')\<in>set (step p s) \<rbrakk> \<Longrightarrow> s' \<in> A"
  by (unfold pres_type_def, blast)

lemma monoD:
  "\<lbrakk> mono r step n A; p < n; s\<in>A; s <=_r t \<rbrakk> \<Longrightarrow> step p s <=|r| step p t"
  by (unfold mono_def, blast)

lemma boundedD: 
  "\<lbrakk> bounded step n; p < n; (q,t) : set (step p xs) \<rbrakk> \<Longrightarrow> q < n" 
  by (unfold bounded_def, blast)

lemma lesubstep_type_refl [simp, intro]:
  "(\<And>x. x <=_r x) \<Longrightarrow> x <=|r| x"
  by (unfold lesubstep_type_def) auto

lemma lesub_step_typeD:
  "a <=|r| b \<Longrightarrow> (x,y) \<in> set a \<Longrightarrow> \<exists>y'. (x, y') \<in> set b \<and> y <=_r y'"
  by (unfold lesubstep_type_def) blast


lemma list_update_le_listI [rule_format]:
  "set xs <= A \<longrightarrow> set ys <= A \<longrightarrow> xs <=[r] ys \<longrightarrow> p < size xs \<longrightarrow>  
   x <=_r ys!p \<longrightarrow> semilat(A,r,f) \<longrightarrow> x\<in>A \<longrightarrow> 
   xs[p := x +_f xs!p] <=[r] ys"
  apply (unfold Listn.le_def lesub_def semilat_def)
  apply (simp add: list_all2_conv_all_nth nth_list_update)
  done


lemma plusplus_closed: 
  "\<And>y. \<lbrakk>semilat (A, r, f); set x \<subseteq> A; y \<in> A\<rbrakk> \<Longrightarrow> x ++_f y \<in> A"
proof (induct x)
  show "\<And>y. y \<in> A \<Longrightarrow> [] ++_f y \<in> A" by simp
  fix y x xs
  assume sl: "semilat (A, r, f)" and y: "y \<in> A" and xs: "set (x#xs) \<subseteq> A"
  assume IH: "\<And>y. \<lbrakk>semilat (A, r, f); set xs \<subseteq> A; y \<in> A\<rbrakk> \<Longrightarrow> xs ++_f y \<in> A"
  from xs obtain x: "x \<in> A" and "set xs \<subseteq> A" by simp  
  from sl x y have "(x +_f y) \<in> A" by (simp add: closedD)
  with sl xs have "xs ++_f (x +_f y) \<in> A" by - (rule IH)
  thus "(x#xs) ++_f y \<in> A" by simp
qed

lemma ub2: "\<And>y. \<lbrakk>semilat (A, r, f); set x \<subseteq> A; y \<in> A\<rbrakk> \<Longrightarrow> y <=_r x ++_f y"
proof (induct x)
  show "\<And>y. semilat(A, r, f) \<Longrightarrow> y <=_r [] ++_f y" by simp 
  
  fix y a l
  assume sl: "semilat (A, r, f)"
  assume y:  "y \<in> A"
  assume "set (a#l) \<subseteq> A"
  then obtain a: "a \<in> A" and x: "set l \<subseteq> A" by simp 
  assume "\<And>y. \<lbrakk>semilat (A, r, f); set l \<subseteq> A; y \<in> A\<rbrakk> \<Longrightarrow> y <=_r l ++_f y"
  hence IH: "\<And>y. y \<in> A \<Longrightarrow> y <=_r l ++_f y" .

  from sl have "order r" .. note order_trans [OF this, trans]  
  
  from sl a y have "y <=_r a +_f y" by (rule semilat_ub2)
  also
  from sl a y have "a +_f y \<in> A" by (simp add: closedD)
  hence "(a +_f y) <=_r l ++_f (a +_f y)" by (rule IH)
  finally
  have "y <=_r l ++_f (a +_f y)" .
  thus "y <=_r (a#l) ++_f y" by simp
qed


lemma ub1: 
  "\<And>y. \<lbrakk>semilat (A, r, f); set ls \<subseteq> A; y \<in> A; x \<in> set ls\<rbrakk> \<Longrightarrow> x <=_r ls ++_f y"
proof (induct ls)
  show "\<And>y. x \<in> set [] \<Longrightarrow> x <=_r [] ++_f y" by simp
  
  fix y s ls
  assume sl: "semilat (A, r, f)" 
  hence "order r" .. note order_trans [OF this, trans]
  assume "set (s#ls) \<subseteq> A"
  then obtain s: "s \<in> A" and ls: "set ls \<subseteq> A" by simp
  assume y: "y \<in> A" 

  assume 
    "\<And>y. \<lbrakk>semilat (A, r, f); set ls \<subseteq> A; y \<in> A; x \<in> set ls\<rbrakk> \<Longrightarrow> x <=_r ls ++_f y"
  hence IH: "\<And>y. x \<in> set ls \<Longrightarrow> y \<in> A \<Longrightarrow> x <=_r ls ++_f y" .

  assume "x \<in> set (s#ls)"
  then obtain xls: "x = s \<or> x \<in> set ls" by simp
  moreover {
    assume xs: "x = s"
    from sl s y have "s <=_r s +_f y" by (rule semilat_ub1)
    also
    from sl s y have "s +_f y \<in> A" by (simp add: closedD)
    with sl ls have "(s +_f y) <=_r ls ++_f (s +_f y)" by (rule ub2)
    finally 
    have "s <=_r ls ++_f (s +_f y)" .
    with xs have "x <=_r ls ++_f (s +_f y)" by simp
  } 
  moreover {
    assume "x \<in> set ls"
    hence "\<And>y. y \<in> A \<Longrightarrow> x <=_r ls ++_f y" by (rule IH)
    moreover
    from sl s y
    have "s +_f y \<in> A" by (simp add: closedD)
    ultimately 
    have "x <=_r ls ++_f (s +_f y)" .
  }
  ultimately 
  have "x <=_r ls ++_f (s +_f y)" by blast
  thus "x <=_r (s#ls) ++_f y" by simp
qed


lemma ub1': 
  "\<lbrakk>semilat (A, r, f); \<forall>(p,s) \<in> set S. s \<in> A; y \<in> A; (a,b) \<in> set S\<rbrakk> 
  \<Longrightarrow> b <=_r map snd [(p', t')\<in>S. p' = a] ++_f y" 
proof -
  let "b <=_r ?map ++_f y" = ?thesis

  assume "semilat (A, r, f)" "y \<in> A"
  moreover
  assume "\<forall>(p,s) \<in> set S. s \<in> A"
  hence "set ?map \<subseteq> A" by auto
  moreover
  assume "(a,b) \<in> set S"
  hence "b \<in> set ?map" by (induct S, auto)
  ultimately
  show ?thesis by - (rule ub1)
qed
    
 

lemma plusplus_empty:  
  "\<forall>s'. (q, s') \<in> set S \<longrightarrow> s' +_f ss ! q = ss ! q \<Longrightarrow>
   (map snd [(p', t')\<in> S. p' = q] ++_f ss ! q) = ss ! q"
apply (induct S)
apply auto 
done


end
