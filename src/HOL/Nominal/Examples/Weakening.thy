(* $Id$ *)

theory weakening 
imports "../nominal" 
begin

(* WEAKENING EXAMPLE*)

section {* Simply-Typed Lambda-Calculus *}
(*======================================*)

atom_decl name 

nominal_datatype lam = Var "name"
                     | App "lam" "lam"
                     | Lam "\<guillemotleft>name\<guillemotright>lam" ("Lam [_]._" [100,100] 100)

datatype ty =
    TVar "string"
  | TArr "ty" "ty" (infix "\<rightarrow>" 200)

primrec
 "pi\<bullet>(TVar s) = TVar s"
 "pi\<bullet>(\<tau> \<rightarrow> \<sigma>) = (\<tau> \<rightarrow> \<sigma>)"

lemma perm_ty[simp]:
  fixes pi ::"name prm"
  and   \<tau>  ::"ty"
  shows "pi\<bullet>\<tau> = \<tau>"
  by (cases \<tau>, simp_all)

instance ty :: pt_name
apply(intro_classes)   
apply(simp_all)
done

instance ty :: fs_name
apply(intro_classes)
apply(simp add: supp_def)
done

(* valid contexts *)
consts
  ctxts :: "((name\<times>ty) list) set" 
  valid :: "(name\<times>ty) list \<Rightarrow> bool"
translations
  "valid \<Gamma>" \<rightleftharpoons> "\<Gamma> \<in> ctxts"  
inductive ctxts
intros
v1[intro]: "valid []"
v2[intro]: "\<lbrakk>valid \<Gamma>;a\<sharp>\<Gamma>\<rbrakk>\<Longrightarrow> valid ((a,\<sigma>)#\<Gamma>)"

lemma eqvt_valid:
  fixes   pi:: "name prm"
  assumes a: "valid \<Gamma>"
  shows   "valid (pi\<bullet>\<Gamma>)"
using a
apply(induct)
apply(auto simp add: pt_fresh_bij[OF pt_name_inst, OF at_name_inst])
done

(* typing judgements *)
consts
  typing :: "(((name\<times>ty) list)\<times>lam\<times>ty) set" 
syntax
  "_typing_judge" :: "(name\<times>ty) list\<Rightarrow>lam\<Rightarrow>ty\<Rightarrow>bool" (" _ \<turnstile> _ : _ " [80,80,80] 80) 
translations
  "\<Gamma> \<turnstile> t : \<tau>" \<rightleftharpoons> "(\<Gamma>,t,\<tau>) \<in> typing"  

inductive typing
intros
t1[intro]: "\<lbrakk>valid \<Gamma>; (a,\<tau>)\<in>set \<Gamma>\<rbrakk>\<Longrightarrow> \<Gamma> \<turnstile> Var a : \<tau>"
t2[intro]: "\<lbrakk>\<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma>; \<Gamma> \<turnstile> t2 : \<tau>\<rbrakk>\<Longrightarrow> \<Gamma> \<turnstile> App t1 t2 : \<sigma>"
t3[intro]: "\<lbrakk>a\<sharp>\<Gamma>;((a,\<tau>)#\<Gamma>) \<turnstile> t : \<sigma>\<rbrakk> \<Longrightarrow> \<Gamma> \<turnstile> Lam [a].t : \<tau>\<rightarrow>\<sigma>"

lemma eqvt_typing: 
  fixes  \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  and    pi:: "name prm"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  shows "(pi\<bullet>\<Gamma>) \<turnstile> (pi\<bullet>t) : \<tau>"
using a
proof (induct)
  case (t1 \<Gamma> \<tau> a)
  have "valid (pi\<bullet>\<Gamma>)" by (rule eqvt_valid)
  moreover
  have "(pi\<bullet>(a,\<tau>))\<in>((pi::name prm)\<bullet>set \<Gamma>)" by (rule pt_set_bij2[OF pt_name_inst, OF at_name_inst])
  ultimately show "(pi\<bullet>\<Gamma>) \<turnstile> ((pi::name prm)\<bullet>Var a) : \<tau>"
    using typing.intros by (force simp add: pt_list_set_pi[OF pt_name_inst, symmetric])
next 
  case (t3 \<Gamma> \<sigma> \<tau> a t)
  moreover have "(pi\<bullet>a)\<sharp>(pi\<bullet>\<Gamma>)" by (rule pt_fresh_bij1[OF pt_name_inst, OF at_name_inst])
  ultimately show "(pi\<bullet>\<Gamma>) \<turnstile> (pi\<bullet>Lam [a].t) :\<tau>\<rightarrow>\<sigma>" by force 
qed (auto)


lemma typing_induct_weak[THEN spec, case_names t1 t2 t3]:
  fixes  P :: "(name\<times>ty) list \<Rightarrow> lam \<Rightarrow> ty \<Rightarrow>'a\<Rightarrow>bool"
  and    \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  and a1:    "\<And>x \<Gamma> (a::name) \<tau>. valid \<Gamma> \<Longrightarrow> (a,\<tau>) \<in> set \<Gamma> \<Longrightarrow> P \<Gamma> (Var a) \<tau> x"
  and a2:    "\<And>x \<Gamma> \<tau> \<sigma> t1 t2. 
              \<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma> \<Longrightarrow> (\<forall>z. P \<Gamma> t1 (\<tau>\<rightarrow>\<sigma>) z) \<Longrightarrow> \<Gamma> \<turnstile> t2 : \<tau> \<Longrightarrow> (\<forall>z. P \<Gamma> t2 \<tau> z)
              \<Longrightarrow> P \<Gamma> (App t1 t2) \<sigma> x"
  and a3:    "\<And>x (a::name) \<Gamma> \<tau> \<sigma> t. 
              a\<sharp>\<Gamma> \<Longrightarrow> ((a,\<tau>) # \<Gamma>) \<turnstile> t : \<sigma> \<Longrightarrow> (\<forall>z. P ((a,\<tau>)#\<Gamma>) t \<sigma> z)
              \<Longrightarrow> P \<Gamma> (Lam [a].t) (\<tau>\<rightarrow>\<sigma>) x"
  shows "\<forall>x. P \<Gamma> t \<tau> x"
using a by (induct, simp_all add: a1 a2 a3)

lemma typing_induct_aux[rule_format]:
  fixes  P :: "(name\<times>ty) list \<Rightarrow> lam \<Rightarrow> ty \<Rightarrow>'a::fs_name\<Rightarrow>bool"
  and    \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  and a1:    "\<And>x \<Gamma> (a::name) \<tau>. valid \<Gamma> \<Longrightarrow> (a,\<tau>) \<in> set \<Gamma> \<Longrightarrow> P \<Gamma> (Var a) \<tau> x"
  and a2:    "\<And>x \<Gamma> \<tau> \<sigma> t1 t2. 
              \<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma> \<Longrightarrow> (\<And>z. P \<Gamma> t1 (\<tau>\<rightarrow>\<sigma>) z) \<Longrightarrow> \<Gamma> \<turnstile> t2 : \<tau> \<Longrightarrow> (\<And>z. P \<Gamma> t2 \<tau> z)
              \<Longrightarrow> P \<Gamma> (App t1 t2) \<sigma> x"
  and a3:    "\<And>x (a::name) \<Gamma> \<tau> \<sigma> t. 
              a\<sharp>x \<Longrightarrow> a\<sharp>\<Gamma> \<Longrightarrow> ((a,\<tau>) # \<Gamma>) \<turnstile> t : \<sigma> \<Longrightarrow> (\<forall>z. P ((a,\<tau>)#\<Gamma>) t \<sigma> z)
              \<Longrightarrow> P \<Gamma> (Lam [a].t) (\<tau>\<rightarrow>\<sigma>) x"
  shows "\<forall>(pi::name prm) (x::'a::fs_name). P (pi\<bullet>\<Gamma>) (pi\<bullet>t) \<tau> x"
using a
proof (induct)
  case (t1 \<Gamma> \<tau> a)
  have j1: "valid \<Gamma>" by fact
  have j2: "(a,\<tau>)\<in>set \<Gamma>" by fact
  show ?case
  proof (intro strip, simp)
    fix pi::"name prm" and x::"'a::fs_name"
    from j1 have j3: "valid (pi\<bullet>\<Gamma>)" by (rule eqvt_valid)
    from j2 have "pi\<bullet>(a,\<tau>)\<in>pi\<bullet>(set \<Gamma>)" by (simp only: pt_set_bij[OF pt_name_inst, OF at_name_inst])  
    hence j4: "(pi\<bullet>a,\<tau>)\<in>set (pi\<bullet>\<Gamma>)" by (simp add: pt_list_set_pi[OF pt_name_inst])
    show "P (pi\<bullet>\<Gamma>) (Var (pi\<bullet>a)) \<tau> x" using a1 j3 j4 by force
  qed
next
  case (t2 \<Gamma> \<sigma> \<tau> t1 t2)
  thus ?case using a2 by (simp, blast intro: eqvt_typing)
next
  case (t3 \<Gamma> \<sigma> \<tau> a t)
  have k1: "a\<sharp>\<Gamma>" by fact
  have k2: "((a,\<tau>)#\<Gamma>)\<turnstile>t:\<sigma>" by fact
  have k3: "\<forall>(pi::name prm) (x::'a::fs_name). P (pi \<bullet> ((a,\<tau>)#\<Gamma>)) (pi\<bullet>t) \<sigma> x" by fact
  show ?case
  proof (intro strip, simp)
    fix pi::"name prm" and x::"'a::fs_name"
    have f: "\<exists>c::name. c\<sharp>(pi\<bullet>a,pi\<bullet>t,pi\<bullet>\<Gamma>,x)"
      by (rule at_exists_fresh[OF at_name_inst], simp add: fs_name1)
    then obtain c::"name" 
      where f1: "c\<noteq>(pi\<bullet>a)" and f2: "c\<sharp>x" and f3: "c\<sharp>(pi\<bullet>t)" and f4: "c\<sharp>(pi\<bullet>\<Gamma>)"
      by (force simp add: fresh_prod at_fresh[OF at_name_inst])
    from k1 have k1a: "(pi\<bullet>a)\<sharp>(pi\<bullet>\<Gamma>)" 
      by (simp add: pt_fresh_left[OF pt_name_inst, OF at_name_inst] 
                    pt_rev_pi[OF pt_name_inst, OF at_name_inst])
    have l1: "(([(c,pi\<bullet>a)]@pi)\<bullet>\<Gamma>) = (pi\<bullet>\<Gamma>)" using f4 k1a 
      by (simp only: pt2[OF pt_name_inst], rule pt_fresh_fresh[OF pt_name_inst, OF at_name_inst])
    have "\<forall>x. P (([(c,pi\<bullet>a)]@pi)\<bullet>((a,\<tau>)#\<Gamma>)) (([(c,pi\<bullet>a)]@pi)\<bullet>t) \<sigma> x" using k3 by force
    hence l2: "\<forall>x. P ((c, \<tau>)#(pi\<bullet>\<Gamma>)) (([(c,pi\<bullet>a)]@pi)\<bullet>t) \<sigma> x" using f1 l1
      by (force simp add: pt2[OF pt_name_inst]  at_calc[OF at_name_inst] split: if_splits)
    have "(([(c,pi\<bullet>a)]@pi)\<bullet>((a,\<tau>)#\<Gamma>)) \<turnstile> (([(c,pi\<bullet>a)]@pi)\<bullet>t) : \<sigma>" using k2 by (rule eqvt_typing)
    hence l3: "((c, \<tau>)#(pi\<bullet>\<Gamma>)) \<turnstile> (([(c,pi\<bullet>a)]@pi)\<bullet>t) : \<sigma>" using l1 f1 
      by (force simp add: pt2[OF pt_name_inst]  at_calc[OF at_name_inst] split: if_splits)
    have l4: "P (pi\<bullet>\<Gamma>) (Lam [c].(([(c,pi\<bullet>a)]@pi)\<bullet>t)) (\<tau> \<rightarrow> \<sigma>) x" using f2 f4 l2 l3 a3 by auto
    have alpha: "(Lam [c].([(c,pi\<bullet>a)]\<bullet>(pi\<bullet>t))) = (Lam [(pi\<bullet>a)].(pi\<bullet>t))" using f1 f3
      by (simp add: lam.inject alpha)
    show "P (pi\<bullet>\<Gamma>) (Lam [(pi\<bullet>a)].(pi\<bullet>t)) (\<tau> \<rightarrow> \<sigma>) x" using l4 alpha 
      by (simp only: pt2[OF pt_name_inst])
  qed
qed

lemma typing_induct[case_names t1 t2 t3]:
  fixes  P :: "(name\<times>ty) list \<Rightarrow> lam \<Rightarrow> ty \<Rightarrow>'a::fs_name\<Rightarrow>bool"
  and    \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  and    x :: "'a::fs_name"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  and a1:    "\<And>x \<Gamma> (a::name) \<tau>. valid \<Gamma> \<Longrightarrow> (a,\<tau>) \<in> set \<Gamma> \<Longrightarrow> P \<Gamma> (Var a) \<tau> x"
  and a2:    "\<And>x \<Gamma> \<tau> \<sigma> t1 t2. 
              \<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma> \<Longrightarrow> (\<forall>z. P \<Gamma> t1 (\<tau>\<rightarrow>\<sigma>) z) \<Longrightarrow> \<Gamma> \<turnstile> t2 : \<tau> \<Longrightarrow> (\<forall>z. P \<Gamma> t2 \<tau> z)
              \<Longrightarrow> P \<Gamma> (App t1 t2) \<sigma> x"
  and a3:    "\<And>x (a::name) \<Gamma> \<tau> \<sigma> t. 
              a\<sharp>x \<Longrightarrow> a\<sharp>\<Gamma> \<Longrightarrow> ((a,\<tau>) # \<Gamma>) \<turnstile> t : \<sigma> \<Longrightarrow> (\<forall>z. P ((a,\<tau>)#\<Gamma>) t \<sigma> z)
              \<Longrightarrow> P \<Gamma> (Lam [a].t) (\<tau>\<rightarrow>\<sigma>) x"
  shows "P \<Gamma> t \<tau> x"
using a a1 a2 a3 typing_induct_aux[of "\<Gamma>" "t" "\<tau>" "P" "[]" "x", simplified] by force


(* Now it comes: The Weakening Lemma *)

constdefs
  "sub" :: "(name\<times>ty) list \<Rightarrow> (name\<times>ty) list \<Rightarrow> bool" (" _ \<lless> _ " [80,80] 80)
  "\<Gamma>1 \<lless> \<Gamma>2 \<equiv> \<forall>a \<sigma>. (a,\<sigma>)\<in>set \<Gamma>1 \<longrightarrow>  (a,\<sigma>)\<in>set \<Gamma>2"

lemma weakening_version1[rule_format]: 
  assumes a: "\<Gamma>1 \<turnstile> t : \<sigma>"
  shows "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> t:\<sigma>"
using a
apply(nominal_induct \<Gamma>1 t \<sigma> rule: typing_induct)
apply(auto simp add: sub_def)
done

lemma weakening_version2[rule_format]: 
  fixes \<Gamma>1::"(name\<times>ty) list"
  and   t ::"lam"
  and   \<tau> ::"ty"
  assumes a: "\<Gamma>1 \<turnstile> t:\<sigma>"
  shows "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> t:\<sigma>"
using a
proof (nominal_induct \<Gamma>1 t \<sigma> rule: typing_induct, auto)
  case (t1 \<Gamma>2 \<Gamma>1 a \<tau>)  (* variable case *)
  assume "\<Gamma>1 \<lless> \<Gamma>2" 
  and    "valid \<Gamma>2" 
  and    "(a,\<tau>)\<in> set \<Gamma>1" 
  thus  "\<Gamma>2 \<turnstile> Var a : \<tau>" by (force simp add: sub_def)
next
  case (t3 \<Gamma>2 a \<Gamma>1 \<tau> \<sigma> t) (* lambda case *)
  assume a1: "\<Gamma>1 \<lless> \<Gamma>2"
  and    a2: "valid \<Gamma>2"
  and    a3: "a\<sharp>\<Gamma>2"
  have i: "\<forall>\<Gamma>3. valid \<Gamma>3 \<longrightarrow> ((a,\<tau>)#\<Gamma>1) \<lless> \<Gamma>3 \<longrightarrow>  \<Gamma>3 \<turnstile> t:\<sigma>" by fact
  have "((a,\<tau>)#\<Gamma>1) \<lless> ((a,\<tau>)#\<Gamma>2)" using a1 by (simp add: sub_def)
  moreover
  have "valid ((a,\<tau>)#\<Gamma>2)" using a2 a3 v2 by force
  ultimately have "((a,\<tau>)#\<Gamma>2) \<turnstile> t:\<sigma>" using i by force
  with a3 show "\<Gamma>2 \<turnstile> (Lam [a].t) : \<tau> \<rightarrow> \<sigma>" by force
qed

lemma weakening_version3[rule_format]: 
  fixes \<Gamma>1::"(name\<times>ty) list"
  and   t ::"lam"
  and   \<tau> ::"ty"
  assumes a: "\<Gamma>1 \<turnstile> t:\<sigma>"
  shows "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> t:\<sigma>"
using a
proof (nominal_induct \<Gamma>1 t \<sigma> rule: typing_induct)
  case (t1 \<Gamma>2 \<Gamma>1 a \<tau>)  (* variable case *)
  thus "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> Var a : \<tau>" by (force simp add: sub_def)
next 
  case (t2 \<Gamma>2 \<Gamma>1 \<tau> \<sigma> t1 t2)  (* variable case *)
  thus "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> App t1 t2 : \<sigma>" by force
next
  case (t3 \<Gamma>2 a \<Gamma>1 \<tau> \<sigma> t) (* lambda case *)
  have a3: "a\<sharp>\<Gamma>2" 
  and  i: "\<forall>\<Gamma>3. valid \<Gamma>3 \<longrightarrow> ((a,\<tau>)#\<Gamma>1) \<lless> \<Gamma>3 \<longrightarrow>  \<Gamma>3 \<turnstile> t:\<sigma>" by fact
  show "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> (Lam [a].t) : \<tau> \<rightarrow> \<sigma>"
    proof (intro strip)
      assume a1: "\<Gamma>1 \<lless> \<Gamma>2"
      and    a2: "valid \<Gamma>2"
      have "((a,\<tau>)#\<Gamma>1) \<lless> ((a,\<tau>)#\<Gamma>2)" using a1 by (simp add: sub_def)
      moreover
      have "valid ((a,\<tau>)#\<Gamma>2)" using a2 a3 v2 by force
      ultimately have "((a,\<tau>)#\<Gamma>2) \<turnstile> t:\<sigma>" using i by force
      with a3 show "\<Gamma>2 \<turnstile> (Lam [a].t) : \<tau> \<rightarrow> \<sigma>" by force
    qed
qed

lemma weakening_version4[rule_format]: 
  assumes a: "\<Gamma>1 \<turnstile> t:\<sigma>"
  shows "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> t:\<sigma>"
using a
proof (nominal_induct \<Gamma>1 t \<sigma> rule: typing_induct)
  case (t3 \<Gamma>2 a \<Gamma>1 \<tau> \<sigma> t) (* lambda case *)
  have fc: "a\<sharp>\<Gamma>2" 
  and ih: "\<forall>\<Gamma>3. valid \<Gamma>3 \<longrightarrow> ((a,\<tau>)#\<Gamma>1) \<lless> \<Gamma>3  \<longrightarrow>  \<Gamma>3 \<turnstile> t:\<sigma>" by fact 
  show "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> (Lam [a].t) : \<tau> \<rightarrow> \<sigma>"
  proof (intro strip)
    assume a1: "\<Gamma>1 \<lless> \<Gamma>2"
    and    a2: "valid \<Gamma>2"
    have "((a,\<tau>)#\<Gamma>1) \<lless> ((a,\<tau>)#\<Gamma>2)" using a1 sub_def by simp 
    moreover
    have "valid ((a,\<tau>)#\<Gamma>2)" using a2 fc by force
    ultimately have "((a,\<tau>)#\<Gamma>2) \<turnstile> t:\<sigma>" using ih by force
    with fc show "\<Gamma>2 \<turnstile> (Lam [a].t) : \<tau> \<rightarrow> \<sigma>" by force
  qed
qed (auto simp add: sub_def) (* lam and var case *)


(* original induction principle is not strong *)
(* enough - so the simple proof fails         *)
lemma weakening_too_weak[rule_format]: 
  assumes a: "\<Gamma>1 \<turnstile> t:\<sigma>"
  shows "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> t:\<sigma>"
using a
proof (nominal_induct \<Gamma>1 t \<sigma> rule: typing_induct_weak, auto)
  case (t1 \<Gamma>2 \<Gamma>1 a \<tau>)  (* variable case *)
  assume "\<Gamma>1 \<lless> \<Gamma>2"
  and    "valid \<Gamma>2"
  and    "(a,\<tau>)\<in> set \<Gamma>1" 
  thus "\<Gamma>2 \<turnstile> Var a : \<tau>" by (force simp add: sub_def)
next
  case (t3 \<Gamma>2 a \<Gamma>1 \<tau> \<sigma> t) (* lambda case *)
  assume a1: "\<Gamma>1 \<lless> \<Gamma>2"
  and    a2: "valid \<Gamma>2"
  and    i: "\<forall>\<Gamma>3. valid \<Gamma>3 \<longrightarrow> ((a,\<tau>)#\<Gamma>1) \<lless> \<Gamma>3  \<longrightarrow>  \<Gamma>3 \<turnstile> t:\<sigma>" 
  have "((a,\<tau>)#\<Gamma>1) \<lless> ((a,\<tau>)#\<Gamma>2)" using a1 by (simp add: sub_def)
  moreover
  have "valid ((a,\<tau>)#\<Gamma>2)" using v2 (* fails *)



