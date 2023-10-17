## Common code

using LinearAlgebra
import SpecialFunctions
import CommonEq
import CommonSolve

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
import SymPyCore: simplify, expand, together, apart, factor, cancel
import SymPyCore: solve, dsolve, nsolve, linsolve, nonlinsolve, solveset
import SymPyCore: subs, lambdify, simplify
import SymPyCore: ask, doit
import SymPyCore: N
import SymPyCore: limit, diff, integrate, Differential, Heaviside
import SymPyCore: rhs, lhs
import SymPyCore: Wild, Permutation, PermutationGroup
#import SymPyCore: ∨, ∧, ¬  # infix logical operators

# more exports defined in SymPyCore/src/gen_methods_sympy
export Sym, SymFunction
export sympy, PI, E, IM, oo, zoo, TRUE, FALSE
export @syms, sympify, symbols, free_symbols
export simplify, expand, together, apart, factor, cancel
export solve, dsolve, nsolve, linsolve, nonlinsolve, solveset
export real_roots,  nroots # roots
export sign #,degree
export series, summation #, hessian
export subs, lambdify
export ask, doit, rewrite # refine,
export N
export limit, diff, integrate, Differential, Heaviside
export rhs, lhs
export Wild #, cse
export Permutation, PermutationGroup
#export ∨, ∧, ¬
export 𝑄, 𝑆, Introspection

export ↓, ↑

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

const _𝑄_ = _pynull()
const 𝑄 = Sym(_𝑄_)

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
    _copy!(_𝑄_, _sympy_.Q)
    _copy!(_TRUE_, _pyobject(true))
    _copy!(_FALSE_, _pyobject(false))

    # pytypemapping
    #basictype = _sympy_core_.basic.Basic
    #_pytype_mapping(basictype, Sym)


end



# includes
core_src_path = joinpath(pathof(SymPyCore), "../../src/SymPy")
include(joinpath(core_src_path, "constructors_sympy.jl"))
include(joinpath(core_src_path, "gen_methods_sympy.jl"))
include(joinpath(core_src_path, "additional_methods_sympy.jl"))
include(joinpath(core_src_path, "show_sympy.jl"))
