# test pattern matching

#     ## match, replace, xreplace, rewrite
#     x,y,z = symbols("x, y, z")
#     #a,b,c = map(sympy.Wild, (:a,:b,:c)) ## XXX Wild needs strings -- not symbols
#     a,b,c = map(sympy.Wild, ("a", "b", "c")) ## XXX Wild needs strings -- not symbols
#     # ## match: we have pattern, expression to follow `match`
#     d = match(a^a, (x+y)^(x+y))
#     @test d[a] == x+y
#     d = match(a^b, (x+y)^(x+y))
#     @test d[b] == x + y
#     ex = (2x)^2
#     pat = a*b^c
#     d = match(pat, ex)
#     @test d[a] == 4 && d[b] == x && d[c] == 2
#     @test pat.xreplace(d) == 4x^2

#     ## replace
#     a = Wild("a")
#     ex = log(sin(x)) + tan(sin(x^2))
#     ##XXX    @test replace(ex, func(sin(x)), u ->  sin(2u)) == log(sin(2x)) + tan(sin(2x^2))
#     @test replace(ex, func(sin(x)), func(tan(x))) == log(tan(x)) + tan(tan(x^2))
#     @test replace(ex, sin(a), tan(a)) ==  log(tan(x)) + tan(tan(x^2))
#     @test replace(ex, sin(a), a) == log(x) + tan(x^2)
#     @test replace(x*y, a*x, a) == y

#     ## xreplace
#     @test (1 + x*y).xreplace(Dict(x => PI)) == 1 + PI*y
#     @test (x*y + z).xreplace(Dict(x*y => PI)) == z + PI
#     @test (x*y * z).xreplace(Dict(x*y => PI)) == x* y * z
#     @test (x + 2 + exp(x + 2)).xreplace(Dict(x+2=>y)) == x + exp(y) + 2
