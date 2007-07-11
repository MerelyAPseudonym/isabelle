(******************************************************************************
date: april 2002
author: Frederic Blanqui
email: blanqui@lri.fr
webpage: http://www.lri.fr/~blanqui/

University of Cambridge, Computer Laboratory
William Gates Building, JJ Thomson Avenue
Cambridge CB3 0FD, United Kingdom
******************************************************************************)

header{*Other Protocol-Independent Results*}

theory Proto imports Guard_Public begin

subsection{*protocols*}

types rule = "event set * event"

abbreviation
  msg' :: "rule => msg" where
  "msg' R == msg (snd R)"

types proto = "rule set"

constdefs wdef :: "proto => bool"
"wdef p == ALL R k. R:p --> Number k:parts {msg' R}
--> Number k:parts (msg`(fst R))"

subsection{*substitutions*}

record subs =
  agent   :: "agent => agent"
  nonce :: "nat => nat"
  nb    :: "nat => msg"
  key   :: "key => key"

consts apm :: "subs => msg => msg"

primrec
"apm s (Agent A) = Agent (agent s A)"
"apm s (Nonce n) = Nonce (nonce s n)"
"apm s (Number n) = nb s n"
"apm s (Key K) = Key (key s K)"
"apm s (Hash X) = Hash (apm s X)"
"apm s (Crypt K X) = (
if (EX A. K = pubK A) then Crypt (pubK (agent s (agt K))) (apm s X)
else if (EX A. K = priK A) then Crypt (priK (agent s (agt K))) (apm s X)
else Crypt (key s K) (apm s X))"
"apm s {|X,Y|} = {|apm s X, apm s Y|}"

lemma apm_parts: "X:parts {Y} ==> apm s X:parts {apm s Y}"
apply (erule parts.induct, simp_all, blast)
apply (erule parts.Fst)
apply (erule parts.Snd)
by (erule parts.Body)+

lemma Nonce_apm [rule_format]: "Nonce n:parts {apm s X} ==>
(ALL k. Number k:parts {X} --> Nonce n ~:parts {nb s k}) -->
(EX k. Nonce k:parts {X} & nonce s k = n)"
by (induct X, simp_all, blast)

lemma wdef_Nonce: "[| Nonce n:parts {apm s X}; R:p; msg' R = X; wdef p;
Nonce n ~:parts (apm s `(msg `(fst R))) |] ==>
(EX k. Nonce k:parts {X} & nonce s k = n)"
apply (erule Nonce_apm, unfold wdef_def)
apply (drule_tac x=R in spec, drule_tac x=k in spec, clarsimp)
apply (drule_tac x=x in bspec, simp)
apply (drule_tac Y="msg x" and s=s in apm_parts, simp)
by (blast dest: parts_parts)

consts ap :: "subs => event => event"

primrec
"ap s (Says A B X) = Says (agent s A) (agent s B) (apm s X)"
"ap s (Gets A X) = Gets (agent s A) (apm s X)"
"ap s (Notes A X) = Notes (agent s A) (apm s X)"

abbreviation
  ap' :: "subs => rule => event" where
  "ap' s R == ap s (snd R)"

abbreviation
  apm' :: "subs => rule => msg" where
  "apm' s R == apm s (msg' R)"

abbreviation
  priK' :: "subs => agent => key" where
  "priK' s A == priK (agent s A)"

abbreviation
  pubK' :: "subs => agent => key" where
  "pubK' s A == pubK (agent s A)"

subsection{*nonces generated by a rule*}

constdefs newn :: "rule => nat set"
"newn R == {n. Nonce n:parts {msg (snd R)} & Nonce n ~:parts (msg`(fst R))}"

lemma newn_parts: "n:newn R ==> Nonce (nonce s n):parts {apm' s R}"
by (auto simp: newn_def dest: apm_parts)

subsection{*traces generated by a protocol*}

constdefs ok :: "event list => rule => subs => bool"
"ok evs R s == ((ALL x. x:fst R --> ap s x:set evs)
& (ALL n. n:newn R --> Nonce (nonce s n) ~:used evs))"

inductive_set
  tr :: "proto => event list set"
  for p :: proto
where

  Nil [intro]: "[]:tr p"

| Fake [intro]: "[| evsf:tr p; X:synth (analz (spies evsf)) |]
  ==> Says Spy B X # evsf:tr p"

| Proto [intro]: "[| evs:tr p; R:p; ok evs R s |] ==> ap' s R # evs:tr p"

subsection{*general properties*}

lemma one_step_tr [iff]: "one_step (tr p)"
apply (unfold one_step_def, clarify)
by (ind_cases "ev # evs:tr p" for ev evs, auto)

constdefs has_only_Says' :: "proto => bool"
"has_only_Says' p == ALL R. R:p --> is_Says (snd R)"

lemma has_only_Says'D: "[| R:p; has_only_Says' p |]
==> (EX A B X. snd R = Says A B X)"
by (unfold has_only_Says'_def is_Says_def, blast)

lemma has_only_Says_tr [simp]: "has_only_Says' p ==> has_only_Says (tr p)"
apply (unfold has_only_Says_def)
apply (rule allI, rule allI, rule impI)
apply (erule tr.induct)
apply (auto simp: has_only_Says'_def ok_def)
by (drule_tac x=a in spec, auto simp: is_Says_def)

lemma has_only_Says'_in_trD: "[| has_only_Says' p; list @ ev # evs1 \<in> tr p |]
==> (EX A B X. ev = Says A B X)"
by (drule has_only_Says_tr, auto)

lemma ok_not_used: "[| Nonce n ~:used evs; ok evs R s;
ALL x. x:fst R --> is_Says x |] ==> Nonce n ~:parts (apm s `(msg `(fst R)))"
apply (unfold ok_def, clarsimp)
apply (drule_tac x=x in spec, drule_tac x=x in spec)
by (auto simp: is_Says_def dest: Says_imp_spies not_used_not_spied parts_parts)

lemma ok_is_Says: "[| evs' @ ev # evs:tr p; ok evs R s; has_only_Says' p;
R:p; x:fst R |] ==> is_Says x"
apply (unfold ok_def is_Says_def, clarify)
apply (drule_tac x=x in spec, simp)
apply (subgoal_tac "one_step (tr p)")
apply (drule trunc, simp, drule one_step_Cons, simp)
apply (drule has_only_SaysD, simp+)
by (clarify, case_tac x, auto)

subsection{*types*}

types keyfun = "rule => subs => nat => event list => key set"

types secfun = "rule => nat => subs => key set => msg"

subsection{*introduction of a fresh guarded nonce*}

constdefs fresh :: "proto => rule => subs => nat => key set => event list
=> bool"
"fresh p R s n Ks evs == (EX evs1 evs2. evs = evs2 @ ap' s R # evs1
& Nonce n ~:used evs1 & R:p & ok evs1 R s & Nonce n:parts {apm' s R}
& apm' s R:guard n Ks)"

lemma freshD: "fresh p R s n Ks evs ==> (EX evs1 evs2.
evs = evs2 @ ap' s R # evs1 & Nonce n ~:used evs1 & R:p & ok evs1 R s
& Nonce n:parts {apm' s R} & apm' s R:guard n Ks)"
by (unfold fresh_def, blast)

lemma freshI [intro]: "[| Nonce n ~:used evs1; R:p; Nonce n:parts {apm' s R};
ok evs1 R s; apm' s R:guard n Ks |]
==> fresh p R s n Ks (list @ ap' s R # evs1)"
by (unfold fresh_def, blast)

lemma freshI': "[| Nonce n ~:used evs1; (l,r):p;
Nonce n:parts {apm s (msg r)}; ok evs1 (l,r) s; apm s (msg r):guard n Ks |]
==> fresh p (l,r) s n Ks (evs2 @ ap s r # evs1)"
by (drule freshI, simp+)

lemma fresh_used: "[| fresh p R' s' n Ks evs; has_only_Says' p |]
==> Nonce n:used evs"
apply (unfold fresh_def, clarify)
apply (drule has_only_Says'D)
by (auto intro: parts_used_app)

lemma fresh_newn: "[| evs' @ ap' s R # evs:tr p; wdef p; has_only_Says' p;
Nonce n ~:used evs; R:p; ok evs R s; Nonce n:parts {apm' s R} |]
==> EX k. k:newn R & nonce s k = n"
apply (drule wdef_Nonce, simp+)
apply (frule ok_not_used, simp+)
apply (clarify, erule ok_is_Says, simp+)
apply (clarify, rule_tac x=k in exI, simp add: newn_def)
apply (clarify, drule_tac Y="msg x" and s=s in apm_parts)
apply (drule ok_not_used, simp+)
by (clarify, erule ok_is_Says, simp+)

lemma fresh_rule: "[| evs' @ ev # evs:tr p; wdef p; Nonce n ~:used evs;
Nonce n:parts {msg ev} |] ==> EX R s. R:p & ap' s R = ev"
apply (drule trunc, simp, ind_cases "ev # evs:tr p", simp)
by (drule_tac x=X in in_sub, drule parts_sub, simp, simp, blast+)

lemma fresh_ruleD: "[| fresh p R' s' n Ks evs; keys R' s' n evs <= Ks; wdef p;
has_only_Says' p; evs:tr p; ALL R k s. nonce s k = n --> Nonce n:used evs -->
R:p --> k:newn R --> Nonce n:parts {apm' s R} --> apm' s R:guard n Ks -->
apm' s R:parts (spies evs) --> keys R s n evs <= Ks --> P |] ==> P"
apply (frule fresh_used, simp)
apply (unfold fresh_def, clarify)
apply (drule_tac x=R' in spec)
apply (drule fresh_newn, simp+, clarify)
apply (drule_tac x=k in spec)
apply (drule_tac x=s' in spec)
apply (subgoal_tac "apm' s' R':parts (spies (evs2 @ ap' s' R' # evs1))")
apply (case_tac R', drule has_only_Says'D, simp, clarsimp)
apply (case_tac R', drule has_only_Says'D, simp, clarsimp)
apply (rule_tac Y="apm s' X" in parts_parts, blast)
by (rule parts.Inj, rule Says_imp_spies, simp, blast)

subsection{*safe keys*}

constdefs safe :: "key set => msg set => bool"
"safe Ks G == ALL K. K:Ks --> Key K ~:analz G"

lemma safeD [dest]: "[| safe Ks G; K:Ks |] ==> Key K ~:analz G"
by (unfold safe_def, blast)

lemma safe_insert: "safe Ks (insert X G) ==> safe Ks G"
by (unfold safe_def, blast)

lemma Guard_safe: "[| Guard n Ks G; safe Ks G |] ==> Nonce n ~:analz G"
by (blast dest: Guard_invKey)

subsection{*guardedness preservation*}

constdefs preserv :: "proto => keyfun => nat => key set => bool"
"preserv p keys n Ks == (ALL evs R' s' R s. evs:tr p -->
Guard n Ks (spies evs) --> safe Ks (spies evs) --> fresh p R' s' n Ks evs -->
keys R' s' n evs <= Ks --> R:p --> ok evs R s --> apm' s R:guard n Ks)"

lemma preservD: "[| preserv p keys n Ks; evs:tr p; Guard n Ks (spies evs);
safe Ks (spies evs); fresh p R' s' n Ks evs; R:p; ok evs R s;
keys R' s' n evs <= Ks |] ==> apm' s R:guard n Ks"
by (unfold preserv_def, blast)

lemma preservD': "[| preserv p keys n Ks; evs:tr p; Guard n Ks (spies evs);
safe Ks (spies evs); fresh p R' s' n Ks evs; (l,Says A B X):p;
ok evs (l,Says A B X) s; keys R' s' n evs <= Ks |] ==> apm s X:guard n Ks"
by (drule preservD, simp+)

subsection{*monotonic keyfun*}

constdefs monoton :: "proto => keyfun => bool"
"monoton p keys == ALL R' s' n ev evs. ev # evs:tr p -->
keys R' s' n evs <= keys R' s' n (ev # evs)"

lemma monotonD [dest]: "[| keys R' s' n (ev # evs) <= Ks; monoton p keys;
ev # evs:tr p |] ==> keys R' s' n evs <= Ks"
by (unfold monoton_def, blast)

subsection{*guardedness theorem*}

lemma Guard_tr [rule_format]: "[| evs:tr p; has_only_Says' p;
preserv p keys n Ks; monoton p keys; Guard n Ks (initState Spy) |] ==>
safe Ks (spies evs) --> fresh p R' s' n Ks evs --> keys R' s' n evs <= Ks -->
Guard n Ks (spies evs)"
apply (erule tr.induct)
(* Nil *)
apply simp
(* Fake *)
apply (clarify, drule freshD, clarsimp)
apply (case_tac evs2)
(* evs2 = [] *)
apply (frule has_only_Says'D, simp)
apply (clarsimp, blast)
(* evs2 = aa # list *)
apply (clarsimp, rule conjI)
apply (blast dest: safe_insert)
(* X:guard n Ks *)
apply (rule in_synth_Guard, simp, rule Guard_analz)
apply (blast dest: safe_insert)
apply (drule safe_insert, simp add: safe_def)
(* Proto *)
apply (clarify, drule freshD, clarify)
apply (case_tac evs2)
(* evs2 = [] *)
apply (frule has_only_Says'D, simp)
apply (frule_tac R=R' in has_only_Says'D, simp)
apply (case_tac R', clarsimp, blast)
(* evs2 = ab # list *)
apply (frule has_only_Says'D, simp)
apply (clarsimp, rule conjI)
apply (drule Proto, simp+, blast dest: safe_insert)
(* apm s X:guard n Ks *)
apply (frule Proto, simp+)
apply (erule preservD', simp+)
apply (blast dest: safe_insert)
apply (blast dest: safe_insert)
by (blast, simp, simp, blast)

subsection{*useful properties for guardedness*}

lemma newn_neq_used: "[| Nonce n:used evs; ok evs R s; k:newn R |]
==> n ~= nonce s k"
by (auto simp: ok_def)

lemma ok_Guard: "[| ok evs R s; Guard n Ks (spies evs); x:fst R; is_Says x |]
==> apm s (msg x):parts (spies evs) & apm s (msg x):guard n Ks"
apply (unfold ok_def is_Says_def, clarify)
apply (drule_tac x="Says A B X" in spec, simp)
by (drule Says_imp_spies, auto intro: parts_parts)

lemma ok_parts_not_new: "[| Y:parts (spies evs); Nonce (nonce s n):parts {Y};
ok evs R s |] ==> n ~:newn R"
by (auto simp: ok_def dest: not_used_not_spied parts_parts)

subsection{*unicity*}

constdefs uniq :: "proto => secfun => bool"
"uniq p secret == ALL evs R R' n n' Ks s s'. R:p --> R':p -->
n:newn R --> n':newn R' --> nonce s n = nonce s' n' -->
Nonce (nonce s n):parts {apm' s R} --> Nonce (nonce s n):parts {apm' s' R'} -->
apm' s R:guard (nonce s n) Ks --> apm' s' R':guard (nonce s n) Ks -->
evs:tr p --> Nonce (nonce s n) ~:analz (spies evs) -->
secret R n s Ks:parts (spies evs) --> secret R' n' s' Ks:parts (spies evs) -->
secret R n s Ks = secret R' n' s' Ks"

lemma uniqD: "[| uniq p secret; evs: tr p; R:p; R':p; n:newn R; n':newn R';
nonce s n = nonce s' n'; Nonce (nonce s n) ~:analz (spies evs);
Nonce (nonce s n):parts {apm' s R}; Nonce (nonce s n):parts {apm' s' R'};
secret R n s Ks:parts (spies evs); secret R' n' s' Ks:parts (spies evs);
apm' s R:guard (nonce s n) Ks; apm' s' R':guard (nonce s n) Ks |] ==>
secret R n s Ks = secret R' n' s' Ks"
by (unfold uniq_def, blast)

constdefs ord :: "proto => (rule => rule => bool) => bool"
"ord p inff == ALL R R'. R:p --> R':p --> ~ inff R R' --> inff R' R"

lemma ordD: "[| ord p inff; ~ inff R R'; R:p; R':p |] ==> inff R' R"
by (unfold ord_def, blast)

constdefs uniq' :: "proto => (rule => rule => bool) => secfun => bool"
"uniq' p inff secret == ALL evs R R' n n' Ks s s'. R:p --> R':p -->
inff R R' --> n:newn R --> n':newn R' --> nonce s n = nonce s' n' -->
Nonce (nonce s n):parts {apm' s R} --> Nonce (nonce s n):parts {apm' s' R'} -->
apm' s R:guard (nonce s n) Ks --> apm' s' R':guard (nonce s n) Ks -->
evs:tr p --> Nonce (nonce s n) ~:analz (spies evs) -->
secret R n s Ks:parts (spies evs) --> secret R' n' s' Ks:parts (spies evs) -->
secret R n s Ks = secret R' n' s' Ks"

lemma uniq'D: "[| uniq' p inff secret; evs: tr p; inff R R'; R:p; R':p; n:newn R;
n':newn R'; nonce s n = nonce s' n'; Nonce (nonce s n) ~:analz (spies evs);
Nonce (nonce s n):parts {apm' s R}; Nonce (nonce s n):parts {apm' s' R'};
secret R n s Ks:parts (spies evs); secret R' n' s' Ks:parts (spies evs);
apm' s R:guard (nonce s n) Ks; apm' s' R':guard (nonce s n) Ks |] ==>
secret R n s Ks = secret R' n' s' Ks"
by (unfold uniq'_def, blast)

lemma uniq'_imp_uniq: "[| uniq' p inff secret; ord p inff |] ==> uniq p secret"
apply (unfold uniq_def)
apply (rule allI)+
apply (case_tac "inff R R'")
apply (blast dest: uniq'D)
by (auto dest: ordD uniq'D intro: sym)

subsection{*Needham-Schroeder-Lowe*}

constdefs
a :: agent "a == Friend 0"
b :: agent "b == Friend 1"
a' :: agent "a' == Friend 2"
b' :: agent "b' == Friend 3"
Na :: nat "Na == 0"
Nb :: nat "Nb == 1"

abbreviation
  ns1 :: rule where
  "ns1 == ({}, Says a b (Crypt (pubK b) {|Nonce Na, Agent a|}))"

abbreviation
  ns2 :: rule where
  "ns2 == ({Says a' b (Crypt (pubK b) {|Nonce Na, Agent a|})},
    Says b a (Crypt (pubK a) {|Nonce Na, Nonce Nb, Agent b|}))"

abbreviation
  ns3 :: rule where
  "ns3 == ({Says a b (Crypt (pubK b) {|Nonce Na, Agent a|}),
    Says b' a (Crypt (pubK a) {|Nonce Na, Nonce Nb, Agent b|})},
    Says a b (Crypt (pubK b) (Nonce Nb)))"

inductive_set ns :: proto where
  [iff]: "ns1:ns"
| [iff]: "ns2:ns"
| [iff]: "ns3:ns"

abbreviation (input)
  ns3a :: event where
  "ns3a == Says a b (Crypt (pubK b) {|Nonce Na, Agent a|})"

abbreviation (input)
  ns3b :: event where
  "ns3b == Says b' a (Crypt (pubK a) {|Nonce Na, Nonce Nb, Agent b|})"

constdefs keys :: "keyfun"
"keys R' s' n evs == {priK' s' a, priK' s' b}"

lemma "monoton ns keys"
by (simp add: keys_def monoton_def)

constdefs secret :: "secfun"
"secret R n s Ks ==
(if R=ns1 then apm s (Crypt (pubK b) {|Nonce Na, Agent a|})
else if R=ns2 then apm s (Crypt (pubK a) {|Nonce Na, Nonce Nb, Agent b|})
else Number 0)"

constdefs inf :: "rule => rule => bool"
"inf R R' == (R=ns1 | (R=ns2 & R'~=ns1) | (R=ns3 & R'=ns3))"

lemma inf_is_ord [iff]: "ord ns inf"
apply (unfold ord_def inf_def)
apply (rule allI)+
apply (rule impI)
apply (simp add: split_paired_all)
by (rule impI, erule ns.cases, simp_all)+

subsection{*general properties*}

lemma ns_has_only_Says' [iff]: "has_only_Says' ns"
apply (unfold has_only_Says'_def)
apply (rule allI, rule impI)
apply (simp add: split_paired_all)
by (erule ns.cases, auto)

lemma newn_ns1 [iff]: "newn ns1 = {Na}"
by (simp add: newn_def)

lemma newn_ns2 [iff]: "newn ns2 = {Nb}"
by (auto simp: newn_def Na_def Nb_def)

lemma newn_ns3 [iff]: "newn ns3 = {}"
by (auto simp: newn_def)

lemma ns_wdef [iff]: "wdef ns"
by (auto simp: wdef_def elim: ns.cases)

subsection{*guardedness for NSL*}

lemma "uniq ns secret ==> preserv ns keys n Ks"
apply (unfold preserv_def)
apply (rule allI)+
apply (rule impI, rule impI, rule impI, rule impI, rule impI)
apply (erule fresh_ruleD, simp, simp, simp, simp)
apply (rule allI)+
apply (rule impI, rule impI, rule impI)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* fresh with NS1 *)
apply (rule impI, rule impI, rule impI, rule impI, rule impI, rule impI)
apply (erule ns.cases)
(* NS1 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (rule No_Nonce, simp)
(* NS2 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (case_tac "nonce sa Na = nonce s Na")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s b" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns1 and R'=ns1 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def keys_def, blast)
apply (rule No_Nonce, simp)
(* NS3 *)
apply clarsimp
apply (case_tac "nonce sa Na = nonce s Nb")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule_tac x=ns3b in ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s a" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns1 and R'=ns2 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def, rule No_Nonce, simp)
(* fresh with NS2 *)
apply (rule impI, rule impI, rule impI, rule impI, rule impI, rule impI)
apply (erule ns.cases)
(* NS1 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (rule No_Nonce, simp)
(* NS2 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (case_tac "nonce sa Nb = nonce s Na")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s b" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns2 and R'=ns1 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def, rule No_Nonce, simp)
(* NS3 *)
apply clarsimp
apply (case_tac "nonce sa Nb = nonce s Nb")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule_tac x=ns3b in ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s a" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns2 and R'=ns2 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def keys_def, blast)
apply (rule No_Nonce, simp)
(* fresh with NS3 *)
by simp

subsection{*unicity for NSL*}

lemma "uniq' ns inf secret"
apply (unfold uniq'_def)
apply (rule allI)+
apply (simp add: split_paired_all)
apply (rule impI, erule ns.cases)
(* R = ns1 *)
apply (rule impI, erule ns.cases)
(* R' = ns1 *)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, erule tr.induct)
(* Nil *)
apply (simp add: secret_def)
(* Fake *)
apply (clarify, simp add: secret_def)
apply (drule notin_analz_insert)
apply (drule Crypt_insert_synth, simp, simp, simp)
apply (drule Crypt_insert_synth, simp, simp, simp, simp)
(* Proto *)
apply (erule_tac P="ok evsa R sa" in rev_mp)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* ns1 *)
apply (clarify, simp add: secret_def)
apply (erule disjE, erule disjE, clarsimp)
apply (drule ok_parts_not_new, simp, simp, simp)
apply (clarify, drule ok_parts_not_new, simp, simp, simp)
(* ns2 *)
apply (simp add: secret_def)
(* ns3 *)
apply (simp add: secret_def)
(* R' = ns2 *)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, erule tr.induct)
(* Nil *)
apply (simp add: secret_def)
(* Fake *)
apply (clarify, simp add: secret_def)
apply (drule notin_analz_insert)
apply (drule Crypt_insert_synth, simp, simp, simp)
apply (drule_tac n="nonce s' Nb" in Crypt_insert_synth, simp, simp, simp, simp)
(* Proto *)
apply (erule_tac P="ok evsa R sa" in rev_mp)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* ns1 *)
apply (clarify, simp add: secret_def)
apply (drule_tac s=sa and n=Na in ok_parts_not_new, simp, simp, simp)
(* ns2 *)
apply (clarify, simp add: secret_def)
apply (drule_tac s=sa and n=Nb in ok_parts_not_new, simp, simp, simp)
(* ns3 *)
apply (simp add: secret_def)
(* R' = ns3 *)
apply simp
(* R = ns2 *)
apply (rule impI, erule ns.cases)
(* R' = ns1 *)
apply (simp only: inf_def, blast)
(* R' = ns2 *)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, erule tr.induct)
(* Nil *)
apply (simp add: secret_def)
(* Fake *)
apply (clarify, simp add: secret_def)
apply (drule notin_analz_insert)
apply (drule_tac n="nonce s' Nb" in Crypt_insert_synth, simp, simp, simp)
apply (drule_tac n="nonce s' Nb" in Crypt_insert_synth, simp, simp, simp, simp)
(* Proto *)
apply (erule_tac P="ok evsa R sa" in rev_mp)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* ns1 *)
apply (simp add: secret_def)
(* ns2 *)
apply (clarify, simp add: secret_def)
apply (erule disjE, erule disjE, clarsimp, clarsimp)
apply (drule_tac s=sa and n=Nb in ok_parts_not_new, simp, simp, simp)
apply (erule disjE, clarsimp)
apply (drule_tac s=sa and n=Nb in ok_parts_not_new, simp, simp, simp)
by (simp_all add: secret_def)

end
