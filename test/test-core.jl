@testset "Symbol creation" begin
    ## Symbol creation
    Sym("x")
    Sym(:x)

    symbols("x")
    x,y = symbols("x,y")

    # @syms
    @syms x
    @syms x, y
    @syms t, x(), y[1:5], z::positive, a=>"α₁"
    @test SymPyCore.funcname(x(t)) == "x"
    @test string(y[1]) == "y₁"
    @test string(a) == "α₁"
    @test isempty(solve(z+1))

    # make sure @syms defines in a local scope
    let
        @syms locally_grown
    end
    @test_throws UndefVarError isdefined(locally_grown)

end

@testset "Symbolic numbers" begin
    @test Sym(2) == 2
    @test Sym(2.0) == 2.0
    @test Sym(2//1) == 2
    @test Sym(im) == 1im
    @test Sym(2im) == 2im
    @test Sym(1 + 2im) == 1 + 2im

    pi, e, catalan = Base.MathConstants.pi, Base.MathConstants.e, Base.MathConstants.catalan
    @test N(Sym(pi)) == pi
    @test N(Sym(ℯ)) ==  ℯ

    # @test N(Sym(catalan)) == catalan XXX <<--- expose catalan?
end

@testset "conversion, promotion" begin
    @syms x
    a,b,c = Sym(2), Sym(2.3), Sym(1 + 2im)

    # promote to Sym
    @test promote(x, 2)[2] isa Sym
    @test promote(x, pi)[2] == PI
    @test promote(x, ℯ)[2] == E
    @test promote(x, exp(1))[2] != E
    @test promote(x, 1//3)[2] == Sym(1)/3
    @test_broken promote(x, 1/3)[2] != Sym(1)/3 # Sym(1/3).equals(Sym(1//3)) is True!

    # promotion via Number defaults
    @test 1 + Sym(2) == Sym(3)
    @test 1 - Sym(2) == Sym(-1)
    @test 1 * Sym(2) == Sym(2)
    @test Sym(1) / 2 == Sym(1//2)
    @test 1 / Sym(2) == Sym(1//2)

    # conversion to number types.
    @test convert(Int, a) == 2
    @test convert(BigInt, a) isa BigInt
    @test convert(Float64, b) == 2.3
    @test convert(BigFloat, b) isa BigFloat
    @test convert(Complex{Int}, c) == 1 + 2im

    # N gets type right?
    @syms x
    @test isa(PI.evalf(), Sym)
    @test isa(N(x), Sym)
    @test isa(N(Sym(1)), Integer)
    @test isa(N(Sym(1)/2), Rational)
    @test isa(N(Sym(1.2)), Float64)

end


@testset "Methods" begin
    @syms x
    p = (x-1)*(x-2)

    # sympy.λ calls
    rs = sympy.roots(p)
    @test rs == Dict{Any,Any}(Sym(1) => 1, Sym(2) => 1)

    p = sympy.poly(p, x)

    # obj.method calls
    @test p.coeffs() == Any[1,-3,2]

end

@testset "substitution" begin
    @syms x
    f = x -> x^2 - 2
    y = f(x)
    @test y.subs(x,1) == f(1)

    ex = (x-1)*(y-2)
    @test ex.subs(x, 1) == 0
    @test ex.subs(((x,1),)) == 0
    @test ex.subs(((x,2),(y,2))) == 0

    # imterface
    @test subs(ex, x=>1) == 0       # removed
    @test subs(ex, x=>2, y=>2) == 0
    @test subs(ex, Dict(x=>1)) == 0
    @test ex(x=>1) == 0
    @test ex(x=>2, y=>2) == 0
    @test ex.subs(Dict(x=>1)) == 0 ## shoul break. Awkward mix of python/julia

    # Test subs on simple numbers
    @syms x y
    @test Sym(2)(x=>300, y=>1.2) == 2

    #Test subs for pars and dicts
    ex = 1
    dict1 = Dict{String,Any}()
    dict2 = Dict{Any,Any}()
    #test subs
    for i=1:4
        x = Sym("x$i")
        ex=ex*x
        dict1[string(x)] = i ## This shoudn't work!!
        dict2[x] = i
    end
    for d in (dict1,)
        @test ex |> subs(d) == factorial(4)
        @test subs(ex, d) == factorial(4)
        @test subs(ex, d...) == factorial(4)
        @test ex |> subs(d...) == factorial(4)
        @test ex(d) == factorial(4)
        @test ex(d...) == factorial(4)
    end
    for d in (dict2,)
        @test ex |> subs(d) == factorial(4)
        @test subs(ex, d) == factorial(4)
        @test subs(ex, d...) == factorial(4)
        @test ex |> subs(d...) == factorial(4)
        @test ex(d) == factorial(4)
        @test ex(d...) == factorial(4)
    end

end


@testset "simplify" begin
    @syms x y
    @syms xₚ::positive, yₚ::positive
    @syms a::positive b::positive

    @test simplify(sin(x)^2 + cos(x)^2) == 1
    @test simplify((x^3 + x^2 - x - 1)/(x^2 + 2x + 1)) == x - 1
    @test simplify(x^a*x^b) == x^(a+b)
    @test simplify(x^a*y^a) == x^a * y^a
    @test simplify(xₚ^a*yₚ^a) == (xₚ* yₚ)^a
end


@testset "Equality" begin
    T,F, No, N,M = Sym(true), Sym(false), Sym(nothing), Sym(NaN), missing
    @syms x y=>"x" z::real=>"x"


    @test x == x
    @test x == y
    @test x != z
    @test T == T
    @test T == true
    @test F == F
    @test F == false
    @test No == No
    @test No == nothing
    @test N != N
    @test isequal(N, N)
    @test isequal(oo, N) == isequal(Inf, NaN)
    @test ismissing(N == M)
    @test ismissing(M == M)
    @test isequal(M, M)

    a = (T,F,N,M,x,y,z)
    for i ∈ 1:length(a)
        for j ∈ (i+1):length(a)
            u,v = a[i], a[j]
            @test isless(u,v) + isequal(u,v) + isless(v,u) == 1
        end
    end

    @syms x::positive
    @test Lt(x, 0) == false # sympy.logic.boolalg.BooleanFalse == false

end

@testset "solve" begin
    @syms x y::real z::positive

    @test length(solve(x^2 + 1)) == 2
    @test length(solve(y^2 + 1)) != 2
    @test length(solve(y^2 - 1)) == 2
    @test length(solve(z^2 - 1)) != 2
    @test length(solve((z-1)*(z-2))) == 2

end

@testset "solveset" begin
    @syms x y::real z::positive

    @test length(solveset(x^2 + 1)) == 2
    #@test_broken length(solveset(y^2 + 1)) != 2 # solveset ignores assumptions?

    @test length(solveset((x-2)*(x-2) ~ 0)) == 1
    @test length(solveset((x-2)*(x-3) ~ 0)) == 2

    u = solveset(sin(x) ~ 1//2, x) # an infinite set
    J = sympy.Interval(-PI/2, PI/2)
    @test length(intersect(u, J)) == 1

end

@testset "Assumptions" begin
    ## Assumptions
    @syms x_real::real
    @syms x_real_positive::(real, positive)

    @test ask(𝑄.even(Sym(2))) == true
    @test ask(𝑄.even(Sym(3))) == false
    @test ask(𝑄.nonzero(Sym(3))) == true
    @test ask(𝑄.positive(x_real)) == Sym(nothing) # ==(nothing) promotes to ===
    @test ask(𝑄.positive(x_real_positive)) == true
    @test ask(𝑄.nonnegative(x_real^2)) == true
    ## XXX @test ask(𝑄.upper_triangular([x_real 1; 0 x_real])) == true
    @test ask(𝑄.positive_definite([x_real 1; 1 x_real])) == Sym(nothing)
end

@testset "Intervals" begin
    @test sympy.Interval(0,1).boundary == Set(Sym[0,1])
    @test sympy.Interval(0,1, false, false) == sympy.Interval(0,1,true,true).closure # [0,1] == (0,1).closure
    @test sympy.Interval(0,1,true,true).complement(𝑆.Reals) == union(sympy.Interval(-oo, 0), sympy.Interval(1, oo)) # (0,1)^c = (-oo, 0] ∪ [1, oo)

    @test sympy.Interval(0,1).contains(1//2) == true
    @test 1//2 ∈ sympy.Interval(0,1)
end

@testset "Sets" begin
    s = sympy.FiniteSet("H","T")
    s1 = ↓(s).powerset() # XXX s1 = s.powerset()
    a, b = sympy.Interval(0,1), sympy.Interval(2,3)
    @test a.is_disjoint(b) == true
    @test union(a, b).measure == 2
end

@testset "doit" begin
    ### doit
    @syms x f() g()

    D = Differential(x)
    df = D(f(x))
    dfx = subs(df, f(x) => x^2)
    @test dfx.doit() == 2*x
    @test doit(dfx) == 2*x
    @test dfx |> doit == 2*x
    # use deep=true to force nested evaluations
    dgfx = g(dfx)
    @test dgfx.doit(deep=true) == g(2*x)
    @test doit(dgfx, deep=true) == g(2*x)
    @test dgfx |> doit(deep=true) == g(2*x)

end

@testset "getproperty" begin
    # test getproperty override

    # properties have 3-valued logic
    @syms x::positive y
    @test x.is_real
    @test !x.is_zero
    @test y.is_real == nothing
    @test Sym(7).is_prime
    @test !Sym(8).is_prime
    @test x.isprime == nothing

    # we get modules back
    @test Introspection.classname(sympy.logic) == "module"

    # get callable object for objects with __call__ method
    @test x.subs isa SymPyCore.SymbolicCallable
    @test x.subs(x,2) isa Sym # calls return Sym objects (or containers of)
end
