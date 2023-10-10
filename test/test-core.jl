
@testset "Symbols" begin

end

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

@testset "Conversion, promotion" begin

end

    @testset "Methods" begin
        # sympy.method, method
        # obj.method(args..) method(obj, args...)
        @syms x

        p = (x-1)*(x-2)
        @test sympy.roots(p) == Dict{Any,Any}(Sym(1) => 1, Sym(2)=> 1) # sympy.roots
        p = sympy.poly(p, x) # XXX sympy.Poly(p, x)
        @test p.coeffs() == Any[1,-3,2] # p.coeffs

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

end


@testset "Core" begin

end

@testset "Core" begin

end

@testset "Core" begin

end

@testset "Core" begin

end

@testset "Core" begin

end

@testset "Core" begin

end

@testset "Core" begin

end
