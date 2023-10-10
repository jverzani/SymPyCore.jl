## promote

## convert is either convert or pyconvert
_convert() = ()

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

    if _istree(x)
        return _convert(Float64, y.evalf())
    end

    if x.is_real == true
        x.is_zero && return 0
        x.is_infinite && return (y.is_negative ? -1 : 1) * Inf
        if x.is_integer == true
            u = abs(x)
            T = Le(u, typemax(Int)) == Sym(true) ? Int : BigInt
            return _convert(T, y)
        end
        if string(y.__class__.__name__) == "Float"
            if _convert(Bool, y._prec <= 64)# <= 64
                return _convert(Float64, y)
            else
                return _convert(BigFloat, y)
            end
        end
        Sym(y.is_rational) == Sym(true) && return Rational(N(numerator(x)), N(denominator(x)))
        if _istree(x)
            if length(args(x)) > 1
                def_precision_decimal = ceil(Int, log10(big"2"^Base.MPFR.DEFAULT_PRECISION.x))
                return _convert(BigFloat, y.evalf(def_precision_decimal))
            end
        end
        return _convert(Float64, y.evalf())
    end
    cnm = string(y.__class__.__name__)
    cnm == "ComplexRootOf" && return N(y.evalf(16))
    cnm == "int" && return _convert(Int, y)
    cnm == "float" && return _convert(Float64, y)
    cnm == "mpf" && return  _convert(Float64, y)
    cnm == "complex" && return complex(N(real(x)), N(imag(x)))
    cnm == "mpc" && return complex(N(real(x)), N(imag(x)))
    cnm == "Infinity" && Inf
    cnm == "NegativeInfinity" && -Inf
    cnm == "ComplexInfinity" && complex(Inf)
    Eq(x, Sym(true)) == Sym(true) && return true
    Eq(x, Sym(false)) == Sym(true) && return false

    x.is_imaginary == Sym(true) && return complex(0, N(imag(x)))
    x.is_complex == Sym(true) && return complex(N(real(x)), N(imag(x)))

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
Base.:&(x::Sym, y::Sym) =  ↑(↓(x).__and__(↓(y)))
Base.:|(x::Sym, y::Sym) =  ↑(↓(x).__or__(↓(y)))
Base.:!(x::Sym)         =  ↑(↓(x).__invert__())

## use ∨, ∧, ¬ for |,&,! (\vee<tab>, \wedge<tab>, \neg<tab>)
∨(x::Sym, y::Sym) = x | y
∧(x::Sym, y::Sym) = x & y
¬(x::Sym) = !x
