(*  Title:      Code_Test_MLtonL.thy
    Author:     Andreas Lochbihler, ETH Zurich

Test case for test_code on MLton
*)

theory Code_Test_MLton imports Code_Test begin

test_code "14 + 7 * -12 = (140 div -2 :: integer)" in MLton

eval_term "14 + 7 * -12 :: integer" in MLton

end