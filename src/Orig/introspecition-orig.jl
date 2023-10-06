

## Module for Introspection
module Introspection

import SymPy
import SymPy: Sym
import PyCall: PyObject, hasproperty, PyNULL, inspect
export args, func, funcname, class, classname, getmembers


# utilities

"""
    funcname(x)

Return name or ""
"""
function funcname(x::Sym)
    y = PyObject(x)
    if hasproperty(y, :func)
        return y.func.__name__
    else
        return ""
    end
end

"""
   func(x)

Return function head from an expression

[Invariant:](http://docs.sympy.org/dev/tutorial/manipulation.html)

Every well-formed SymPy expression `ex` must either have `length(args(ex)) == 0` or
`func(ex)(args(ex)...) = ex`.
"""
func(ex::Sym) = return ex.func

"""
    args(x)

Return arguments of `x`, as a tuple. (Empty if no `:args` property.)
"""
function args(x::Sym)
    if hasproperty(PyObject(x), :args)
        return x.args
    else
        return ()
    end
end

function class(x::T) where {T <: Union{Sym, PyObject}}
    if hasproperty(PyObject(x), :__class__)
        return x.__class__
    else
        return PyNull()
    end
end

function classname(x::T) where {T <: Union{Sym, PyObject}}
    cls = class(x)
    if cls == PyNULL()
        "NULL"
    else
        cls.__name__
    end
end

function getmembers(x::T) where {T <: Union{Sym, PyObject}}
    Dict(u=>v for (u,v) in inspect.getmembers(x))
end


## Map to get function object from type information
funcname2function = (
    Add = +,
    Sub = -,
    Mul = *,
    Div = /,
    Pow = ^,
    re  = real,
    im  = imag,
    Abs = abs,
    Min = min,
    Max = max,
    Poly = identity,
    Piecewise = error, # replace
    Order = (as...) -> 0,
    And = (as...) -> all(as),
    Or =  (as...) -> any(as),
    Less = <,
    LessThan = <=,
    StrictLessThan = <,
    Equal = ==,
    Equality = ==,
    Unequality = !==,
    StrictGreaterThan = >,
    GreaterThan = >=,
    Greater = >,
    conjugate = conj,
    atan2 = atan,
    TupleArg = tuple,
    Heaviside =  (a...)  -> (a[1] < 0 ? 0 : (a[1] > 0 ? 1 : (length(a) > 1 ? a[2] : NaN))),
)

end
