(* 
  ID:     $Id$
  Author: Jeremy Dawson and Gerwin Klein, NICTA
  
  Basic definition of word type and basic theorems following from 
  the definition of the word type 
*) 

header {* Definition of Word Type *}

theory WordDefinition
imports Numeral_Type BinOperations TdThs begin

typedef (open word) 'a word
  = "{(0::int) ..< 2^CARD('a)}" by auto

instance word :: (type) number ..
instance word :: (type) size ..
instance word :: (type) inverse ..
instance word :: (type) bit ..

subsection {* Basic arithmetic *}

definition
  Abs_word' :: "int \<Rightarrow> 'a word"
  where "Abs_word' x = Abs_word (x mod 2^CARD('a))"

lemma Rep_word_mod: "Rep_word (x::'a word) mod 2^CARD('a) = Rep_word x"
  by (simp only: mod_pos_pos_trivial Rep_word [simplified])

lemma Rep_word_inverse': "Abs_word' (Rep_word x) = x"
  unfolding Abs_word'_def Rep_word_mod
  by (rule Rep_word_inverse)

lemma Abs_word'_inverse: "Rep_word (Abs_word' z::'a word) = z mod 2^CARD('a)"
  unfolding Abs_word'_def
  by (simp add: Abs_word_inverse)

lemmas Rep_word_simps =
  Rep_word_inject [symmetric]
  Rep_word_mod
  Rep_word_inverse'
  Abs_word'_inverse

instance word :: (type) "{zero,one,plus,minus,times,power}"
  word_zero_def: "0 \<equiv> Abs_word' 0"
  word_one_def: "1 \<equiv> Abs_word' 1"
  word_add_def: "x + y \<equiv> Abs_word' (Rep_word x + Rep_word y)"
  word_mult_def: "x * y \<equiv> Abs_word' (Rep_word x * Rep_word y)"
  word_diff_def: "x - y \<equiv> Abs_word' (Rep_word x - Rep_word y)"
  word_minus_def: "- x \<equiv> Abs_word' (- Rep_word x)"
  word_power_def: "x ^ n \<equiv> Abs_word' (Rep_word x ^ n)"
  ..

lemmas word_arith_defs =
  word_zero_def
  word_one_def
  word_add_def
  word_mult_def
  word_diff_def
  word_minus_def
  word_power_def

instance word :: (type) "{comm_ring,comm_monoid_mult,recpower}"
  apply (intro_classes, unfold word_arith_defs)
  apply (simp_all add: Rep_word_simps zmod_simps ring_simps
                       mod_pos_pos_trivial)
  done

instance word :: (finite) comm_ring_1
  apply (intro_classes, unfold word_arith_defs)
  apply (simp_all add: Rep_word_simps zmod_simps ring_simps
                       mod_pos_pos_trivial one_less_power)
  done

lemma word_of_nat: "of_nat n = Abs_word' (int n)"
  apply (induct n)
  apply (simp add: word_zero_def)
  apply (simp add: Rep_word_simps word_arith_defs zmod_simps)
  done

lemma word_of_int: "of_int z = Abs_word' z"
  apply (cases z rule: int_diff_cases)
  apply (simp add: Rep_word_simps word_diff_def word_of_nat zmod_simps)
  done

subsection "Type conversions and casting"

constdefs
  -- {* representation of words using unsigned or signed bins, 
        only difference in these is the type class *}
  word_of_int :: "int => 'a word"
  "word_of_int w == Abs_word (bintrunc CARD('a) w)" 

  -- {* uint and sint cast a word to an integer,
        uint treats the word as unsigned,
        sint treats the most-significant-bit as a sign bit *}
  uint :: "'a word => int"
  "uint w == Rep_word w"
  sint :: "'a :: finite word => int"
  sint_uint: "sint w == sbintrunc (CARD('a) - 1) (uint w)"
  unat :: "'a word => nat"
  "unat w == nat (uint w)"

  -- "the sets of integers representing the words"
  uints :: "nat => int set"
  "uints n == range (bintrunc n)"
  sints :: "nat => int set"
  "sints n == range (sbintrunc (n - 1))"
  unats :: "nat => nat set"
  "unats n == {i. i < 2 ^ n}"
  norm_sint :: "nat => int => int"
  "norm_sint n w == (w + 2 ^ (n - 1)) mod 2 ^ n - 2 ^ (n - 1)"

defs (overloaded)
  word_size: "size (w :: 'a word) == CARD('a)"
  word_number_of_def: "number_of w == word_of_int w"

constdefs
  word_int_case :: "(int => 'b) => ('a word) => 'b"
  "word_int_case f w == f (uint w)"

syntax
  of_int :: "int => 'a"
translations
  "case x of of_int y => b" == "word_int_case (%y. b) x"


subsection  "Arithmetic operations"

lemma Abs_word'_eq: "Abs_word' = word_of_int"
  unfolding expand_fun_eq Abs_word'_def word_of_int_def
  by (simp add: bintrunc_mod2p)

lemma word_1_wi: "(1 :: ('a) word) == word_of_int 1"
  by (simp only: word_arith_defs Abs_word'_eq)

lemma word_0_wi: "(0 :: ('a) word) == word_of_int 0"
  by (simp only: word_arith_defs Abs_word'_eq)

constdefs
  word_succ :: "'a word => 'a word"
  "word_succ a == word_of_int (Numeral.succ (uint a))"

  word_pred :: "'a word => 'a word"
  "word_pred a == word_of_int (Numeral.pred (uint a))"

consts
  word_power :: "'a word => nat => 'a word"
primrec
  "word_power a 0 = 1"
  "word_power a (Suc n) = a * word_power a n"

lemma
  word_pow: "power == word_power"
  apply (rule eq_reflection, rule ext, rule ext)
  apply (rename_tac n, induct_tac n, simp_all add: power_Suc)
  done

lemma
  word_add_def: "a + b == word_of_int (uint a + uint b)"
and
  word_sub_wi: "a - b == word_of_int (uint a - uint b)"
and
  word_minus_def: "- a == word_of_int (- uint a)"
and
  word_mult_def: "a * b == word_of_int (uint a * uint b)"
  by (simp_all only: word_arith_defs Abs_word'_eq uint_def)

subsection "Bit-wise operations"

defs (overloaded)
  word_and_def: 
  "(a::'a word) AND b == word_of_int (uint a AND uint b)"

  word_or_def:  
  "(a::'a word) OR b == word_of_int (uint a OR uint b)"

  word_xor_def: 
  "(a::'a word) XOR b == word_of_int (uint a XOR uint b)"

  word_not_def: 
  "NOT (a::'a word) == word_of_int (NOT (uint a))"

  word_test_bit_def: 
  "test_bit (a::'a word) == bin_nth (uint a)"

  word_set_bit_def: 
  "set_bit (a::'a word) n x == 
   word_of_int (bin_sc n (If x bit.B1 bit.B0) (uint a))"

  word_lsb_def: 
  "lsb (a::'a word) == bin_last (uint a) = bit.B1"

  word_msb_def: 
  "msb (a::'a::finite word) == bin_sign (sint a) = Numeral.Min"


constdefs
  setBit :: "'a word => nat => 'a word" 
  "setBit w n == set_bit w n True"

  clearBit :: "'a word => nat => 'a word" 
  "clearBit w n == set_bit w n False"


constdefs
  -- "Largest representable machine integer."
  max_word :: "'a::finite word"
  "max_word \<equiv> word_of_int (2^CARD('a) - 1)"

consts 
  of_bool :: "bool \<Rightarrow> 'a::finite word"
primrec
  "of_bool False = 0"
  "of_bool True = 1"



lemmas word_size_gt_0 [iff] = 
  xtr1 [OF word_size [THEN meta_eq_to_obj_eq] zero_less_card_finite, standard]
lemmas lens_gt_0 = word_size_gt_0 zero_less_card_finite
lemmas lens_not_0 [iff] = lens_gt_0 [THEN gr_implies_not0, standard]

lemma uints_num: "uints n = {i. 0 \<le> i \<and> i < 2 ^ n}"
  by (simp add: uints_def range_bintrunc)

lemma sints_num: "sints n = {i. - (2 ^ (n - 1)) \<le> i \<and> i < 2 ^ (n - 1)}"
  by (simp add: sints_def range_sbintrunc)

lemmas atLeastLessThan_alt = atLeastLessThan_def [unfolded 
  atLeast_def lessThan_def Collect_conj_eq [symmetric]]
  
lemma mod_in_reps: "m > 0 ==> y mod m : {0::int ..< m}"
  unfolding atLeastLessThan_alt by auto

lemma 
  Rep_word_0:"0 <= Rep_word x" and 
  Rep_word_lt: "Rep_word (x::'a word) < 2 ^ CARD('a)"
  by (auto simp: Rep_word [simplified])

lemma Rep_word_mod_same:
  "Rep_word x mod 2 ^ CARD('a) = Rep_word (x::'a word)"
  by (simp add: int_mod_eq Rep_word_lt Rep_word_0)

lemma td_ext_uint: 
  "td_ext (uint :: 'a word => int) word_of_int (uints CARD('a)) 
    (%w::int. w mod 2 ^ CARD('a))"
  apply (unfold td_ext_def')
  apply (simp add: uints_num uint_def word_of_int_def bintrunc_mod2p)
  apply (simp add: Rep_word_mod_same Rep_word_0 Rep_word_lt
                   word.Rep_word_inverse word.Abs_word_inverse int_mod_lem)
  done

lemmas int_word_uint = td_ext_uint [THEN td_ext.eq_norm, standard]

interpretation word_uint: 
  td_ext ["uint::'a word \<Rightarrow> int" 
          word_of_int 
          "uints CARD('a)"
          "\<lambda>w. w mod 2 ^ CARD('a)"]
  by (rule td_ext_uint)
  
lemmas td_uint = word_uint.td_thm

lemmas td_ext_ubin = td_ext_uint 
  [simplified zero_less_card_finite no_bintr_alt1 [symmetric]]

interpretation word_ubin:
  td_ext ["uint::'a word \<Rightarrow> int" 
          word_of_int 
          "uints CARD('a)"
          "bintrunc CARD('a)"]
  by (rule td_ext_ubin)

lemma sint_sbintrunc': 
  "sint (word_of_int bin :: 'a word) = 
    (sbintrunc (CARD('a :: finite) - 1) bin)"
  unfolding sint_uint 
  by (auto simp: word_ubin.eq_norm sbintrunc_bintrunc_lt)

lemma uint_sint: 
  "uint w = bintrunc CARD('a) (sint (w :: 'a :: finite word))"
  unfolding sint_uint by (auto simp: bintrunc_sbintrunc_le)
  

lemma bintr_uint': 
  "n >= size w ==> bintrunc n (uint w) = uint w"
  apply (unfold word_size)
  apply (subst word_ubin.norm_Rep [symmetric]) 
  apply (simp only: bintrunc_bintrunc_min word_size min_def)
  apply simp
  done

lemma wi_bintr': 
  "wb = word_of_int bin ==> n >= size wb ==> 
    word_of_int (bintrunc n bin) = wb"
  unfolding word_size
  by (clarsimp simp add : word_ubin.norm_eq_iff [symmetric] min_def)

lemmas bintr_uint = bintr_uint' [unfolded word_size]
lemmas wi_bintr = wi_bintr' [unfolded word_size]

lemma td_ext_sbin: 
  "td_ext (sint :: 'a word => int) word_of_int (sints CARD('a::finite)) 
    (sbintrunc (CARD('a) - 1))"
  apply (unfold td_ext_def' sint_uint)
  apply (simp add : word_ubin.eq_norm)
  apply (cases "CARD('a)")
   apply (auto simp add : sints_def)
  apply (rule sym [THEN trans])
  apply (rule word_ubin.Abs_norm)
  apply (simp only: bintrunc_sbintrunc)
  apply (drule sym)
  apply simp
  done

lemmas td_ext_sint = td_ext_sbin 
  [simplified zero_less_card_finite no_sbintr_alt2 Suc_pred' [symmetric]]

(* We do sint before sbin, before sint is the user version
   and interpretations do not produce thm duplicates. I.e. 
   we get the name word_sint.Rep_eqD, but not word_sbin.Req_eqD,
   because the latter is the same thm as the former *)
interpretation word_sint:
  td_ext ["sint ::'a::finite word => int" 
          word_of_int 
          "sints CARD('a::finite)"
          "%w. (w + 2^(CARD('a::finite) - 1)) mod 2^CARD('a::finite) -
               2 ^ (CARD('a::finite) - 1)"]
  by (rule td_ext_sint)

interpretation word_sbin:
  td_ext ["sint ::'a::finite word => int" 
          word_of_int 
          "sints CARD('a::finite)"
          "sbintrunc (CARD('a::finite) - 1)"]
  by (rule td_ext_sbin)

lemmas int_word_sint = td_ext_sint [THEN td_ext.eq_norm, standard]

lemmas td_sint = word_sint.td

lemma word_number_of_alt: "number_of b == word_of_int (number_of b)"
  unfolding word_number_of_def by (simp add: number_of_eq)

lemma word_no_wi: "number_of = word_of_int"
  by (auto simp: word_number_of_def intro: ext)

lemmas uints_mod = uints_def [unfolded no_bintr_alt1]

lemma uint_bintrunc: "uint (number_of bin :: 'a word) = 
    number_of (bintrunc CARD('a) bin)"
  unfolding word_number_of_def number_of_eq
  by (auto intro: word_ubin.eq_norm) 

lemma sint_sbintrunc: "sint (number_of bin :: 'a word) = 
    number_of (sbintrunc (CARD('a :: finite) - 1) bin)" 
  unfolding word_number_of_def number_of_eq
  by (auto intro!: word_sbin.eq_norm simp del: one_is_Suc_zero)

lemma unat_bintrunc: 
  "unat (number_of bin :: 'a word) =
    number_of (bintrunc CARD('a) bin)"
  unfolding unat_def nat_number_of_def 
  by (simp only: uint_bintrunc)

(* WARNING - these may not always be helpful *)
declare 
  uint_bintrunc [simp] 
  sint_sbintrunc [simp] 
  unat_bintrunc [simp]

lemma size_0_eq: "size (w :: 'a word) = 0 ==> v = w"
  apply (unfold word_size)
  apply (rule word_uint.Rep_eqD)
  apply (rule box_equals)
    defer
    apply (rule word_ubin.norm_Rep)+
  apply simp
  done

lemmas uint_lem = word_uint.Rep [unfolded uints_num mem_Collect_eq]
lemmas sint_lem = word_sint.Rep [unfolded sints_num mem_Collect_eq]
lemmas uint_ge_0 [iff] = uint_lem [THEN conjunct1, standard]
lemmas uint_lt2p [iff] = uint_lem [THEN conjunct2, standard]
lemmas sint_ge = sint_lem [THEN conjunct1, standard]
lemmas sint_lt = sint_lem [THEN conjunct2, standard]

lemma sign_uint_Pls [simp]: 
  "bin_sign (uint x) = Numeral.Pls"
  by (simp add: sign_Pls_ge_0 number_of_eq)

lemmas uint_m2p_neg = iffD2 [OF diff_less_0_iff_less uint_lt2p, standard]
lemmas uint_m2p_not_non_neg = 
  iffD2 [OF linorder_not_le uint_m2p_neg, standard]

lemma lt2p_lem:
  "CARD('a) <= n ==> uint (w :: 'a word) < 2 ^ n"
  by (rule xtr8 [OF _ uint_lt2p]) simp

lemmas uint_le_0_iff [simp] = 
  uint_ge_0 [THEN leD, THEN linorder_antisym_conv1, standard]

lemma uint_nat: "uint w == int (unat w)"
  unfolding unat_def by auto

lemma uint_number_of:
  "uint (number_of b :: 'a word) = number_of b mod 2 ^ CARD('a)"
  unfolding word_number_of_alt
  by (simp only: int_word_uint)

lemma unat_number_of: 
  "bin_sign b = Numeral.Pls ==> 
  unat (number_of b::'a word) = number_of b mod 2 ^ CARD('a)"
  apply (unfold unat_def)
  apply (clarsimp simp only: uint_number_of)
  apply (rule nat_mod_distrib [THEN trans])
    apply (erule sign_Pls_ge_0 [THEN iffD1])
   apply (simp_all add: nat_power_eq)
  done

lemma sint_number_of: "sint (number_of b :: 'a :: finite word) = (number_of b + 
    2 ^ (CARD('a) - 1)) mod 2 ^ CARD('a) -
    2 ^ (CARD('a) - 1)"
  unfolding word_number_of_alt by (rule int_word_sint)

lemma word_of_int_bin [simp] : 
  "(word_of_int (number_of bin) :: 'a word) = (number_of bin)"
  unfolding word_number_of_alt by auto

lemma word_int_case_wi: 
  "word_int_case f (word_of_int i :: 'b word) = 
    f (i mod 2 ^ CARD('b))"
  unfolding word_int_case_def by (simp add: word_uint.eq_norm)

lemma word_int_split: 
  "P (word_int_case f x) = 
    (ALL i. x = (word_of_int i :: 'b word) & 
      0 <= i & i < 2 ^ CARD('b) --> P (f i))"
  unfolding word_int_case_def
  by (auto simp: word_uint.eq_norm int_mod_eq')

lemma word_int_split_asm: 
  "P (word_int_case f x) = 
    (~ (EX n. x = (word_of_int n :: 'b word) &
      0 <= n & n < 2 ^ CARD('b) & ~ P (f n)))"
  unfolding word_int_case_def
  by (auto simp: word_uint.eq_norm int_mod_eq')
  
lemmas uint_range' =
  word_uint.Rep [unfolded uints_num mem_Collect_eq, standard]
lemmas sint_range' = word_sint.Rep [unfolded One_nat_def
  sints_num mem_Collect_eq, standard]

lemma uint_range_size: "0 <= uint w & uint w < 2 ^ size w"
  unfolding word_size by (rule uint_range')

lemma sint_range_size:
  "- (2 ^ (size w - Suc 0)) <= sint w & sint w < 2 ^ (size w - Suc 0)"
  unfolding word_size by (rule sint_range')

lemmas sint_above_size = sint_range_size
  [THEN conjunct2, THEN [2] xtr8, folded One_nat_def, standard]

lemmas sint_below_size = sint_range_size
  [THEN conjunct1, THEN [2] order_trans, folded One_nat_def, standard]

lemma test_bit_eq_iff: "(test_bit (u::'a word) = test_bit v) = (u = v)"
  unfolding word_test_bit_def by (simp add: bin_nth_eq_iff)

lemma test_bit_size [rule_format] : "(w::'a word) !! n --> n < size w"
  apply (unfold word_test_bit_def)
  apply (subst word_ubin.norm_Rep [symmetric])
  apply (simp only: nth_bintr word_size)
  apply fast
  done

lemma word_eqI [rule_format] : 
  fixes u :: "'a word"
  shows "(ALL n. n < size u --> u !! n = v !! n) ==> u = v"
  apply (rule test_bit_eq_iff [THEN iffD1])
  apply (rule ext)
  apply (erule allE)
  apply (erule impCE)
   prefer 2
   apply assumption
  apply (auto dest!: test_bit_size simp add: word_size)
  done

lemmas word_eqD = test_bit_eq_iff [THEN iffD2, THEN fun_cong, standard]

lemma test_bit_bin': "w !! n = (n < size w & bin_nth (uint w) n)"
  unfolding word_test_bit_def word_size
  by (simp add: nth_bintr [symmetric])

lemmas test_bit_bin = test_bit_bin' [unfolded word_size]

lemma bin_nth_uint_imp': "bin_nth (uint w) n --> n < size w"
  apply (unfold word_size)
  apply (rule impI)
  apply (rule nth_bintr [THEN iffD1, THEN conjunct1])
  apply (subst word_ubin.norm_Rep)
  apply assumption
  done

lemma bin_nth_sint': 
  "n >= size w --> bin_nth (sint w) n = bin_nth (sint w) (size w - 1)"
  apply (rule impI)
  apply (subst word_sbin.norm_Rep [symmetric])
  apply (simp add : nth_sbintr word_size)
  apply auto
  done

lemmas bin_nth_uint_imp = bin_nth_uint_imp' [rule_format, unfolded word_size]
lemmas bin_nth_sint = bin_nth_sint' [rule_format, unfolded word_size]


lemmas num_AB_u [simp] = word_uint.Rep_inverse 
  [unfolded o_def word_number_of_def [symmetric], standard]
lemmas num_AB_s [simp] = word_sint.Rep_inverse 
  [unfolded o_def word_number_of_def [symmetric], standard]

(* naturals *)
lemma uints_unats: "uints n = int ` unats n"
  apply (unfold unats_def uints_num)
  apply safe
  apply (rule_tac image_eqI)
  apply (erule_tac nat_0_le [symmetric])
  apply auto
  apply (erule_tac nat_less_iff [THEN iffD2])
  apply (rule_tac [2] zless_nat_eq_int_zless [THEN iffD1])
  apply (auto simp add : nat_power_eq int_power)
  done

lemma unats_uints: "unats n = nat ` uints n"
  apply (auto simp add : uints_unats image_iff)
  done

lemmas bintr_num = word_ubin.norm_eq_iff 
  [symmetric, folded word_number_of_def, standard]
lemmas sbintr_num = word_sbin.norm_eq_iff 
  [symmetric, folded word_number_of_def, standard]

lemmas num_of_bintr = word_ubin.Abs_norm [folded word_number_of_def, standard]
lemmas num_of_sbintr = word_sbin.Abs_norm [folded word_number_of_def, standard];
    
(* don't add these to simpset, since may want bintrunc n w to be simplified;
  may want these in reverse, but loop as simp rules, so use following *)

lemma num_of_bintr':
  "bintrunc CARD('a) a = b ==> 
    number_of a = (number_of b :: 'a word)"
  apply safe
  apply (rule_tac num_of_bintr [symmetric])
  done

lemma num_of_sbintr':
  "sbintrunc (CARD('a :: finite) - 1) a = b ==> 
    number_of a = (number_of b :: 'a word)"
  apply safe
  apply (rule_tac num_of_sbintr [symmetric])
  done

lemmas num_abs_bintr = sym [THEN trans,
  OF num_of_bintr word_number_of_def [THEN meta_eq_to_obj_eq], standard]
lemmas num_abs_sbintr = sym [THEN trans,
  OF num_of_sbintr word_number_of_def [THEN meta_eq_to_obj_eq], standard]

lemmas test_bit_def' = word_test_bit_def [THEN meta_eq_to_obj_eq, THEN fun_cong]

lemmas word_log_defs = word_and_def word_or_def word_xor_def word_not_def
lemmas word_log_bin_defs = word_log_defs


subsection {* Casting words to different lengths *}

constdefs
  -- "cast a word to a different length"
  scast :: "'a :: finite word => 'b :: finite word"
  "scast w == word_of_int (sint w)"
  ucast :: "'a word => 'b word"
  "ucast w == word_of_int (uint w)"

  -- "whether a cast (or other) function is to a longer or shorter length"
  source_size :: "('a word => 'b) => nat"
  "source_size c == let arb = arbitrary ; x = c arb in size arb"  
  target_size :: "('a => 'b word) => nat"
  "target_size c == size (c arbitrary)"
  is_up :: "('a word => 'b word) => bool"
  "is_up c == source_size c <= target_size c"
  is_down :: "('a word => 'b word) => bool"
  "is_down c == target_size c <= source_size c"

(** cast - note, no arg for new length, as it's determined by type of result,
  thus in "cast w = w, the type means cast to length of w! **)

lemma ucast_id: "ucast w = w"
  unfolding ucast_def by auto

lemma scast_id: "scast w = w"
  unfolding scast_def by auto

lemma nth_ucast: 
  "(ucast w::'a word) !! n = (w !! n & n < CARD('a))"
  apply (unfold ucast_def test_bit_bin)
  apply (simp add: word_ubin.eq_norm nth_bintr word_size) 
  apply (fast elim!: bin_nth_uint_imp)
  done

(* for literal u(s)cast *)

lemma ucast_bintr [simp]: 
  "ucast (number_of w ::'a word) = 
   number_of (bintrunc CARD('a) w)"
  unfolding ucast_def by simp

lemma scast_sbintr [simp]: 
  "scast (number_of w ::'a::finite word) = 
   number_of (sbintrunc (CARD('a) - Suc 0) w)"
  unfolding scast_def by simp

lemmas source_size = source_size_def [unfolded Let_def word_size]
lemmas target_size = target_size_def [unfolded Let_def word_size]
lemmas is_down = is_down_def [unfolded source_size target_size]
lemmas is_up = is_up_def [unfolded source_size target_size]

lemmas is_up_down = 
  trans [OF is_up [THEN meta_eq_to_obj_eq] 
            is_down [THEN meta_eq_to_obj_eq, symmetric], 
         standard]

lemma down_cast_same': "uc = ucast ==> is_down uc ==> uc = scast"
  apply (unfold is_down)
  apply safe
  apply (rule ext)
  apply (unfold ucast_def scast_def uint_sint)
  apply (rule word_ubin.norm_eq_iff [THEN iffD1])
  apply simp
  done

lemma sint_up_scast': 
  "sc = scast ==> is_up sc ==> sint (sc w) = sint w"
  apply (unfold is_up)
  apply safe
  apply (simp add: scast_def word_sbin.eq_norm)
  apply (rule box_equals)
    prefer 3
    apply (rule word_sbin.norm_Rep)
   apply (rule sbintrunc_sbintrunc_l)
   defer
   apply (subst word_sbin.norm_Rep)
   apply (rule refl)
  apply simp
  done

lemma uint_up_ucast':
  "uc = ucast ==> is_up uc ==> uint (uc w) = uint w"
  apply (unfold is_up)
  apply safe
  apply (rule bin_eqI)
  apply (fold word_test_bit_def)
  apply (auto simp add: nth_ucast)
  apply (auto simp add: test_bit_bin)
  done
    
lemmas down_cast_same = refl [THEN down_cast_same']
lemmas uint_up_ucast = refl [THEN uint_up_ucast']
lemmas sint_up_scast = refl [THEN sint_up_scast']

lemma ucast_up_ucast': "uc = ucast ==> is_up uc ==> ucast (uc w) = ucast w"
  apply (simp (no_asm) add: ucast_def)
  apply (clarsimp simp add: uint_up_ucast)
  done
    
lemma scast_up_scast': "sc = scast ==> is_up sc ==> scast (sc w) = scast w"
  apply (simp (no_asm) add: scast_def)
  apply (clarsimp simp add: sint_up_scast)
  done
    
lemmas ucast_up_ucast = refl [THEN ucast_up_ucast']
lemmas scast_up_scast = refl [THEN scast_up_scast']

lemmas ucast_up_ucast_id = trans [OF ucast_up_ucast ucast_id]
lemmas scast_up_scast_id = trans [OF scast_up_scast scast_id]

lemmas isduu = is_up_down [where c = "ucast", THEN iffD2]
lemmas isdus = is_up_down [where c = "scast", THEN iffD2]
lemmas ucast_down_ucast_id = isduu [THEN ucast_up_ucast_id]
lemmas scast_down_scast_id = isdus [THEN ucast_up_ucast_id]

lemma up_ucast_surj:
  "is_up (ucast :: 'b word => 'a word) ==> 
   surj (ucast :: 'a word => 'b word)"
  by (rule surjI, erule ucast_up_ucast_id)

lemma up_scast_surj:
  "is_up (scast :: 'b::finite word => 'a::finite word) ==> 
   surj (scast :: 'a word => 'b word)"
  by (rule surjI, erule scast_up_scast_id)

lemma down_scast_inj:
  "is_down (scast :: 'b::finite word => 'a::finite word) ==> 
   inj_on (ucast :: 'a word => 'b word) A"
  by (rule inj_on_inverseI, erule scast_down_scast_id)

lemma down_ucast_inj:
  "is_down (ucast :: 'b word => 'a word) ==> 
   inj_on (ucast :: 'a word => 'b word) A"
  by (rule inj_on_inverseI, erule ucast_down_ucast_id)

  
lemma ucast_down_no': 
  "uc = ucast ==> is_down uc ==> uc (number_of bin) = number_of bin"
  apply (unfold word_number_of_def is_down)
  apply (clarsimp simp add: ucast_def word_ubin.eq_norm)
  apply (rule word_ubin.norm_eq_iff [THEN iffD1])
  apply (erule bintrunc_bintrunc_ge)
  done
    
lemmas ucast_down_no = ucast_down_no' [OF refl]

end
