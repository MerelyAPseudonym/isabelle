Fib = WF_Rel +
consts fib  :: nat => nat
recdef fib "measure(%n. n)"
    "fib 0 = 0"
    "fib 1 = 1"
    "fib (Suc(Suc x)) = fib x + fib (Suc x)"
end
