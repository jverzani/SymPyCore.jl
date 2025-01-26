"""
    symtype(x=Sym(1))

Return `Sym{T}` for `T` being the uderlying Python type of `x`.
"""
symtype(x::SymbolicObject{T}=Sym(1)) where {T} = Sym{T}
export symtype



# Math and other functions that don't fit metaprogramming pattern
Base.log(x::Sym) = sympy.log(x) # generated method confuses two argument form
Base.log(n::Number, x::Sym) = sympy.log(x, n) # Need to switch order here
Base.log(n::Sym{T}, x::Sym{T}) where {T} = sympy.log(x, n) # Need to switch order here
Base.log2(x::SymbolicObject)  = sympy.log(x, Sym(2)) # sympy.log has different order
Base.log10(x::SymbolicObject) = sympy.log(x, Sym(10)) # sympy.log has different order
Base.atan(x::Sym) = sympy.atan(x) # generated method confuses two argument form
Base.atan(x::Sym, y) = sympy.atan2(x, y)
Base.angle(z::Sym) = atan(imag(z), real(z))
Base.binomial(a::Sym, b::Sym) = sympy.binomial(a, b)
function limit(ex::Sym, xc::Pair; kwargs...) # allow pairs
    sympy.limit(↓(ex), Sym(first(xc)), Sym(last(xc)); kwargs...)
end
Base.xor(x::Sym, y::Sym) = ↑(_sympy_.Xor(↓(x), ↓(y)))
Base.div(x::Sym, y::Sym) = ↑(first(_sympy_.div(↓(x), ↓(y))))
Base.rem(x::Sym, y::Sym) = ↑(_sympy_.rem(↓(x), ↓(y)))

SpecialFunctions.beta(a::Sym, b::Sym) = sympy.beta(a,b)

SpecialFunctions.besseli(n::Number, b::Sym) = sympy.besseli(n, b)

SpecialFunctions.besselj(n::Number, b::Sym) = sympy.besselj(n, b)
SpecialFunctions.besselj0(b::Sym) = sympy.besselj(0, b)
SpecialFunctions.besselj1(b::Sym) = sympy.besselj(1, b)

SpecialFunctions.besselk(n::Number, b::Sym) = sympy.besselk(n, b)

SpecialFunctions.bessely(n::Number, b::Sym) = sympy.bessely(n, b)
SpecialFunctions.bessely0(b::Sym) = sympy.bessely(n, b)
SpecialFunctions.bessely1(b::Sym) = sympy.bessely(n, b)

# no besselix, besseljx, besselkx, or besselyx


# CommonEq
CommonEq.Lt(a::T,b::T) where {T <: SymbolicObject} = sympy.Lt(a,b)
CommonEq.Le(a::T,b::T) where {T <: SymbolicObject} = sympy.Le(a,b)
CommonEq.Eq(a::T,b::T) where {T <: SymbolicObject} = sympy.Eq(a,b)
CommonEq.Ne(a::T,b::T) where {T <: SymbolicObject} = sympy.Ne(a,b)
CommonEq.Ge(a::T,b::T) where {T <: SymbolicObject} = sympy.Ge(a,b)
CommonEq.Gt(a::T,b::T) where {T <: SymbolicObject} = sympy.Gt(a,b)

LinearAlgebra.norm(x::AbstractVector{T}, args...; kwargs...) where {T <: SymbolicObject} =
    ↑(getproperty(sympy.Matrix(Tuple(xᵢ for xᵢ ∈ x)), :norm)(↓(args)...; ↓ₖ(kwargs)...))

function dsolve(eqn, args...;
                ics::Union{Nothing, AbstractDict, Tuple}=nothing,
                kwargs...)
    sympy.dsolve(eqn, args...; ics=ics, kwargs...)
end


SymPyCore.Wild(x::AbstractString) = sympy.Wild(string(x))

function Permutation(x...; kwargs...)
    if typeof(x) <: UnitRange
        x = collect(x)
    end
    # should do this _check_permutation_format(x)
    # call this way to avoid ↓(x) call
    Sym(_combinatorics_.permutations.Permutation(x...; kwargs...))
end
PermutationGroup(args...; kwargs...) = combinatorics.PermutationGroup(args...; kwargs...)

# Introspection, assumptions use a struct to imitate old use of module; we pass in _sympy_
@doc SymPyCore.Introspection_docs Introspection = SymPyCore.Introspection(_sympy_ = _sympy_) # introspection

# 𝑄 alternative to sympy.Q (maybe unnecessary)
#@doc SymPyCore.Q_docs
#𝑄 = sympy.Q #SymPyCore.𝑄(_sympy_=_sympy_)

function SymPyCore.ask(x::Sym)
    u = sympy.ask(x)
    return SymPyCore.Bool3(u)
    #return convert(SymPyCore.Bool3, u)
end

# lambdify using use_julia_code (`sympy` not available in `lambify.jl`)
function SymPyCore._convert_expr(use_julia_code::Val{true}, ex; kwargs...)
    Meta.parse(string(_sympy_.julia_code(↓(ex))))
end

function SymPyCore.julia_code(ex; kwargs...)
    str = string(_sympy_.julia_code(↓(ex)))
    str = replace(str, ".*" => "*", ".^" => "^")
    Meta.parse(str)
end


# deprecations
import Base: collect
Base.@deprecate collect(x::SymbolicObject, args...; kwargs...) sympy.collect(x, args...; kwargs...)
