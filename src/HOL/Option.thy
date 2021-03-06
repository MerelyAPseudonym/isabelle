(*  Title:      HOL/Option.thy
    Author:     Folklore
*)

section {* Datatype option *}

theory Option
imports Lifting Finite_Set
begin

datatype 'a option =
    None
  | Some (the: 'a)

datatype_compat option

lemma [case_names None Some, cases type: option]:
  -- {* for backward compatibility -- names of variables differ *}
  "(y = None \<Longrightarrow> P) \<Longrightarrow> (\<And>a. y = Some a \<Longrightarrow> P) \<Longrightarrow> P"
by (rule option.exhaust)

lemma [case_names None Some, induct type: option]:
  -- {* for backward compatibility -- names of variables differ *}
  "P None \<Longrightarrow> (\<And>option. P (Some option)) \<Longrightarrow> P option"
by (rule option.induct)

text {* Compatibility: *}

setup {* Sign.mandatory_path "option" *}

lemmas inducts = option.induct
lemmas cases = option.case

setup {* Sign.parent_path *}

lemma not_None_eq [iff]: "(x ~= None) = (EX y. x = Some y)"
  by (induct x) auto

lemma not_Some_eq [iff]: "(ALL y. x ~= Some y) = (x = None)"
  by (induct x) auto

text{*Although it may appear that both of these equalities are helpful
only when applied to assumptions, in practice it seems better to give
them the uniform iff attribute. *}

lemma inj_Some [simp]: "inj_on Some A"
by (rule inj_onI) simp

lemma case_optionE:
  assumes c: "(case x of None => P | Some y => Q y)"
  obtains
    (None) "x = None" and P
  | (Some) y where "x = Some y" and "Q y"
  using c by (cases x) simp_all

lemma split_option_all: "(\<forall>x. P x) \<longleftrightarrow> P None \<and> (\<forall>x. P (Some x))"
by (auto intro: option.induct)

lemma split_option_ex: "(\<exists>x. P x) \<longleftrightarrow> P None \<or> (\<exists>x. P (Some x))"
using split_option_all[of "\<lambda>x. \<not>P x"] by blast

lemma UNIV_option_conv: "UNIV = insert None (range Some)"
by(auto intro: classical)

subsubsection {* Operations *}

lemma ospec [dest]: "(ALL x:set_option A. P x) ==> A = Some x ==> P x"
  by simp

setup {* map_theory_claset (fn ctxt => ctxt addSD2 ("ospec", @{thm ospec})) *}

lemma elem_set [iff]: "(x : set_option xo) = (xo = Some x)"
  by (cases xo) auto

lemma set_empty_eq [simp]: "(set_option xo = {}) = (xo = None)"
  by (cases xo) auto

lemma map_option_case: "map_option f y = (case y of None => None | Some x => Some (f x))"
  by (auto split: option.split)

lemma map_option_is_None [iff]:
    "(map_option f opt = None) = (opt = None)"
  by (simp add: map_option_case split add: option.split)

lemma map_option_eq_Some [iff]:
    "(map_option f xo = Some y) = (EX z. xo = Some z & f z = y)"
  by (simp add: map_option_case split add: option.split)

lemma map_option_o_case_sum [simp]:
    "map_option f o case_sum g h = case_sum (map_option f o g) (map_option f o h)"
  by (rule o_case_sum)

lemma map_option_cong: "x = y \<Longrightarrow> (\<And>a. y = Some a \<Longrightarrow> f a = g a) \<Longrightarrow> map_option f x = map_option g y"
by (cases x) auto

functor map_option: map_option proof -
  fix f g
  show "map_option f \<circ> map_option g = map_option (f \<circ> g)"
  proof
    fix x
    show "(map_option f \<circ> map_option g) x= map_option (f \<circ> g) x"
      by (cases x) simp_all
  qed
next
  show "map_option id = id"
  proof
    fix x
    show "map_option id x = id x"
      by (cases x) simp_all
  qed
qed

lemma case_map_option [simp]:
  "case_option g h (map_option f x) = case_option g (h \<circ> f) x"
  by (cases x) simp_all

lemma rel_option_iff:
  "rel_option R x y = (case (x, y) of (None, None) \<Rightarrow> True
    | (Some x, Some y) \<Rightarrow> R x y
    | _ \<Rightarrow> False)"
by (auto split: prod.split option.split)

primrec bind :: "'a option \<Rightarrow> ('a \<Rightarrow> 'b option) \<Rightarrow> 'b option" where
bind_lzero: "bind None f = None" |
bind_lunit: "bind (Some x) f = f x"

lemma bind_runit[simp]: "bind x Some = x"
by (cases x) auto

lemma bind_assoc[simp]: "bind (bind x f) g = bind x (\<lambda>y. bind (f y) g)"
by (cases x) auto

lemma bind_rzero[simp]: "bind x (\<lambda>x. None) = None"
by (cases x) auto

lemma bind_cong: "x = y \<Longrightarrow> (\<And>a. y = Some a \<Longrightarrow> f a = g a) \<Longrightarrow> bind x f = bind y g"
by (cases x) auto

lemma bind_split: "P (bind m f) 
  \<longleftrightarrow> (m = None \<longrightarrow> P None) \<and> (\<forall>v. m=Some v \<longrightarrow> P (f v))"
    by (cases m) auto

lemma bind_split_asm: "P (bind m f) = (\<not>(
    m=None \<and> \<not>P None 
  \<or> (\<exists>x. m=Some x \<and> \<not>P (f x))))"
  by (cases m) auto

lemmas bind_splits = bind_split bind_split_asm

definition these :: "'a option set \<Rightarrow> 'a set"
where
  "these A = the ` {x \<in> A. x \<noteq> None}"

lemma these_empty [simp]:
  "these {} = {}"
  by (simp add: these_def)

lemma these_insert_None [simp]:
  "these (insert None A) = these A"
  by (auto simp add: these_def)

lemma these_insert_Some [simp]:
  "these (insert (Some x) A) = insert x (these A)"
proof -
  have "{y \<in> insert (Some x) A. y \<noteq> None} = insert (Some x) {y \<in> A. y \<noteq> None}"
    by auto
  then show ?thesis by (simp add: these_def)
qed

lemma in_these_eq:
  "x \<in> these A \<longleftrightarrow> Some x \<in> A"
proof
  assume "Some x \<in> A"
  then obtain B where "A = insert (Some x) B" by auto
  then show "x \<in> these A" by (auto simp add: these_def intro!: image_eqI)
next
  assume "x \<in> these A"
  then show "Some x \<in> A" by (auto simp add: these_def)
qed

lemma these_image_Some_eq [simp]:
  "these (Some ` A) = A"
  by (auto simp add: these_def intro!: image_eqI)

lemma Some_image_these_eq:
  "Some ` these A = {x\<in>A. x \<noteq> None}"
  by (auto simp add: these_def image_image intro!: image_eqI)

lemma these_empty_eq:
  "these B = {} \<longleftrightarrow> B = {} \<or> B = {None}"
  by (auto simp add: these_def)

lemma these_not_empty_eq:
  "these B \<noteq> {} \<longleftrightarrow> B \<noteq> {} \<and> B \<noteq> {None}"
  by (auto simp add: these_empty_eq)

hide_const (open) bind these
hide_fact (open) bind_cong


subsection {* Transfer rules for the Transfer package *}

context
begin
interpretation lifting_syntax .

lemma option_bind_transfer [transfer_rule]:
  "(rel_option A ===> (A ===> rel_option B) ===> rel_option B)
    Option.bind Option.bind"
  unfolding rel_fun_def split_option_all by simp

end


subsubsection {* Interaction with finite sets *}

lemma finite_option_UNIV [simp]:
  "finite (UNIV :: 'a option set) = finite (UNIV :: 'a set)"
  by (auto simp add: UNIV_option_conv elim: finite_imageD intro: inj_Some)

instance option :: (finite) finite
  by default (simp add: UNIV_option_conv)


subsubsection {* Code generator setup *}

definition is_none :: "'a option \<Rightarrow> bool" where
  [code_post]: "is_none x \<longleftrightarrow> x = None"

lemma is_none_code [code]:
  shows "is_none None \<longleftrightarrow> True"
    and "is_none (Some x) \<longleftrightarrow> False"
  unfolding is_none_def by simp_all

lemma [code_unfold]:
  "HOL.equal x None \<longleftrightarrow> is_none x"
  "HOL.equal None = is_none"
  by (auto simp add: equal is_none_def)

hide_const (open) is_none

code_printing
  type_constructor option \<rightharpoonup>
    (SML) "_ option"
    and (OCaml) "_ option"
    and (Haskell) "Maybe _"
    and (Scala) "!Option[(_)]"
| constant None \<rightharpoonup>
    (SML) "NONE"
    and (OCaml) "None"
    and (Haskell) "Nothing"
    and (Scala) "!None"
| constant Some \<rightharpoonup>
    (SML) "SOME"
    and (OCaml) "Some _"
    and (Haskell) "Just"
    and (Scala) "Some"
| class_instance option :: equal \<rightharpoonup>
    (Haskell) -
| constant "HOL.equal :: 'a option \<Rightarrow> 'a option \<Rightarrow> bool" \<rightharpoonup>
    (Haskell) infix 4 "=="

code_reserved SML
  option NONE SOME

code_reserved OCaml
  option None Some

code_reserved Scala
  Option None Some

end
