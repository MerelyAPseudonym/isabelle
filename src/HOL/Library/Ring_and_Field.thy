(*  Title:      HOL/Library/Ring_and_Field.thy
    ID:         $Id$
    Author:     Gertrud Bauer and Markus Wenzel, TU Muenchen
*)

header {*
  \title{Ring and field structures}
  \author{Gertrud Bauer and Markus Wenzel}
*}

theory Ring_and_Field = Main: 

subsection {* Abstract algebraic structures *}

axclass ring < zero, plus, minus, times, number
  add_assoc: "(a + b) + c = a + (b + c)"
  add_commute: "a + b = b + a"
  left_zero [simp]: "0 + a = a"
  left_minus [simp]: "- a + a = 0"
  diff_minus [simp]: "a - b = a + (-b)"
  zero_number: "0 = #0"

  mult_assoc: "(a * b) * c = a * (b * c)"
  mult_commute: "a * b = b * a"
  left_one [simp]: "#1 * a = a"

  left_distrib: "(a + b) * c = a * c + b * c"

axclass ordered_ring < ring, linorder
  add_left_mono: "a \<le> b ==> c + a \<le> c + b"
  mult_strict_left_mono: "a < b ==> 0 < c ==> c * a < c * b"
  abs_if: "\<bar>a\<bar> = (if a < 0 then -a else a)"

axclass field < ring, inverse
  left_inverse [simp]: "a \<noteq> 0 ==> inverse a * a = #1"
  divides_inverse [simp]: "b \<noteq> 0 ==> a / b = a * inverse b" (* FIXME unconditional ?? *)

axclass ordered_field < ordered_ring, field



subsection {* Derived rules *}

subsubsection {* Derived rules for addition *}

lemma right_zero [simp]: "a + 0 = (a::'a::ring)" 
proof -
  have "a + 0 = 0 + a" by (simp only: add_commute)
  also have "\<dots> = a" by simp
  finally show ?thesis .
qed

lemma add_left_commute: "a + (b + c) = b + (a + (c::'a::ring))"
proof -
  have "a + (b + c) = (a + b) + c" by (simp only: add_assoc)
  also have "\<dots> = (b + a) + c" by (simp only: add_commute)
  finally show ?thesis by (simp only: add_assoc) 
qed

theorems ring_add_ac = add_assoc add_commute add_left_commute

lemma right_minus [simp]: "a + -(a::'a::ring) = 0" 
proof -
  have "a + -a = -a + a" by (simp add: ring_add_ac)
  also have "\<dots> = 0" by simp
  finally show ?thesis .
qed

lemma right_minus_eq [simp]: "(a - b = 0) = (a = (b::'a::ring))"
proof 
  have "a = a - b + b" by (simp add: ring_add_ac)
  also assume "a - b = 0"
  finally show "a = b" by simp
qed simp

lemma diff_self [simp]: "a - (a::'a::ring) = 0"
  by simp



subsubsection {* Derived rules for multiplication *}

lemma right_one [simp]: "a = a * (#1\<Colon>'a::field)"
proof -
  have "a = #1 * a" by simp
  also have "\<dots> = a * #1" by (simp add: mult_commute)
  finally show ?thesis .
qed

lemma mult_left_commute: "a * (b * c) = b * (a * (c::'a::ring))"
proof -
  have "a * (b * c) = (a * b) * c" by (simp only: mult_assoc)
  also have "\<dots> = (b * a) * c" by (simp only: mult_commute)
  finally show ?thesis by (simp only: mult_assoc)
qed

theorems ring_mult_ac = mult_assoc mult_commute mult_left_commute

lemma right_inverse [simp]: "a \<noteq> 0 \<Longrightarrow>  a * inverse (a::'a::field) = #1" 
proof -
  have "a * inverse a = inverse a * a" by (simp add: ring_mult_ac)
  also assume "a \<noteq> 0"
  hence "inverse a * a = #1" by simp
  finally show ?thesis .
qed

lemma right_inverse_eq [simp]: "b \<noteq> 0 \<Longrightarrow> (a / b = #1) = (a = (b::'a::field))"
proof 
  assume "b \<noteq> 0"
  hence "a = (a / b) * b" by (simp add: ring_mult_ac)
  also assume "a / b = #1"
  finally show "a = b" by simp
qed simp

lemma divide_self [simp]: "a \<noteq> 0 \<Longrightarrow> a / (a::'a::field) = #1"
  by simp



subsubsection {* Distribution rules *}

lemma right_distrib: "a * (b + c) = a * b + a * (c::'a::ring)"
proof -
  have "a * (b + c) = (b + c) * a" by (simp add: ring_mult_ac)
  also have "\<dots> = b * a + c * a" by (simp only: left_distrib)
  also have "\<dots> = a * b + a * c" by (simp add: ring_mult_ac)
  finally show "?thesis" .
qed

theorems ring_distrib = right_distrib left_distrib



subsection {* Example: The ordered ring of integers *}

instance int :: ordered_ring
proof
  fix i j k :: int
  show "(i + j) + k = i + (j + k)" by simp
  show "i + j = j + i" by simp
  show "0 + i = i" by simp
  show "- i + i = 0" by simp
  show "i - j = i + (-j)" by simp
  show "(i * j) * k = i * (j * k)" by simp
  show "i * j = j * i" by simp
  show "#1 * i = i" by simp
  show "0 = (#0::int)" by simp
  show "(i + j) * k = i * k + j * k" by (simp add: int_distrib)
  show "i \<le> j ==> k + i \<le> k + j" by simp
  show "i < j ==> 0 < k ==> k * i < k * j" by (simp add: zmult_zless_mono2)
  show "\<bar>i\<bar> = (if i < 0 then -i else i)" by (simp only: zabs_def)
qed

end
