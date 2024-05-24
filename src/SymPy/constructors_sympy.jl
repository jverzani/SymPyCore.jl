## constructors

Sym(x::AbstractString) = ↑(_sympy_.symbols(x))
Sym(x::Number) = ↑(_sympy_.sympify(x)) # slower that Sym(Py(x)), but more idiomatic
Sym(x::Irrational{:π}) = PI
Sym(x::Irrational{:ℯ}) = E
Sym(x::Irrational{:φ}) = (1 + sqrt(Sym(5))) / 2
Sym(x::Rational) = ↑(_sympy_.Rational(numerator(x), denominator(x)))
function Sym(x::Complex{Bool})
    !x.re &&  x.im && return IM
    !x.re && !x.im && return Sym(0)
     x.re && !x.im && return Sym(1)
     x.re &&  x.im && return Sym(1) + IM
end
Sym(x::Complex{T}) where {T} = Sym(real(x)) + Sym(imag(x)) * IM

# workaround to get inferrability
Sym{P}(x::AbstractString) where {P} = ↑(_sympy_.symbols(x))::Sym{P}
Sym{P}(x::Number) where {P} = Sym{P}(_sympy_.sympify(x))::Sym{P} # slower that Sym(Py(x)), but more idiomatic
Sym{P}(x::Irrational{:π}) where {P} = PI::Sym{P}
Sym{P}(x::Irrational{:ℯ}) where {P} = E::Sym{P}
Sym{P}(x::Irrational{:φ}) where {P} = ((1 + sqrt(Sym{P}(5))) / 2)::Sym{P}
Sym{P}(x::Rational) where {P} = Sym{P}(_sympy_.Rational(numerator(x), denominator(x)))::Sym{P}
function Sym{P}(x::Complex{Bool}) where {P}
    !x.re &&  x.im && return IM
    !x.re && !x.im && return Sym{P}(0)
     x.re && !x.im && return Sym{P}(1)
     x.re &&  x.im && return Sym{P}(1) + IM
end
Sym{P}(x::Complex{T}) where {P,T} = Sym{P}(real(x)) + Sym{P}(imag(x)) * IM

## ---

sympify(x; kwargs...) = ↑(_sympy_.sympify(x; kwargs...))

# ↓ for Vector, Matrix we convert to a matrix
import SymPyCore: ↓
(↓)(x::Vector{<:Sym}) = _sympy_.Matrix(Tuple(map(↓, reshape(x, length(x), 1))))
function (↓)(M::AbstractMatrix{<:Sym})
    _sympy_.Matrix(Tuple(map(↓, Mᵢ) for Mᵢ ∈ eachrow(M)))
end

function Base.getproperty(M::AbstractArray{<:Sym, N}, prop::Symbol) where {N} #XX array or Matrix?
    if prop in fieldnames(typeof(M))
        return getfield(M, prop)
    end
    getproperty(Sym(↓(M)), prop)
end

## ----

function symbols(args...; kwargs...)
    as =  _sympy_.symbols(args...; kwargs...)
    hasproperty(as, :__iter__) && return Tuple((↑)(xᵢ) for xᵢ ∈ as)
    return ↑(as)
end

function SymFunction(x::AbstractString; kwargs...)
    xs = split(x, r",\s*")
    length(xs) > 1 ?  _SymFunction.(xs; kwargs...) : _SymFunction(only(xs); kwargs...)
end

function _SymFunction(x; kwargs...)
    out = _sympy_.Function(x; kwargs...)
    SymPyCore.SymFunction(out)
end

macro syms(xs...)
    # If the user separates declaration with commas, the top-level expression is a tuple
    if length(xs) == 1 && isa(xs[1], Expr) && xs[1].head == :tuple
        SymPyCore._gensyms(xs[1].args...)
    elseif length(xs) > 0
        SymPyCore._gensyms(xs...)
    end
end
