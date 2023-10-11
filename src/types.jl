##################################################
## SymbolicObject types have field x::PyCall.PyObject

## Symbol class for controlling dispatch
abstract type SymbolicObject{T} <: Number end

import Base: ==
function Base.:(==)(x::SymbolicObject, y::SymbolicObject)
    if hasproperty(↓(x), "is_Boolean") && convert(Bool, ↑(↓(x).is_Boolean))
        u = convert(Bool, x)
        v=convert(Bool, y)
        return u==v
    end

    if hasproperty(↓(x), "equals")
        u = x.equals(y)
        return convert(Bool, u == Sym(true))
    else
        return (hash(x) == hash(y))
    end
end


# SymPy.symbols constructor
# must be implemented in SymPyPyCall or SymPyPythonCall
"""
    symbols(arg; kwargs...)

Construct symbolic values using `sympy.symbols`.
"""
symbols() = nothing

## --------------------------------------------------
## Sym Main type

"""
    Sym{T}

Main wrapper for symbolic Python objects.

This is useful for dispatching methods for generic functions. `Sym` is also used to make symbolic values, in particular numeric values can be made into symbolic values.
"""
struct Sym{T} <: SymbolicObject{T}
    o::T
end
Sym(s::SymbolicObject) = s
Sym(x::Symbol) = Sym(string(x))
Sym(xs::Symbol...) = Tuple(Sym.((string(x) for x in xs)))
Sym{T}(x::Sym{T}) where {T} = x
Sym(x::Rational{T}) where {T} = Sym(numerator(x))/Sym(denominator(x))
# containers
Sym(x::Tuple) = Tuple(Sym(xᵢ) for xᵢ ∈ x)
Sym(x::Vector) = Sym[Sym(xᵢ) for xᵢ ∈ x]



Base.collect(s::Sym) = Sym.(collect(↓(s)))

## --------------------------------------------------

"""
    SymFunction

A type and constructor to create symbolic functions. Such objects can be used
for specifying differential equations. The macro [`@syms`](@ref) is also available for constructing `SymFunction`s (`@syms f()`)

## Examples:

```julia jldoctest symfunction
julia> using SymPyPythonCall

julia> @syms v(); # recommended way to create a symbolic function

julia> u = SymFunction("u") # alternate

```

## Extended help

For symbolic functions *not* wrapped in the `SymFunction` type, the `sympy.Function` constructor can be used, as can the [`symbols`](@ref) function to construct symbolic functions (`F=sympy.Function("F", real=true)`; `F = sympy.symbols("F", cls=sympy.Function, real=true)`).

```julia jldoctest symfunction
julia> @syms u(), v()::real, t
(u, v, t)

julia> sqrt(u(t)^2), sqrt(v(t)^2) # real values have different simplification rules
(sqrt(u(t)^2), Abs(v(t)))

```

Such functions are undefined functions in SymPy, and can be used symbolically, such as with taking derivatives:

```julia jldoctest symfunction
julia> @syms x y u()
(x, y, u)

julia> diff(u(x), x) |> string
"Derivative(u(x), x)"

julia> diff(u(x, y), x) |> string
"Derivative(u(x, y), x)"
```


Here is one way to find the second derivative of an inverse function to `f`, utilizing the `SymFunction` class and the convenience `Differential` function:

```
@syms f() f⁻¹() x
D = Differential(x) # ∂(f) is diff(f(x),x)
D² = D∘D
u1 = only(solve(D((f⁻¹∘f)(x))  ~ 1, D(f⁻¹)(f(x))))
u2 = only(solve(D²((f⁻¹∘f)(x)) ~ 0, D²(f⁻¹)(f(x))))
u2(D(f⁻¹)(f(x)) => u1) # f''/[f']^3
```

"""
struct SymFunction{T} <: SymbolicObject{T}
    o::T
end
(F::SymFunction)(x) = ↑(↓(F)(↓(x)))

## --------------------------------------------------

## Matrices
## We use this class for `ImmutableMatrices`
## Mutable matrices are mapped to `AbstractArray{Sym,N}`
## cf. matrix.jl
# """
#     SymMatrix

# Type to store a SymPy matrix, as created by `sympy.ImmutableMatrix`.

# These have 0-based indexing defined for them to match SymPy

# The traditional infix mathmatical operations are defined, but no dot broadcasting.

# The `convert(Matrix{Sym}, M)` call is useful to covert to a Julia matrix

# """
# mutable struct SymMatrix{T} <: SymbolicObject{T}
#     o::T
# end

# ## --------------------------------------------------

# ## Permutations
# ## A permutation of {0, 1, 2, ..., n} -- 0-based
# struct SymPermutation{T} <: SymbolicObject{T}
#     o::T
# end
# Base.convert(::Type{SymPermutation}, o) = SymPermutation(o)


# ## A permutation of {0, 1, 2, ..., n} -- 0-based
# struct SymPermutationGroup{T} <: SymbolicObject{T}
#     p::T
# end
# Base.convert(::Type{SymPermutationGroup}, o) = SymPermutationGroup(o)

## --------------------------------------------------
#XXX
# a Lambda function
# struct Lambda{T} <: SymbolicObject
#     o::T
# end
# Lambda(args, expression) = Lambda(sympy.Lambda(args, expression).__pyobject__)
# (λ::Lambda)(args...; kwargs...) = λ.__pyobject__(args...; kwargs...)
# export Lambda

#=

##################################################

## important override
## this allows most things to flow though PyCall
PyCall.PyObject(x::SymbolicObject) = x.__pyobject__
## Override this so that using symbols as keys in a dict works
function Base.hash(x::SymbolicObject, h::UInt)
    o = PyObject(x)
    px = ccall((PyCall.@pysym :PyObject_Hash), PyCall.Py_hash_t, (PyCall.PyPtr,), o) # from PyCall.jl
    reinterpret(UInt, Int(px)) - 3h                                                  # from PythonCall.jl
end
#hash(x::SymbolicObject) = hash(PyObject(x))
==(x::SymbolicObject, y::SymbolicObject) = PyObject(x) == PyObject(y)

##################################################


## Show methods
"create basic printed output"
function jprint(x::SymbolicObject)
    out = PyCall.pycall(pybuiltin("str"), String, PyObject(x))
    out = replace(out, r"\*\*" => "^")
    out
end
jprint(x::AbstractArray) = map(jprint, x)

## text/plain
Base.show(io::IO, s::Sym) = print(io, jprint(s))
Base.show(io::IO, ::MIME"text/plain", s::SymbolicObject) =  print(io, sympy.pretty(s))

## latex enhancements: Sym, array, Dict
#Base.show(io::IO, ::MIME"text/latex", x::SymbolicObject) = print(io, sympy.latex(x, mode="equation*"))

as_markdown(x) = Markdown.parse("``$x``")
function Base.show(io::IO, ::MIME"text/latex", x::SymbolicObject)
    print(io, sympy.latex(x, mode="inline",fold_short_frac=false)) # plain? equation*?
#    #print(io, as_markdown(sympy.latex(x, mode="equation*")))
#    #print(io, as_markdown(sympy.latex(x, mode="plain",fold_short_frac=false))) # inline?
end
function  show(io::IO, ::MIME"text/latex", x::AbstractArray{Sym})
    function toeqnarray(x::Vector{Sym})
        a = join([sympy.latex(x[i]) for i in 1:length(x)], "\\\\")
        """\\left[ \\begin{array}{r}$a\\end{array} \\right]"""
#        "\\begin{bmatrix}$a\\end{bmatrix}"
    end
    function toeqnarray(x::AbstractArray{Sym,2})
        sz = size(x)
        a = join([join(map(sympy.latex, x[i,:]), "&") for i in 1:sz[1]], "\\\\")
        "\\left[ \\begin{array}{" * repeat("r",sz[2]) * "}" * a * "\\end{array}\\right]"
#        "\\begin{bmatrix}$a\\end{bmatrix}"
    end
    print(io, as_markdown(toeqnarray(x)))
end
function show(io::IO, ::MIME"text/latex", d::Dict{T,S}) where {T<:SymbolicObject, S<:Any}
    Latex(x::Sym) = sympy.latex(x)
    Latex(x) = sprint(io -> show(IOContext(io, :compact => true), x))

    out = "\\begin{equation*}\\begin{cases}"
    for (k,v) in d
        out = out * Latex(k) * " & \\text{=>} &" * Latex(v) * "\\\\"
    end
    out = out * "\\end{cases}\\end{equation*}"
    print(io, as_markdown(out))
end

latex(x::Sym) = sympy.latex(x)

# (this is used by Polynomials.jl)
function Base.show_unquoted(io::IO, pj::SymbolicObject, indent::Int, prec::Int)
    if Base.operator_precedence(:+) <= prec
        print(io, "(")
        show(io, pj)
        print(io, ")")
    else
        show(io, pj)
    end
end



## Following recent changes to PyCall where:
# For o::PyObject, make o["foo"], o[:foo], and o.foo equivalent to o.foo in Python,
# with the former returning an raw PyObject and the latter giving the PyAny
# conversion.
# We do something similar to SymPy
#
# We only implement for symbols here, not strings
function Base.getproperty(o::T, s::Symbol) where {T <: SymbolicObject}
    if (s in fieldnames(T))
        getfield(o, s)
    else
        getproperty(PyCall.PyObject(o), s)
    end
end

# XXX Needs version v1.2+
#function Base.hasproperty(o::T, s::Symbol) where {T <: SymbolicObject}
#    s ∈ fieldnames(T) && return true
#    hasproperty(PyCall.PyObject(o), s)
#end

=#
