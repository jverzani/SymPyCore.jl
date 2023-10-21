##################################################
## SymbolicObject types have field x::PyCall.PyObject

## Symbol class for controlling dispatch
abstract type SymbolicObject{T} <: Number end




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
_pytype(::Sym{T}) where {T} = T


Base.collect(s::Sym) = Sym.(collect(↓(s)))

## --------------------------------------------------

"""
    SymFunction

A type and constructor to create symbolic functions. Such objects can be used
for specifying differential equations. The macro [`@syms`](@ref) is also available for constructing `SymFunction`s (`@syms f()`)

## Examples:

```jldoctest symfunction
julia> using SymPyPythonCall

julia> @syms t, v(); # recommended way to create a symbolic function

julia> u = SymFunction("u") # alternate
u

julia> diff(v(t), t) |> show
Derivative(v(t), t)
```

## Extended help

For symbolic functions *not* wrapped in the `SymFunction` type, the `sympy.Function` constructor can be used, as can the [`symbols`](@ref) function to construct symbolic functions (`F=sympy.Function("F", real=true)`; `F = sympy.symbols("F", cls=sympy.Function, real=true)`).

```jldoctest symfunction
julia> @syms u(), v()::real, t
(u, v, t)

julia> sqrt(u(t)^2), sqrt(v(t)^2) # real values have different simplification rules
(sqrt(u(t)^2), Abs(v(t)))

```

Such functions are undefined functions in SymPy, and can be used symbolically, such as with taking derivatives:

```jldoctest symfunction
julia> @syms x y u()
(x, y, u)

julia> diff(u(x), x) |> show
Derivative(u(x), x)

julia> diff(u(x, y), x) |> show
Derivative(u(x, y), x)
```


Here is one way to find the second derivative of an inverse function to `f`, utilizing the `SymFunction` class and the convenience `Differential` function:

```jldoctest symfunction
julia> @syms f() f⁻¹() x;

julia> D = Differential(x) # ∂(f) is diff(f(x),x)
Differential(x)

julia> D² = D∘D
Differential(x) ∘ Differential(x)

julia> u1 = only(solve(D((f⁻¹∘f)(x))  ~ 1, D(f⁻¹)(f(x)))); show(u1)
1/Derivative(f(x), x)

julia> u2 = only(solve(D²((f⁻¹∘f)(x)) ~ 0, D²(f⁻¹)(f(x)))); show(u2)
-Derivative(f(x), (x, 2))*Derivative(f⁻¹(f(x)), f(x))/Derivative(f(x), x)^2

julia> u2(D(f⁻¹)(f(x)) => u1) |> show # f''/[f']^3
-Derivative(f(x), (x, 2))/Derivative(f(x), x)^3
```

"""
struct SymFunction{T} <: SymbolicObject{T}
    o::T
end
(F::SymFunction)(xs...) = ↑(↓(F)(↓(xs)...))

## --------------------------------------------------
## XXX resurect?
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
