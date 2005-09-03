(*  Title:      HOLCF/IOA/ABP/Abschannels.thy
    ID:         $Id$
    Author:     Olaf M�ller
*)

header {* The transmission channel -- finite version *}

theory Abschannel_finite
imports Abschannel IOA Action Lemmas
begin

consts

ch_fin_asig  :: "'a abs_action signature"

ch_fin_trans :: "('a abs_action, 'a list)transition set"

ch_fin_ioa   :: "('a abs_action, 'a list)ioa"

srch_fin_asig  :: "'m action signature"
rsch_fin_asig  :: "'m action signature"

srch_fin_trans :: "('m action, 'm packet list)transition set"
rsch_fin_trans :: "('m action, bool list)transition set"

srch_fin_ioa   :: "('m action, 'm packet list)ioa"
rsch_fin_ioa   :: "('m action, bool list)ioa"

reverse        :: "'a list => 'a list"

primrec
  reverse_Nil:  "reverse([]) = []"
  reverse_Cons: "reverse(x#xs) =  reverse(xs)@[x]"

defs

srch_fin_asig_def: "srch_fin_asig == asig_of(srch_fin_ioa)"
rsch_fin_asig_def: "rsch_fin_asig == asig_of(rsch_fin_ioa)"

srch_fin_trans_def: "srch_fin_trans == trans_of(srch_fin_ioa)"
rsch_fin_trans_def: "rsch_fin_trans == trans_of(rsch_fin_ioa)"

srch_fin_ioa_def: "srch_fin_ioa == rename ch_fin_ioa  srch_actions"
rsch_fin_ioa_def: "rsch_fin_ioa == rename ch_fin_ioa  rsch_actions"


ch_fin_asig_def: "ch_fin_asig == ch_asig"

ch_fin_trans_def: "ch_fin_trans ==
 {tr. let s = fst(tr);
          t = snd(snd(tr))
      in
      case fst(snd(tr))
        of S(b) => ((t = s) |
                   (if (b=hd(reverse(s)) & s~=[]) then  t=s else  t=s@[b])) |
           R(b) => s ~= [] &
                    b = hd(s) &
                    ((t = s) | (t = tl(s)))    }"

ch_fin_ioa_def: "ch_fin_ioa == (ch_fin_asig, {[]}, ch_fin_trans,{},{})"

ML {* use_legacy_bindings (the_context ()) *}

end
