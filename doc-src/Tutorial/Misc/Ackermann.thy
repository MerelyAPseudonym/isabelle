Ackermann = WF_Rel +
consts ack :: "nat * nat => nat"
recdef ack "measure(%m. m) ** measure(%n. n)"
"ack(0,n)         = Suc n"
"ack(Suc m,0)     = ack(m, 1)"
"ack(Suc m,Suc n) = ack(m,ack(Suc m,n))"
end
