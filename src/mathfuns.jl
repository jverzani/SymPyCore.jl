## Implement Julia math functions not
## easily implemented in gen_methods list
## https://github.com/SimonDanisch/AbstractNumbers.jl provides
## a useful list of targeted functions

Base.eps(::Type{<:Sym}) = 0
Base.rtoldefault(::Type{<:Sym}) = 0

Base.float(x::Sym) = _float(N(x))
_float(x::Sym) = throw(ArgumentError("variable must have no free symbols"))
_float(x) = float(x)

Base.Float64(x::Sym) = _Float64(N(x))
_Float64(x::Sym) = throw(ArgumentError("variable must have no free symbols"))
_Float64(x) = Float64(x)

function Base.Int(x::Sym)
    if x.is_integer == true
        abs(x) <= typemax(Int) && return convert(Int, ↓(x))
        return convert(BigInt, ↓(x))
    end
    convert(Int, ↓(x.evalf()))
end

Base.complex(::Type{Sym}) = Sym
Base.complex(r::Sym) = real(r) + imag(r) * im
function Base.complex(r::Sym, i)
    isreal(r) || throw(ArgumentError("r and i must not be complex"))
    isreal(i) || throw(ArgumentError("r and i must not be complex"))
    N(r) + N(i) * im
end
Base.complex(xs::AbstractArray{Sym}) = complex.(xs) # why is this in base?



Base.abs2(x::SymbolicObject) = x * conj(x)
Base.cbrt(x::Sym) = x^(1//3)

## Trig
Base.asech(z::Sym) = log(sqrt(1/z-1)*sqrt(1/z+1) + 1/z)
Base.acsch(z::Sym) = log(sqrt(1+1/z^2) + 1/z) ## http://mathworld.wolfram.com/InverseHyperbolicCosecant.html

Base.sincos(x::Sym) = (sin(x), cos(x))

Base.hypot(x::Sym, y::Number) = hypot(promote(x,y)...)
Base.hypot(xs::Sym...) = sqrt(sum(abs(xᵢ)^2 for xᵢ ∈ xs))

## exponential
Base.expm1(x::Sym) = exp(x) - 1
Base.exp2(x::Sym)  = Sym(2)^x
Base.exp10(x::Sym) = Sym(10)^x
Base.log1p(x::Sym) = log(1 + x)
#Base.log(b::Number, x::Sym) = log(x, b) # sympy.log has different order
function Base.frexp(x::Sym)
    n = ceil(log2(x))
    r = x/2^n
    (r, n)
end
Base.ldexp(x::Sym, n) = x * Sym(2)^n
function Base.modf(x::Sym)
    isinf(x) && return (copysign(zero(T), x), x)
    ix = trunc(x)
    rx = copysign(x - ix, x)
    return (rx, ix)
end

Base.iseven(x::Sym) = x.is_even
Base.isodd(x::Sym) = x.is_odd
function Base.ispow2(x::Sym)
    a = x.is_integer
    a == true && return ispow2(N(x))
    a
end

Base.trunc(x::Sym) = x.is_Number != true ? x :
    (x.is_positive == true) ? floor(x) : ceil(x)
Base.isfinite(x::Sym) = x.is_finite == true
Base.isinf(x::Sym) = x.is_infinite == true
Base.isinteger(x::Sym) = x.is_integer == true
Base.isreal(x::Sym) = x.is_real == true
Base.isnan(x::Sym) = _convert(Bool, ↓(x) == ↓(Sym(NaN)))
Base.copysign(x::Sym, y::Sym) = abs(x)*sign(y)
Base.flipsign(x::Sym, y) = isless(y, 0) ? -x : x
Base.fld(x::Sym, y::Sym) = floor(x / y)
Base.clamp(x::Sym, a, b) = min(max(x, a), b)
Base.divrem(x::Sym, y::Sym) = (div(x,y), rem(x,y))


## --------------------------------------------------
# sets
Base.in(x::Sym, I::Sym) = I.contains(x) == Sym(true)
Base.in(x::Number, I::Sym) = Sym(x) in I
Base.intersect(x::Sym, args...; kwargs...) = x.intersect(args...; kwargs...)
Base.union(x::Sym, args...; kwargs...) = x.union(args...; kwargs...)
Base.issubset(x::Sym, args...; kwargs...) = x.issubset(args...; kwargs...)


## --------------------------------------------------
## calculus.
## use a pair for limit x=>0
limit(x::SymbolicObject, xc::Pair, args...;kwargs...) = limit(x, xc[1], xc[2], args...;kwargs...)

# Steal this idea from ModelingToolkit
"""
    Differential(x)

Use to find (partial) derivatives.

## Example
```
@syms x y u()
Dx = Differential(x)
Dx(u(x,y))  # resolves to diff(u(x,y),x)
Dx(u)       # will evaluate diff(u(x), x)
```
"""
struct Differential
    x::Sym
end
(∂::Differential)(u::Sym) = diff(u, ∂.x)
(∂::Differential)(u::SymFunction) = diff(u(∂.x), ∂.x)


## Add interfaces for solve, nonlinsolve when vector of equations passed in

## An alternative to Eq(lhs, rhs) following Symbolics.jl
"""
    lhs ~ rhs

Specify an equation.

Alternative syntax to `Eq(lhs, rhs)` or `lhs ⩵ rhs` (`\\Equal[tab]`). Notation borrowed from `Symbolics.jl`.

See [`rhs`](@ref) or `lhs` to extract the two sides.

Inequalities may be defined using other functions imported from `CommonEq`.
"""
Base.:~(lhs::Number, rhs::SymbolicObject) = Eq(lhs, rhs)
Base.:~(lhs::SymbolicObject, rhs::Number) = Eq(lhs, rhs)
Base.:~(lhs::SymbolicObject, rhs::SymbolicObject) = Eq(lhs, rhs)


"""
    solve

Use `solve` to solve algebraic equations.

# Extended help

Examples:

```jldoctest mathfuns
julia> using SymPyPythonCall


julia> @syms x y a b c d
(x, y, a, b, c, d)

julia> solve(x^2 + 2x + 1, x) # [-1]
1-element Vector{Sym{PythonCall.Py}}:
 -1

julia> solve(x^2 + 2a*x + a^2, x) # [-a]
1-element Vector{Sym{PythonCall.Py}}:
 -a

julia> u = solve([a*x + b*y-3, c*x + b*y - 1], [x,y]); show(u[x])
2/(a - c)
```

!!! note
    A very nice example using `solve` is a [blog](https://newptcai.github.io/euclidean-plane-geometry-with-julia.html) entry on [Napoleon's theorem](https://en.wikipedia.org/wiki/Napoleon%27s_theorem) by Xing Shi Cai.

!!! note "Systems"
    Use a tuple, not a vector, of equations when there is more than one.

"""
solve() = nothing

## dsolve allowing initial condiation to be specified

"""
    dsolve(eqn, var, args..,; ics=nothing, kwargs...)

Calls `sympy.dsolve`.

ics: The initial conditions are specified with a dictionary or `nothing`

# Extended help

Example:

```jldoctest dsolve
julia> using SymPyPythonCall

julia> @syms α, x, f(), g()
(α, x, f, g)

julia> ∂ = Differential(x)
Differential(x)

julia> eqn = ∂(f(x)) ~ α * x; show(eqn)
Eq(Derivative(f(x), x), x*α)
```

```jldoctest dsolve
julia> dsolve(eqn) |> show
Eq(f(x), C1 + x^2*α/2)
```

```julia jldoctest dsolve
julia> dsolve(eqn(α=>2); ics=Dict(f(0)=>1))
        2
f(x) = x  + 1

julia> eqn = ∂(∂(f(x))) ~ -f(x);

julia> dsolve(eqn)
f(x) = C₁⋅sin(x) + C₂⋅cos(x)

julia> dsolve(eqn; ics = Dict(f(0)=>1, ∂(f)(0) => -1))
f(x) = -sin(x) + cos(x)

julia> eqn = ∂(∂(f(x))) - f(x) - exp(x);

julia> dsolve(eqn, ics=Dict(f(0) => 1, f(1) => Sym(1//2))) |> show
Eq(f(x), (x/2 + (-exp(2) - 2 + E)/(-2 + 2*exp(2)))*exp(x) + (-E + 3*exp(2))*exp(-x)/(-2 + 2*exp(2)))
```

!!! note "Systems"
    Use a tuple, not a vector, of equations when there is more than one.

```julia jldoctest dsolve
julia> @syms x() y() t g
(x, y, t, g)

julia> ∂ = Differential(t)
Differential(t)

julia> eqns = (∂(x(t)) ~ y(t), ∂(y(t)) ~ x(t));

julia> dsolve(eqns)
2-element Vector{Sym{PythonCall.Py}}:
 Eq(x(t), -C1*exp(-t) + C2*exp(t))
  Eq(y(t), C1*exp(-t) + C2*exp(t))

julia> dsolve(eqns, ics = Dict(x(0) => 1, y(0) => 2))
2-element Vector{Sym{PythonCall.Py}}:
 Eq(x(t), 3*exp(t)/2 - exp(-t)/2)
 Eq(y(t), 3*exp(t)/2 + exp(-t)/2)

julia> eqns = (∂(∂(x(t))) ~ 0, ∂(∂(y(t))) ~ -g)
(Eq(Derivative(x(t), (t, 2)), 0), Eq(Derivative(y(t), (t, 2)), -g))

julia> dsolve(eqns)  # can't solve for initial conditions though! (NotAlgebraic)
2-element Vector{Sym{PythonCall.Py}}:
           x(t) = C₁ + C₂⋅t
 Eq(y(t), C3 + C4*t - g*t^2/2)

julia> @syms t x() y()
(t, x, y)

julia> eq = (∂(x)(t) ~ x(t)*y(t)*sin(t), ∂(y)(t) ~ y(t)^2 * sin(t));
```

```julia
julia> dsolve(eq)
Set{Sym{PythonCall.Py}} with 2 elements:
  Eq(x(t), -exp(C1)/(C2*exp(C1) - cos(t)))
  Eq(y(t), -1/(C1 - cos(t)))
```

"""
dsolve() = nothing

rhs(x::SymbolicObject) = x.rhs()
lhs(x::SymbolicObject) = x.lhs()

"""
    rhs(eqn)
    lhs(eqn)

Returns right (or left) side of an equation object. Wrappers around `eqn.rhs()` and `eqn.lhs()`.
"""
rhs, lhs


## --------------------------------------------------
Permutation() = nothing
PermutationGroup() = nothing

"""
    Permutation
    PermutationGroup

Give access to the `sympy.combinatorics.permutations` module

## Example
```jldoctest permutation
julia> using SymPyPythonCall

julia> p = Permutation([1,2,3,0])
(0 1 2 3)

julia> p^2
(0 2)(1 3)

julia> p^2 * p^2
()
```

Rubik's cube example from SymPy documentation

```jldoctest permutation
julia> F = Permutation([(2, 19, 21, 8),(3, 17, 20, 10),(4, 6, 7, 5)])
(2 19 21 8)(3 17 20 10)(4 6 7 5)

julia> R = Permutation([(1, 5, 21, 14),(3, 7, 23, 12),(8, 10, 11, 9)])
(1 5 21 14)(3 7 23 12)(8 10 11 9)

julia> D = Permutation([(6, 18, 14, 10),(7, 19, 15, 11),(20, 22, 23, 21)])
(6 18 14 10)(7 19 15 11)(20 22 23 21)

julia> G = PermutationGroup(F,R,D);

julia> G.order()
3674160
```
"""
Permutation, PermutationGroup
