## promote

## convert

## N
# special case numbers in sympy.core.numbers
sympy_core_numbers = ((:Zero, 0),
                      (:One, 1),
                      (:NegativeOne, -1),
                      (:Half, 1//2),
                      (:NaN, NaN),
                      (:Exp1, ℯ),
                      (:ImaginaryUnit, im),
                      (:Pi, pi),
                      (:EulerGamma, Base.MathConstants.eulergamma),
                      (:Catalan, Base.MathConstants.catalan),
                      (:GoldenRation, Base.MathConstants.golden),
                      (:TribonacciConstant, big(1)/3 + (-big(3)*sqrt(big(33)) + 19)^(1//3)/3 + (3*sqrt(big(33)) + 19)^(1//3)/3))


# N(x.evalf([prec]))
function N(x)
    !is_symbolic(x) && return x
    !isempty(free_symbols(x)) && return x # need constant
    y = ↓(x)
    #y.is_constant() || return Sym(y)

    cname = Symbol(classname(y))
    for (u,v) ∈ sympy_core_numbers
        cname == u && return v
    end

    if y.is_real
        y.is_zero && return 0
        y.is_infinite && return (y.is_negative ? -1 : 1) * Inf
        if y.is_integer == true
            u = abs(x)
            T = Le(u, typemax(Int)) == Sym(true) ? Int : BigInt
            return convert(T, y)
        end
        if y.__class__.__name__ == "Float"
            if y._prec <= 64
                return convert(Float64, y)
            else
                return convert(BigFloat, y)
            end
        end
        y.is_rational == true && return Rational(N(numerator(x)), N(denominator(x)))
        if _istree(x)
            if length(args(x)) > 1
                def_precision_decimal = ceil(Int, log10(big"2"^Base.MPFR.DEFAULT_PRECISION.x))
                return convert(BigFloat, y.evalf(def_precision_decimal))
            end
        end
        return convert(Float64, y.evalf())
    end

    y.__class__.__name__ == "ComplexRootOf" && return N(y.evalf(16))
    y.__class__.__name__ == "int" && return convert(Int, y)
    y.__class__.__name__ == "float" && return convert(Float64, y)
    y.__class__.__name__ == "mpf" && return  convert(Float64, y)
    y.__class__.__name__ == "complex" && return complex(N(real(x)), N(imag(x)))
    y.__class__.__name__ == "mpc" && return complex(N(real(x)), N(imag(x)))
    y.__class__.__name__ == "Infinity" && Inf
    y.__class__.__name__ == "NegativeInfinity" && -Inf
    y.__class__.__name__ == "ComplexInfinity" && complex(Inf)
    Eq(x, Sym(true)) == Sym(true) && return true
    Eq(x, Sym(false)) == Sym(true) && return false

    y.is_imaginary && return complex(0, N(imag(x)))
    y.is_complex && return complex(N(real(x)), N(real(y)))

    try
        lambdify(x)()
    catch err
        @info "FAILED to find type for $x. Please report"
        x
    end
end

function N(x::Sym, digits::Int; kwargs...)
    @show :XXX
end


## infix logical operators
import Base: &, |, !

## XXX Experimental! Not sure these are such a good idea ...
Base.:&(x::Sym, y::Sym) =  ↑(↓(x).__and__(y))
Base.:|(x::Sym, y::Sym) =  ↑(↓(x).__or__(y))
!(x::Sym)               =  ↑(↓(x).__invert__())

## use ∨, ∧, ¬ for |,&,! (\vee<tab>, \wedge<tab>, \neg<tab>)
∨(x::Sym, y::Sym) = x | y
∧(x::Sym, y::Sym) = x & y
¬(x::Sym) = !x
