## Common code

using LinearAlgebra
import CommonEq
import CommonSolve
import SpecialFunctions

## import/exports
import SymPyCore: ↑, ↓, ↓ₖ
import SymPyCore: SymbolicObject, Sym, SymFunction, SymMatrix
import SymPyCore: symbols, free_symbols
import SymPyCore: solve
import SymPyCore: subs, lambdify
import SymPyCore: ask
import SymPyCore: N
import SymPyCore: Differential
import SymPyCore: rhs, lhs
#import SymPyCore: ∨, ∧, ¬  # infix logical operators

# more exports defined in SymPyCore/src/gen_methods_sympy
export Sym, SymFunction
export sympy, PI, E, IM, oo, zoo, TRUE, FALSE
export @syms, sympify, symbols, free_symbols
export simplify, expand_trig, expand, together, apart, factor, cancel
export solve, dsolve, nsolve, linsolve, nonlinsolve, solveset
export real_roots, roots, nroots
export integrate
export degree, sign
export series, summation, hessian
export subs, lambdify
export refine, ask
export N
export limit, diff, integrate, Differential
export rhs, lhs
#export ∨, ∧, ¬
export 𝑄

export _sympy_, ↓, ↑ # remove later; for development only

# emacs and indent; this goes last
import SymPyCore: Lt, ≪, Le, ≦, Eq, ⩵, Ne, ≶, ≷, Ge, ≫, Gt, ≧
export  Lt, ≪, Le, ≦, Eq, ⩵, Ne, ≶, ≷, Ge, ≫, Gt, ≧

const _sympy_core_  = _pynull()

# exported symbols and their python counterparts
const _sympy_  = _pynull()
const sympy = Sym(_sympy_)

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

function __init__()

    ## Define sympy, mpmath, ...
    _copy!(_sympy_, PyCall.pyimport_conda("sympy", "sympy"))
    _copy!(_sympy_core_, PyCall.pyimport("sympy.core"))

    _copy!(_PI_, _sympy_.pi)
    _copy!(_E_, _sympy_.E)
    _copy!(_IM_, _sympy_.I)
    _copy!(_oo_, _sympy_.oo)
    _copy!(_zoo_, _sympy_.zoo)
    _copy!(_TRUE_, PyCall.PyObject(true))
    _copy!(_FALSE_, PyCall.PyObject(false))

    # pytypemapping
    basictype = _sympy_core_.basic.Basic
    pytype_mapping(basictype, Sym)

end



# includes
core_src_path = joinpath(pathof(SymPyPyCall.SymPyCore), "../../src/SymPy")
include(joinpath(core_src_path, "constructors_sympy.jl"))
include(joinpath(core_src_path, "gen_methods_sympy.jl"))
include(joinpath(core_src_path, "show_sympy.jl"))

# Mathfunctions
Base.factorial(n::Sym) = sympy.factorial(n)
Base.log(x::Sym, n::Number) = sympy.log(x, n) # Need to switch order here
Base.atan(x::Sym, y) = sympy.atan2(x, y)
Base.angle(z::Sym) = atan(imag(z), real(z))

# Instrospection, assumptions use a struct to imitate old use of module; we pass in _sympy_
Introspection = SymPyCore.Introspection(_sympy_ = _sympy_) # introspection
const 𝑄 = SymPyCore.𝑄(_sympy_=_sympy_)
