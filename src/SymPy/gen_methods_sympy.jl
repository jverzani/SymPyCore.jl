## Code to generate methods for exported functions from Base, LinearAlgebra, and SpecialFunctions
## which have a SymPy counterpart.
## Key to this are two exported operators: ↓ and ↑
## visualized by this diagram
##
## Julia ⋯⋯⋯⋯ >  Julia
##  |                ^
##  |                |
##  | ↓              | ↑
##  |                |
##  v      (SymPy)   |
## Python  ------> Python
##
## The bulk of the translations follow this pattern
## Base.λ(x::Sym, args...; kwargs...) = ↑(_sympy_.λ(↓(x), ↓(args)...; ↓ₖ(kwargs)...)
## which allows for metaprogramming
##
## Also are a few object methods, essentially:
## meth(obj::Sym, args...; kwargs...) = obj.meth(args...; kwargs...)

##--------------------------------------------------
# generic method pattern: (pymodule, pymethod, juliamodule, juliamethod)
# these don't need to be exported
# in SymPy we use getmembers to generate this; not sure what is better
#const
generic_methods = (
    (:_sympy_, :cos, :Base, :cos),
    (:_sympy_, :sin, :Base, :sin),
    (:_sympy_, :tan, :Base, :tan),
    (:_sympy_, :sec, :Base, :sec),
    (:_sympy_, :csc, :Base, :csc),
    (:_sympy_, :cot, :Base, :cot),
    (:_sympy_, :acos, :Base, :acos),
    (:_sympy_, :asin, :Base, :asin),
    #(:_sympy_, :atan, :Base, :atan), # need 2 arg version
    (:_sympy_, :asec, :Base, :asec),
    (:_sympy_, :acsc, :Base, :acsc),
    (:_sympy_, :acot, :Base, :acot),


    #
    (:_sympy_, :cosh,  :Base, :cosh),
    (:_sympy_, :sinh,  :Base, :sinh),
    (:_sympy_, :tanh,  :Base, :tanh),
    (:_sympy_, :sech,  :Base, :sech),
    (:_sympy_, :csch,  :Base, :csch),
    (:_sympy_, :coth,  :Base, :coth),
    (:_sympy_, :acosh, :Base, :acosh),
    (:_sympy_, :asinh, :Base, :asinh),
    (:_sympy_, :atanh, :Base, :atanh),
#    (:_sympy_, :asech, :Base, :asech),
#    (:_sympy_, :acsch, :Base, :acsch),
    (:_sympy_, :acoth, :Base, :acoth),
    #
    (:_sympy_, :sqrt, :Base, :sqrt),
    (:_sympy_, :exp,  :Base, :exp),
#    (:_sympy_, :log, :Base, :log),
    (:_sympy_, :factorial, :Base, :factorial),
    #
    (:_sympy_, :Mod,     :Base, :mod),
    (:_sympy_, :floor,   :Base, :floor),
    (:_sympy_, :ceiling, :Base, :ceil),
    #
    (:_sympy_, :numer, :Base, :numerator),
    (:_sympy_, :denom, :Base, :denominator),
    (:_sympy_, :Max,   :Base, :max),
    (:_sympy_, :Abs,   :Base, :abs),
    (:_sympy_, :Min,   :Base, :min),
    #
    (:_sympy_, :re,        :Base, :real),
    (:_sympy_, :im,        :Base, :imag),
    (:_sympy_, :transpose, :Base, :transpose),
    #
    (:_sympy_, :sign,  :Base, :sign),
    #
    (:_sympy_, :diff,  :Base, :diff),

    # solve
    (:_sympy_, :solve, :CommonSolve, :solve),

    # Eq
    (:_sympy_, :Eq, :CommonEq, :Eq),
    (:_sympy_, :Lt, :CommonEq, :Lt),
    (:_sympy_, :Le, :CommonEq, :Le),
    (:_sympy_, :Ne, :CommonEq, :Ne),
    (:_sympy_, :Ge, :CommonEq, :Ge),
    (:_sympy_, :Gt, :CommonEq, :Gt),


    # collect
    (:_sympy_, :collect, :Base, :collect),

    # SpecialFunctions
    (:_sympy_, :airyai ,      :SpecialFunctions, :airyai),
    (:_sympy_, :airyaiprime , :SpecialFunctions, :airyaiprime),
    (:_sympy_, :airybi ,      :SpecialFunctions, :airybi),
    #(:_sympy_, :besseli ,     :SpecialFunctions, :besseli),
    #(:_sympy_, :besselj ,     :SpecialFunctions, :besselj),
    #(:_sympy_, :besselk ,     :SpecialFunctions, :besselk),
    #(:_sympy_, :bessely ,     :SpecialFunctions, :bessely),
    (:_sympy_, :beta ,        :SpecialFunctions, :beta),
    (:_sympy_, :erf ,         :SpecialFunctions, :erf),
    (:_sympy_, :erfc ,        :SpecialFunctions, :erfc),
    (:_sympy_, :erfi ,        :SpecialFunctions, :erfi),
    (:_sympy_, :erfinv ,      :SpecialFunctions, :erfinv),
    (:_sympy_, :erfcinv ,     :SpecialFunctions, :erfcinv),
    (:_sympy_, :gamma ,       :SpecialFunctions, :gamma),
    (:_sympy_, :digamma ,     :SpecialFunctions, :digamma),
    (:_sympy_, :polygamma ,   :SpecialFunctions, :polygamma),
    (:_sympy_, :hankel1,      :SpecialFunctions, :hankelh1),
    (:_sympy_, :hankel2,      :SpecialFunctions, :hankelh2),
    (:_sympy_, :zeta ,        :SpecialFunctions, :zeta),
)

## --------------------------------------------------
# pmod, pmeth, meth
#const
# XXX how to document these things>
# XXX maybe move this to SymPyCore?
new_exported_methods = (
    #
    (:_sympy_, :simplify,    :simplify),
    (:_sympy_, :expand_trig, :expand_trig),
    (:_sympy_, :expand,      :expand),
    (:_sympy_, :together,    :together),
    (:_sympy_, :apart,       :apart),
    (:_sympy_, :factor,      :factor),
    (:_sympy_, :cancel,      :cancel),
    #
    (:_sympy_, :degree,      :degree),
    #
    (:_sympy_, :integrate,   :integrate),
    #
    (:_sympy_, :real_roots,  :real_roots),
    (:_sympy_, :roots,       :roots),
    (:_sympy_, :nroots,      :nroots),
    (:_sympy_, :dsolve,      :dsolve),
    (:_sympy_, :nsolve,      :nsolve),
    (:_sympy_, :linsolve,    :linsolve),
    (:_sympy_, :nonlinsolve, :nonlinsolve),
    (:_sympy_, :solveset,    :solveset),
    #
    (:_sympy_, :series,      :series),
    (:_sympy_, :summation,   :summation),
    (:_sympy_, :hessian,     :hessian),
    #
    (:_sympy_, :ask,         :ask),
    (:_sympy_, :refine,      :refine),
    #
    (:_sympy_, :Heaviside,   :Heaviside),
)

## --------------------------------------------------
# M.meth
matrix_meths = (
    (:adjoint, :Base, :adjoint),
    (:exp, :Base, :exp),
    (:inv, :Base, :inv),
    (:transpose, :Base, :transpose),
    (:det, :LinearAlgebra, :det),
    (:diag, :LinearAlgebra, :diag),
    #(:eigenvects, :LinearAlgebra, :eigvecs),
    #(:eigenvals, :LinearAlgebra, :eigvals),
    (:norm, :LinearAlgebra, :norm),
    (:pinv, :LinearAlgebra, :pinv),
    (:rank, :LinearAlgebra, :rank),
)

## --------------------------------------------------
object_methods = (
    (:conjugate, :Base, :conj),
)


## --------------------------------------------------
## Generate the methods
for (pmod, pmeth, jmod, jmeth) ∈ generic_methods
    @eval begin
        ($(jmod).$(jmeth))(x::Sym, args...; kwargs...) =
            ↑($(pmod).$(pmeth)(↓(x), ↓(args)...; ↓ₖ(kwargs)...))
    end
end

for (pmod, pmeth, jmeth) ∈ new_exported_methods
    @eval begin
        ($(jmeth))(x::Sym, args...; kwargs...) =
            ↑($(pmod).$(pmeth)(↓(x), ↓(args)...; ↓ₖ(kwargs)...))
        export $(jmeth)
    end
end

for (smeth, jmod, jmeth) ∈ matrix_meths
    @eval begin
        ($(jmod).$(jmeth))(M::Matrix{T}, args...; kwargs...) where {T <: Sym} =
            ↑(↓(M).$(smeth)(↓(args)...; ↓ₖ(kwargs)...))
    end
end

for (ometh, jmod, jmeth) ∈ object_methods
    @eval begin
        ($(jmod).$(jmeth))(x::Sym, args...; kwargs...) =
            ↑(↓(x).$(ometh)(↓(args)...; ↓ₖ(kwargs)...))
    end
end

## --------------------------------------------------
## Some trignometric functions which need PI defined

Base.sinpi(x::Sym) = sin(PI*x)
Base.cospi(x::Sym) = cos(PI*x)
Base.sinc(x::Sym) = iszero(x) ? one(x) : sinpi(x)/(PI*x)
Base.cosc(x::Sym) = cospi(x)/x - sinc(x)/x

Base.deg2rad(x::Sym) = x * PI/180
Base.rad2deg(x::Sym) = x * 180 /  PI

for fn ∈ (:sin,:cos, :tan, :sec, :csc, :cot)
    f = Symbol(string(fn) * "d")
    saf = Symbol("a" * string(fn))
    af = Symbol("a" * string(fn) * "d")
    @eval begin
        (Base.$f)(x::Sym)  = $(sympy).$(fn)(deg2rad(x))
        (Base.$af)(x::Sym) = rad2deg(($sympy).$(saf)(x))
    end
end


## Add methods for "solve functions"
for meth ∈ (:solve, :linsolve, :nonlinsolve, :nsolve, :dsolve)
    m = Symbol(meth)
    @eval begin
        ($meth)(V::AbstractArray{T,N}, args...; kwargs...) where {T <: SymbolicObject, N} =
            ↑(_sympy_.$meth(↓(V), ↓(args)...; ↓ₖ(kwargs)...))
        ($meth)(Ts::NTuple{N,T}, args...; kwargs...) where {N, T <: SymbolicObject} =
            sympy.$meth(Ts, args...; kwargs...)
        ($meth)(Ts::Tuple, args...; kwargs...) =
            sympy.$meth(Ts, args...; kwargs...)
    end
end
