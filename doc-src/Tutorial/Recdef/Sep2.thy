Sep2 = Main +
consts sep :: 'a list => 'a => 'a list
recdef sep "measure length"
  "sep (x#y#zs) = (%a. x # a # sep zs a)"
  "sep xs       = (%a. xs)"
end
