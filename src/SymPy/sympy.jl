## Common code

using LinearAlgebra
import CommonEq
import CommonSolve
import SpecialFunctions

#=
Several functions are exported

* generic functions in base `Julia` having a `sympy` counterpart have
  methods defined to dispatch on the first argument. (Basically,
  `Base.sin(x::Sym) = \uparrow(_sympy_.sin(\downarrow(x))`.) These are
  defined in the `generic_methods` list in `SymPyCore` and read in via
  the package once a Python bridge is in place.

* Some object methods, such as `ex.subs(...)` have exported functions
  that use the `Julian` order `subs(ex, ...)`. All object methods
  should be callable using the python syntax `obj.method(...)`.

* Functions in `sympy` that are foundational (e.g., `simplify`) have
  methods created dispatch on the first argument being symbolic
  (typically type `Sym`). These are exported. Other functions, e.g.,
  `trigsimp` may be called via `sympy.trigsimp(...)`.
=#

## import/exports
import SymPyCore: ↑, ↓, ↓ₖ
import SymPyCore: SymbolicObject, Sym, SymFunction
import SymPyCore: symbols, free_symbols
import SymPyCore: solve
import SymPyCore: subs, lambdify
import SymPyCore: ask
import SymPyCore: N
import SymPyCore: Differential, Wild
import SymPyCore: rhs, lhs
#import SymPyCore: ∨, ∧, ¬  # infix logical operators

# more exports defined in SymPyCore/src/gen_methods_sympy
export Sym, SymFunction
export sympy, PI, E, IM, oo, zoo, TRUE, FALSE
export @syms, sympify, symbols, free_symbols
export simplify, expand_trig, expand, together, apart, factor, cancel
export solve, dsolve, nsolve, linsolve, nonlinsolve, solveset
export real_roots, roots, nroots
export limit, integrate
export degree, sign
export series, summation, hessian
export subs, lambdify
export refine, ask
export N
export limit, diff, integrate, Differential, Heaviside
export rhs, lhs
export Wild, cse
export Permutation, PermutationGroup
#export ∨, ∧, ¬
export 𝑄, 𝑆, Introspection

export _sympy_, ↓, ↑ # remove later; for development only

# emacs and indent; this goes last
import SymPyCore: Lt, ≪, Le, ≦, Eq, ⩵, Ne, ≶, ≷, Ge, ≫, Gt, ≧
export  Lt, ≪, Le, ≦, Eq, ⩵, Ne, ≶, ≷, Ge, ≫, Gt, ≧

const _sympy_core_  = _pynull()

# exported symbols and their python counterparts
const _sympy_  = _pynull()
const sympy = Sym(_sympy_)

const _combinatorics_ = _pynull()
const combinatorics = Sym(_combinatorics_)

const _PI_ =_pynull()
const PI = Sym(_PI_)

const _E_ =_pynull()
const E = Sym(_E_)

const _IM_ =_pynull()
const IM = Sym(_IM_)

const _oo_ =_pynull()
const oo = Sym(_oo_)

const _zoo_ =_pynull()
const zoo = Sym(_zoo_)

const _TRUE_ =_pynull()
const TRUE = Sym(_TRUE_)

const _FALSE_ =_pynull()
const FALSE = Sym(_FALSE_)

const _𝑆_ = _pynull()
const 𝑆 = Sym(_𝑆_)

function __init__()

    ## Define sympy, mpmath, ...
    _copy!(_sympy_, _pyimport_conda("sympy", "sympy"))
    _copy!(_sympy_core_, _pyimport("sympy.core"))
    _copy!(_combinatorics_, _pyimport_conda("sympy.combinatorics", "sympy"))

    _copy!(_PI_, _sympy_.pi)
    _copy!(_E_, _sympy_.E)
    _copy!(_IM_, _sympy_.I)
    _copy!(_oo_, _sympy_.oo)
    _copy!(_zoo_, _sympy_.zoo)
    _copy!(_𝑆_, _sympy_.S)
    _copy!(_TRUE_, _pyobject(true))
    _copy!(_FALSE_, _pyobject(false))

    # pytypemapping
    basictype = _sympy_core_.basic.Basic
    _pytype_mapping(basictype, Sym)


end



# includes
core_src_path = joinpath(pathof(SymPyCore), "../../src/SymPy")
include(joinpath(core_src_path, "constructors_sympy.jl"))
include(joinpath(core_src_path, "gen_methods_sympy.jl"))
include(joinpath(core_src_path, "show_sympy.jl"))



# Create a symbolic type. There are various containers to recurse in to be
# caught here
function SymPyCore.:↑(::Type{_PyType}, x)
    class_nm = SymPyCore.classname(x)
    class_nm == "set"       && return Set(Sym.(collect(x)))
    class_nm == "tuple" && return Tuple(↑(xᵢ) for xᵢ ∈ x)
    class_nm == "list" && return [↑(xᵢ) for xᵢ ∈ x]
    class_nm == "dict" && return Dict(↑(k) => ↑(x[k]) for k ∈ x)

    class_nm == "FiniteSet" && return Set(Sym.(collect(x)))
    class_nm == "MutableDenseMatrix" && return _up_matrix(x) #map(↑, x.tolist())

    # others ... more hands on than pytype_mapping

    Sym(x)
end


# Mathfunctions that
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
SpecialFunctions.beta(a::Sym, b::Sym) = sympy.beta(a,b)
SpecialFunctions.besseli(n::Number, b::Sym) = sympy.besseli(n, b)
SpecialFunctions.besselj(n::Number, b::Sym) = sympy.besselj(n, b)
SpecialFunctions.besselk(n::Number, b::Sym) = sympy.besselk(n, b)
SpecialFunctions.bessely(n::Number, b::Sym) = sympy.bessely(n, b)



# lambdify using use_julia_code (`sympy` not available in `lambify.jl`)
function SymPyCore._convert_expr(use_julia_code::Val{true}, ex; kwargs...)
    Meta.parse(string(sympy.julia_code(ex)))
end

SymPyCore.Wild(x::AbstractString) = sympy.Wild(string(x))

"""
    Permutation
    PermutationGroup

Give access to the `sympy.combinatorics.permutations` module

## Example
```
julia> p = Permutation([1,2,3,0])
(0 1 2 3)

julia> p^2
(0 2)(1 3)

julia> p^2 * p^2
(3)
```

Rubik's cube example from SymPy documentation

```
julia> F = Permutation([(2, 19, 21, 8),(3, 17, 20, 10),(4, 6, 7, 5)])
(2 19 21 8)(3 17 20 10)(4 6 7 5)

julia> R = Permutation([(1, 5, 21, 14),(3, 7, 23, 12),(8, 10, 11, 9)])
(1 5 21 14)(3 7 23 12)(8 10 11 9)

julia> D = Permutation([(6, 18, 14, 10),(7, 19, 15, 11),(20, 22, 23, 21)])
(6 18 14 10)(7 19 15 11)(20 22 23 21)

julia> G = PermutationGroup(F,R,D)
PermutationGroup([
    (23)(2 19 21 8)(3 17 20 10)(4 6 7 5),
    (1 5 21 14)(3 7 23 12)(8 10 11 9),
    (6 18 14 10)(7 19 15 11)(20 22 23 21)])

julia> G.order()
3674160
```
"""
function Permutation(x; kwargs...)
    if typeof(x) <: UnitRange
        x = collect(x)
    end
    # should do this _check_permutation_format(x)
    # call this way to avoid ↓(x) call
    Sym(_combinatorics_.permutations.Permutation(x; kwargs...))
end
PermutationGroup(args...; kwargs...) = combinatorics.PermutationGroup(args...; kwargs...)

# Instrospection, assumptions use a struct to imitate old use of module; we pass in _sympy_
const Introspection = SymPyCore.Introspection(_sympy_ = _sympy_) # introspection
const 𝑄 = SymPyCore.𝑄(_sympy_=_sympy_)
