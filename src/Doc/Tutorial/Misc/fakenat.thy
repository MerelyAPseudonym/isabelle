(*<*)
theory fakenat imports Main begin
(*>*)

text{*\noindent
The type \tydx{nat} of natural
numbers is predefined to have the constructors \cdx{0} and~\cdx{Suc}.
It behaves approximately as if it were declared like this:
*}

datatype nat = zero ("0") | Suc nat
(*<*)
end
(*>*)
