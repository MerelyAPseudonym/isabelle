(*<*)theory Overloading = Overloading1:(*>*)
instance list :: ("term")ordrel
by intro_classes

text{*\noindent
This means. Of course we should also define the meaning of @{text <<=} and
@{text <<} on lists.
*}

defs (overloaded)
prefix_def:
  "xs <<= (ys::'a::ordrel list)  \<equiv>  \<exists>zs. ys = xs@zs"
strict_prefix_def:
  "xs << (ys::'a::ordrel list)   \<equiv>  xs <<= ys \<and> xs \<noteq> ys"
  
text{*
We could also have made the second definition non-overloaded once and for
all: @{prop"x << y \<equiv> x <<= y \<and> x \<noteq> y"}.  This would have saved us writing
many similar definitions at different types, but it would also have fixed
that @{text <<} is defined in terms of @{text <<=} and never the other way
around. Below you will see why we want to avoid this asymmetry.
*}
(*<*)end(*>*)
