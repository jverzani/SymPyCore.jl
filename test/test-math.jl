using Test
using SpecialFunctions

@testset "Math" begin
    ρ = symbols("rho", positive=true)
    ϕ = symbols("phi", real=true)
    x = symbols("x")

    @test simplify(hypot(ρ*cos(ϕ), ρ * sin(ϕ))) == ρ
    @test simplify(hypot(ρ*cos(ϕ), 3)) == sqrt(ρ^2*cos(ϕ)^2 + 9)

    @test real(sqrt(Sym(5))+im) == sqrt(Sym(5))
    @test real(sqrt(Sym(5))+im) isa Sym
    @test imag(sqrt(Sym(5))+im) == 1
    @test imag(sqrt(Sym(5))+im) isa Sym

    @test atan(Sym(1), 1) == PI/4
    @test atan(Sym(1), -1) == 3PI/4

    @test N(angle(Sym(1) + Sym(2)*IM)) ≈ atan(2,1)

    @test factorial(Sym(0)) == 1
    @test factorial(Sym(7)) == 5040

    @test sympy.factorial2(Sym(5)) == 15
    @test sympy.factorial2(Sym(-5)) == Sym(1)/3

    @test erf(Sym(0)) == 0
    @test erf(Sym(oo)) == 1
    @test diff(erf(x), x) == 2*exp(-x^2)/sqrt(PI)


    @test sinc(Sym(0)) == 1
    # test consistency with Julia's sinc
    @test sinc(Sym(1)) == 0
    @test N(sinc(Sym(0.2))) ≈ sinc(0.2)

    @test flipsign(Sym(3), 2.0) == 3
    @test flipsign(Sym(3), 0.0) == 3
    @test flipsign(Sym(3), -0.0) == -3
    @test flipsign(Sym(3), -2.0) == -3

    @test eps(Sym) == 0
    #@test rewrite(sinc(x), "jn") == jn(0, PI * x)
end

@test "sign and absolute value functions" begin
    # abs, abs2,s ign, signbit, copysign, flipsign
    @syms x y::real z::positive
    a, b = Sym(22//10), Sym(-3)

    @test !iszero(abs(x) - x)
    @test iszero(abs(z) - z)
    @test abs(b) == 3

    @test abs(x)^2 != abs2(x)
    @test abs(y)^2 == abs2(y)
    @test abs(z)^2 == abs2(z)

    @test sign(x) != 1
    @test sign(z) == 1
    @test sign(a) == 1
    @test sign(b) == -1
    @test sign(Sym(0)) = 0

    # no signbit

    @test copysign(x,y)(x=>1, y=>-2) == -2
    @test copysign(Sym(1), Sym(-2)) == -1
    @test copysign(Sym(-1), Sym(2)) == 1

    @test flipsign(x, y)(x=>5, y=>3) == 5
    @test flipsign(Sym(5), Sym(3)) == 5
    @test flipsign(Sym(5), Sym(-3)) == -5

end

@test "powers, logs, roots" begin
    # sqrt, cbrt, hypot, exp, expm1, ldexp, log, log(b,x), log2(x), log10, log1p,
    # XXX exponent, significant
    @syms x y::real z::positive
    u, v = 22//10, -3
    a, b = Sym(u), Sym(v)

    @test sqrt(x) == x^(1//2)
    @test sqrt(z) == z^(1//2)

    @test cbrt(x) == x^(1//3)
    @test cbrt(z) == z^(1//3)

    @test hypot(y,z) == sqrt(y^2 + z^2)
    @test hypot(a,b) == hypot(u, v)

    @test exp(x) == E^x
    @test exp(a) == u

    @test expm1(x) == E^x - 1
    @test expm1(a) == exp(u) - 1

    @test ldexp(x, y ) == x * 2^y
    @test iszero(ldexp(a, 4) - ldexp(float(u),4))

    @test log(z)(z => a) ≈ log(u)
    @test log(a) == log(22/10)

    @test log(2, x) == log(x)/log(Sym(2)) # sympy.log(x,b) is order
    @test log2(x) == log(x)/log(Sym(2))
    @test log10(x) == log(x)/log(Sym(10))
    @test log1p(x) == log(1 + x)

end

@testset "isless" begin
    @syms w, x, y
    @test isless(w,x) + isless(x,w) + isequal(x,w) == 1
    a, b = Sym(2), Sym(3)
    @test isless(a,b) + isless(b,a) + isequal(a,b) == 1
    @test isless(a,b)
    @test isless(a,3) # promotes
    @test !isless(x, b)  # sympy.compare specific
end

@testset  "nan"  begin
    #  issue  346
    a = sympy.nan
    a′ = NaN

    @test (a < 0) == (a′ < 0)
    @test (a > 0) == (a′ > 0)
    @test (a == 0) == (a′ == 0)

end

@testset "Polynomial" begin
    # expand, factor, together, apart
end


@testset "solve" begin
    @syms x::real, y::real, a::Real
    solve(x^2 - 2x)
    solve(x^2 - 2a, x)
    solve(x^2 - 2a, a)
    solve(Lt(x-2, 0))
    solve( x-2 ≪ 0)
    exs = [x-y-1, x+y-2]
    di = solve(exs)
    @test di[x] == 3//2
    @test map(ex -> subs(ex, di), exs) == [0,0]
    solve([x-y-a, x+y], [x,y])

end

@testset "solveset" begin
end

@testset "nsolve, linsolve, nonlinsolve" begin
    ## nsolve -- not method for arrays, issue 268
    @syms z1::positive z2z1::positive
    # XXX No error? @test_throws MethodError nsolve([z1^2-1, z1+z2z1-2], [z1,z2z1], [1,1])  # non symbolic first argument
    @test all(N.(sympy.nsolve([z1^2-1, z1+z2z1-2], [z1,z2z1], (1,1))) .≈ [1.0, 1.0])

    ## linsolve
    @syms x y
    M=Sym[1 2 3; 2 3 4]
    as = linsolve(M, x, y)


end

@testset "roots, real_roots" begin
end

@testset "dsolve" begin
end


@testset "Calculus" begin
    @syms x, y a
    @test limit(sin(x*a)/x, x=>0) == a
    @test diff(exp(x*a), x) == a*exp(x*a)
    @test integrate(cos(x*a), x) == sin(x*a) / a
    @test summation(x^2, (x, 1, 10)) == sum(x^2 for x ∈ 1:10)
end

@testset "Piecewise" begin

end

@testset "Relations" begin
    # CommonEq

end

@testset "Assumptions" begin
    @test ask(𝑄.even(Sym(2))) == true
    @test ask(𝑄.even(Sym(3))) == false
    @test ask(𝑄.nonzero(Sym(3))) == true
    @syms x_real::real
    @syms x_real_positive::(real, positive)
    @test ask(𝑄.positive(x_real)) == nothing
    @test ask(𝑄.positive(x_real_positive)) == true
    @test ask(𝑄.nonnegative(x_real^2)) == true
    ## XXX @test ask(𝑄.upper_triangular([x_real 1; 0 x_real])) == true
    @test ask(𝑄.positive_definite([x_real 1; 1 x_real])) == nothing
end


@testset "Fix past issues" begin
    @syms x y z
    ## Issue # 56
    @test Sym(1+2im) == 1+2IM
    @test convert(Sym, 1 + 2im) == 1 + 2IM


    ## Issue #59
    sympy.cse(sin(x)+sin(x)*cos(x))
    sympy.cse([sin(x), sin(x)*cos(x)])
    sympy.cse( [sin(x), sin(x)*cos(x), cos(x), sin(x)*cos(x)])

    ## Issue #60, lambidfy
    x, y = symbols("x, y")
    lambdify(sin(x)*cos(2x) * exp(x^2/2))
    fn = lambdify(sin(x)*asin(x)*sinh(x)); fn(0.25)
    lambdify(real(x)*imag(x))
    @test lambdify(min(x,y))(3,2) == 2 # XXX lambdify(Min(x,y))(3,2) == 2

    ex = 2 * x^2/(3-x)*exp(x)*sin(x)*sind(x)
    fn = lambdify(ex); map(fn, rand(10))
    ex = x - y
    @test lambdify(ex, (x,y))(3,2) == 1

    Indicator(x, a, b) = sympy.Piecewise((1, Lt(x, b) & Gt(x,a)), (0, Le(x,a)), (0, Ge(x,b)))
    i = Indicator(x, 0, 1)
    u = lambdify(i)
    @test u(.5) == 1
    @test u(1.5) == 0

    # SymPy issue 567; constants
    u = lambdify(Sym(1//2))
    @test u() == u(1,2,3) == 1/2
    @syms x
    ex = integrate(sqrt(1 + (1/x)^2), (x, 1/sympy.E, sympy.E))
    @test lambdify(ex)() ≈ 3.1961985135995072

#    i2 = SymPy.lambdify_expr(x^2,name=:square)
#    @test i2.head == :function
#    @test i2.args[1].args[1] == :square
    ## @test i2.args[2] == :(x.^2) # too fussy


    ## issue #67
    @test N(Sym(4)/3) == 4//3
    @test N(convert(Sym, 4//3)) == 4//3

    ## issue #71
    @test log(Sym(3), Sym(4)) == log(Sym(4)) / log(Sym(3))

    ## issue #103 # this does not work for `x` (which has `classname(x) == "Symbol"`), but should work for other expressions
    for ex in (sin(x), x*y^2*x, sqrt(x^2 - 2y))
        @test Bool(func(ex)(SymPy.Introspection.args(ex)...) == ex) # XXX func(ex)(SymPy.Introspection.args(ex)...) == ex
    end

    ## properties (Issue #119)
    @test (sympify(3).is_odd) == true
    @test sympy.poly(x^2 -2, x).is_monic == true # not Poly

    ## test round (Issue #153)
    y = Sym(eps())
    @test round(N(y), digits=5) == 0
    @test round(N(y), digits=16) != 0

    ## lambdify over a matrix #218
    @syms x y
    s = [1 0; 0 1]
    @test lambdify(x*s)(2) == 2 * s
    U = [x-y x+y; x+y x-y]
    @test lambdify(U, [x,y])(2,4) == [-2 6;6 -2]
    @test lambdify(U, [y,x])(2,4) == [ 2 6;6  2]

    @test eltype(lambdify([x 0; 1 x])(0)) <: Integer
    @test eltype(lambdify([x 0; 1 x], T=Float64)(0)) == Float64

    # issue 222 type of eigvals
    A = [Sym("a") 1; 0 1]
    @test typeof(eigvals(A)) <: Dict ## XXX typeof(eigvals(A)) <: Vector{Sym}

    # issue 231 Q.complex
    @syms x_maybecomplex
    @syms x_imag::imaginary
    @test ask(𝑄.complex(x_maybecomplex)) == nothing
    @test ask(𝑄.complex(x_imag)) == true

    # issue 242 lambdify and conjugate
    @syms x
    #expr = conjugate(x)
    expr = conj(x)
    fn = lambdify(expr)
    @test fn(1.0im) == 0.0 - 1.0im
    fn = lambdify(expr, use_julia_code=true)
    @test fn(1.0im) == 0.0 - 1.0im

    # issue 245 missing sincos
    @test applicable(sincos, x)
    @test sincos(x)[1] == sin(x)

    # issue 256 det
    @syms rho::real phi::real theta::real
    xs = [rho*cos(theta)*sin(phi), rho*sin(theta)*sin(phi), rho*cos(phi)]
    J = [diff(x, u) for x in xs, u in (rho, phi, theta)]
    J.det()

    # issue #273 x[i]
    x = sympy.IndexedBase("x")
    i,j = sympy.symbols("i j", integer=true)
    ## XXX not defined
    #@test x[i] == PyCall.py"$x[$i]"

    ## issue #295 with piecewise function
    @syms x
    p = sympy.Piecewise((x,Gt(x,0)), (x^2, Le(x,0)))
    @test lambdify(p)(2) == 2
    @test lambdify(p)(-2) == (-2)^2

    # issue 298 lambdify for results of dsolve
    @syms t
    F = SymFunction("F")
    diffeq = diff(F(t),t) - 3*F(t)
    res = dsolve(diffeq, F(t), ics=Dict(F(0) => 2))  # 2exp(3t)
    @test lambdify(res)(1) ≈ 2*exp(3*1)

    # issue 304 wrong values for sind, ...
    a = Sym(45)
    @test sind(a) == sin(PI/4)

    # issue #319  with   use   of  Dummy, but
    #  really  a  lambdify issue
    dummy = sympy.Dummy
    # Symbolic differentiation of functions
    function D(f)
        x = dummy("x")
        lambdify(diff.(f(x), x), (x,))
    end
    @test D(t -> t^2)(1) == 2

    # issue   #320  with integrate(f) when
    # f  is consant
    # XXX @test integrate(x -> 1, 0, 1)  == 1 <-- want to deprecate
    # XXX @test limit(x->1,  x, 0) == 1
    # xxx @test diff(x->1)  ==   0

    ## Issue 324 with inference of matrix operations
    A = fill(Sym("a"), 2, 2)
    @test eltype(A*A) == Sym
    @test eltype(A*ones(2,2)) == Sym
    @test eltype(A*Diagonal([1,1])) == Sym
    VERSION >= v"1.2.0"  && @test eltype(A * I(2)) == Sym

    ## Issue 328 with E -> e
    @syms x
    ex = 3 * sympy.E * x
    fn = lambdify(ex)
    @test fn(1) ≈ 3*exp(1) * 1

    ## Issue 332 with `abs2`
    @syms x::real
    @test abs2(x) == x*x
    @syms x
    @test abs2(x) == x*conj(x)

    ## Issue 376 promote to Sym Before pycall
    f = x -> x^2 + 1 +log(abs( 11*x-15 ))/99
    @test limit(f(x), x=>15//11) == -oo

    ## Issue 351 booleans  and arithmetic operations
    @test Sym(1) + true == Sym(2) == true +  Sym(1)
    @test Sym(1) - true == Sym(0) == true -  Sym(1)
    @test Sym(1) * true == Sym(1) == true * Sym(1)
    @test Sym(1) / true == Sym(1) == true / Sym(1)
    @test true^Sym(1)   == Sym(1) == Sym(1)^true

    ## Issue #390 on div (__div__ was depracated, use __truediv__)
    #XXX@test Sym(2):-Sym(2):-Sym(2) |> collect == [2, 0, -2]

    ## Lambda function to create a lambda
    # XXX not working!
    #@syms x
    #ex = x^2 - 2
    #fn1 = Lambda(x, ex)
    #fn2 = lambdify(ex)
    #@test fn1(3) == fn2(3)

    ## issue 402 with lamdify and Order
    @syms x
    t = series(exp(x), x, 0, 2)
    @test lambdify(t)(1/2) == 1 + 1/2

        ## Issue #405 with ambigous methods
    @syms α
    M = Sym[1 2; 3 4] ## XXX M = SymMatrix([1 2; 3 4])
    @test α * M == M * α
    @test 2 * M == M * 2
    @test isa(M/α, SymMatrix)
    @test isa(α * inv(M), SymMatrix)

    ## issue #408 with inv
    @syms n::(integer,positive)
    A = sympy.MatrixSymbol("A", n, n)
    @test A.inv() == A.I ## XXX inv(A) == A.I

    # ceil broken
    @syms x
    @test limit(ceil(x), x=>0, dir="+") != limit(ceil(x), x=>0, dir="-")
    @test limit(floor(x), x=>0, dir="+") != limit(floor(x), x=>0, dir="-")

    ## issue #411 with Heaviside
    @syms t
    u = Heaviside(t)
    λ = lambdify(u)
    @test all((iszero(λ(-1)), isone(λ(1))))
    VersionNumber(string(sympy.py.__version__)) >= v"1.9" && @test λ(0) == 1//2
    u = Heaviside(t, 1)
    λ = lambdify(u)
    @test all((iszero(λ(-1)), isone(λ(0)), isone(λ(1))))


    ## Issue catch all for N; floats only
    @syms x
    ex = integrate(sqrt(1 + (1/x)^2), (x, 1/sympy.E, sympy.E))
    @test N(ex) ≈ 3.196198513599507

        ## Issue #433 add sympy docstrings, clean up docstring
    # XX sprint(io -> show(io, SymPy.Doc(:sin)))
    Base.Docs.getdoc(sin(x))

end
