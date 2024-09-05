## Work with symbolic expression tree including lambdify

# to keep SymPy.Introspection alive
Introspection_docs = md"""
     Introspection

Struct holding functions used to inspect an object

* `Introspection.func`: Return pointer to Python function.
* `Introspection.operation`: Return `Julia` generic function for given underlying function
* `Introspection.funcname`: Returns name of function
* `Introspection.args`: Returns arguments for expression or empty tuple
* `Introspection.arguments`: Return arguments
* `Introspection.iscall`: Check if object is an expression (with operation and arguments) or not
* `Introspection.class`: Returns `__class__` value
* `Introspection.classname`: Returns `__class__` value as a string
* `Introspection.similarterm`: Create a similar term

[Invariant:](http://docs.sympy.org/dev/tutorial/manipulation.html)

As `args` returns symbolic objects, this becomes:
every well-formed SymPy expression `ex` must either have `length(args(ex)) == 0` or
`func(ex)(↓(args(ex))...) = ex`.

Using the methods designed for `SymbolicUtils` usage, this becomes
every expression one of `!iscall(ex)`  or `operation(ex)(args(ex)...) == ex` should hold.
"""

@doc Introspection_docs
Base.@kwdef struct Introspection{T}
    _sympy_::T
    funcname::Function  = (x::Sym) -> SymPyCore.funcname(x, _sympy_)
    func::Function      = (x::Sym) -> SymPyCore.func(x, _sympy_)
    args::Function      = (x::Sym) -> SymPyCore.args(x, _sympy_)
    class::Function     = (x::Sym) -> SymPyCore.class(x, _sympy_)
    classname::Function = (x::Sym) -> SymPyCore.classname(x, _sympy_)
    operation::Function = (x::Sym) -> SymPyCore._operation(x)
    arguments::Function = (x::Sym) -> SymPyCore.args(x, _sympy_)
    iscall::Function    = (x::Sym) -> SymPyCore._iscall(x)
end

is_symbolic(x::SymbolicObject) = true
is_symbolic(x) = false

"""
    Introspection.funcname(x)

Return name or ""
"""
function funcname(x::Sym, _sympy_=nothing)
    y = ↓(x)
    if hasproperty(y, :func)
        return string(y.func.__name__)
    else
        return ""
    end
end

func(ex::Sym, _sympy_=nothing) = return ↓(ex).func
function args(x::Sym, _sympy_=nothing)
    y = ↓(x)
    if hasproperty(y, :args)
        return Tuple(Sym(aᵢ) for aᵢ in y.args)
    else
        return ()
    end
end

function class(x::T, _sympy_=nothing) where {T}
    y = ↓(x)
    if hasproperty(y, :__class__)
        return y.__class__
    else
        return nothing
    end
end

function classname(x::T, _sympy_=nothing) where {T}
    cls = class(x)
    if cls == nothing
        "NULL"
    else
        string(cls.__name__)
    end
end

# function getmembers(x::T) where {T <: Union{Sym, PyObject}}
#     Dict(u=>v for (u,v) in inspect.getmembers(x))
# end

## --------------------------------------------------
# Methods for TermInterface extension
function _iscall(x::SymbolicObject)
    hasproperty(↓(x), :is_Atom) && return !x.is_Atom
    return false
end

TermInterface.isexpr(x::SymbolicObject) = _iscall(x)
function TermInterface.operation(x::SymbolicObject)
    #@assert _iscall(x)
    nm = funcname(x)
    λ = get(sympy_fn_julia_fn, nm, nothing)
    isnothing(λ) && return getfield(Main, Symbol(nm))
    return first(λ)
end

TermInterface.arguments(x::SymbolicObject) = collect(args(x))

TermInterface.iscall(ex::SymbolicObject) = TermInterface.isexpr(ex)
TermInterface.head(ex::SymbolicObject) = TermInterface.operation(ex)
TermInterface.children(ex::SymbolicObject) = TermInterface.arguments(ex)

function TermInterface.maketerm(T::Type{<:SymbolicObject}, head, args, metadata)
    return head(args...)
end

## --- Additional TermInterface like methods for roundtripping
is_symbolic_variable(x::Sym) = x.is_symbol
function symbol_metadata(x::Sym)
    is_symbolic_variable(x) || throw(ArgumentError("not a symbol"))
    (Symbol(x), x.assumptions0)
end

is_symbolic_number(x::Sym) = x.is_number
function as_number(x::Sym)
    is_symbolic_number(x) || throw(ArgumentError("Not a symbolic number"))
    N(x)
end

is_symbolic_variable(::Any) = false
is_symbolic_number(::Any) = false

is_symbolic_number(x::Number) = false
as_number(x::Number) = x

# make a symbolic variable of type T
# implicit assumption that symbol + metadata makes identical symbol

"""
    makesym(constructor::Type, x::Symbol, metadata::Nothing)

For conversion *from* SymPy or SymPyPythonCall a method for `makesym` must be defined. For example, this is in an extension for SymbolicUtils:

```
import SymbolicUtils
function SymPyCore.makesym(T::Type{<:SymbolicUtils.BasicSymbolic}, 𝑥::Symbol, m=nothing)
    SymbolicUtils.Sym{Number}(𝑥) # add metadata
end
```
"""
function makesym(T::Type{<:Sym}, 𝑥::Symbol, m=nothing)
    Sym(𝑥) # add metadata
end

"""
    exhange(T, ex)

Exchange an expression in one symbolic type with an expression in another. E.g. from `SymPy` to `SymbolicUtils`.

## Example
```
import SymPy
import SymbolicUtils
import SymPy.SymPyCore: exchange
T,S = SymPy.Sym, SymbolicUtils.BasicSymbolic
SymPy.@syms x y
exchange(S, sin(x^2) + 2cos(y))
exchange(T, exchange(S, sin(x^2) + 2cos(y))) # round trip
```


!!! note "Tentative"
    This is a possible interface for exchanging symbolic expressions, it may change

For conversion through `exchange` *to* SymPy or SymPyPythonCall methods for
`is_symbolic_variable(x::T)`,  `symbol_metadata(x::T)`, `is_symbolic_number(x::T)` and  `as_number(x::T)` must be defined.

"""
function exchange(T, ex)
    if TermInterface.isexpr(ex)
        op, args = TermInterface.operation(ex), TermInterface.arguments(ex)
        args′ = exchange.(Ref(T), args)
        return TermInterface.maketerm(T, op, args′, nothing)
    elseif is_symbolic_number(ex)
        return as_number(ex)
    elseif is_symbolic_variable(ex)
        𝑥, m = symbol_metadata(ex)
        return makesym(T, 𝑥, m)
    end
    ex
end

# **possible alternate to the above**
# which doesn't make any effort to detect and convert symbols

_N(ex::Sym) = N(ex)
_N(ex) = ex

"""
    _exchange(ex, as::Pair...)

```
SymPy.@syms 𝑥 𝑦
SymbolicUtils.@syms x y

𝑒𝑥 = sin(𝑥^2 + y + π) / (2 + cos(𝑦) + 𝑥^2)
ex = sin(x^2 + y + π) / (2 + cos(y) + x^2)

SymPyCore.xchange(𝑒𝑥, 𝑥 => x, 𝑦 => y)
SymPyCore.xchange(ex, x => 𝑥, y => 𝑦)
```

!!! note
    Experimental
"""
function xchange(ex, as::Pair...)
    _xchange(Val(iscall(ex)), ex, as...)
end

function _xchange(::Val{true}, ex, as...)
    op, args = operation(ex), arguments(ex)
    args′ = replace(args, as...)
    op((xchange(aᵢ, as...) for aᵢ ∈ args′)...)
end

function _xchange(::Val{false}, ex, as...)
    for (k,v) ∈ as
        isequal(ex, k) && return v
    end
    _N(ex)
end


## --------------------------------------------------

# lambdify an expression

## Mapping of SymPy Values into julia values
val_map = Dict(
               "Zero"             => :(0),
               "One"              => :(1),
               "NegativeOne"      => :(-1),
               "Half"             => :(1/2),
               "Pi"               => :pi,
               "Exp1"             => :ℯ,
               "Infinity"         => :Inf,
               "NegativeInfinity" => :(-Inf),
               "ComplexInfinity"  => :Inf, # error?
               "ImaginaryUnit"    => :im,
               "BooleanTrue"      => :true,
               "BooleanFalse"     => :false
               )

## Mapping of Julia function names into julia ones
## most are handled by Symbol(fnname), the following catch exceptions
## Hack to avoid Expr(:call,  :*,2, x)  being  2x and  not  2*x
## As of newer sympy versions, this is no longer needed.

# Some julia functions for use within lambdify
function _piecewise(args...)
    as = copy([args...])
    val, cond = pop!(as)
    ex = Expr(:call, :ifelse, cond, convert(Expr,val), :nothing)
    while length(as) > 0
        val, cond = pop!(as)
        ex = Expr(:call, :ifelse, cond, convert(Expr,val), convert(Expr, ex))
    end
    ex
end

_ANY_(xs...) = any(xs) # any∘tuple ?
_ALL_(xs...) = all(xs) # all∘tuple
_ZERO_(xs...) = 0      #
# not quite a match; NaN not θ(0) when evaluated at 0 w/o second argument
_HEAVISIDE_(a...)  = (a[1] < 0 ? 0 : (a[1] > 0 ? 1 : (length(a) > 1 ? a[2] : NaN)))
_sinc_(x) = iszero(x) ? 1 : sin(x)/x # sympy.sinc ->

## Map to get function object from type information
# we may want fn or expression, Symbol(+) yields :+ but allocates to make a string
sympy_fn_julia_fn = Dict(
    "Add" => (+, :+),
    "Sub" => (-, :-),
    "Mul" => (*, :*),
    "Div" => (/, :/),
    "Pow" => (^, :^),
    "re"  => (real, :real),
    "im"  => (imag, :imag),
    "Abs" => (abs, :abs),
    "Min" => (min, :min),
    "Max" => (max, :max),
    "Poly" => (identity, :identity),
    "conjugate" => (conj, :conj),
    "atan2" => (atan, :atan),
    #
    "Less" => (<, :(<)),
    "LessThan" => (<=, :(<=)),
    "StrictLessThan" => (<, :(<)),
    "Equal" => (==, :(==)),
    "Equality" => (==, :(==)),
    "Unequality" => (!==, :(!==)),
    "StrictGreaterThan" => (>, :(>)),
    "GreaterThan" => (>=, :(>=)),
    "Greater" => (>, :(>)),
    #
    "sinc" => (SymPyCore._sinc_, :(SymPyCore._sinc_)),
    "Piecewise" => (SymPyCore._piecewise,  :(SymPyCore._piecewise)),
    "Heaviside" => (SymPyCore._HEAVISIDE_, :(SymPyCore._HEAVISIDE_)),
    "Order" =>     (SymPyCore._ZERO_,      :(SymPyCore._ZERO_)),
    "And" =>       (all∘tuple,             :(SymPyCore._ALL_)),
    "Or" =>        (any∘tuple,             :(SymPyCore._ANY_)),
)


const  fn_map = Dict(k => last(v) for (k,v) ∈ pairs(sympy_fn_julia_fn))

map_fn(key, fn_map) = haskey(fn_map, key) ? fn_map[key] : Symbol(key)

##

Base.convert(::Type{Expr}, x::SymbolicObject) = walk_expression(x)

"""
    walk_expression(ex; values=Dict(), fns=Dict())

Convert a symbolic SymPy expression into a `Julia` expression. This is needed to use functions in external packages in lambdified functions.

# Extended help

## Example

```julia
using SymPy
@syms x y
ex = sympy.hyper((2,2),(3,3),x) * y
```

Calling `lambdify(ex)` will fail to make a valid function, as `hyper` is implemented in `HypergeometricFunctions.pFq`. So, we have:

```julia
using HypergeometricFunctions
d = Dict("hyper" => :pFq)
body = SymPy.walk_expression(ex, fns=d)
syms = Symbol.(free_symbols(ex))
fn = eval(Expr(:function, Expr(:call, gensym(), syms...), body));
fn(1,1) # 1.6015187080185656
```

"""
function walk_expression(ex; values=Dict(), fns=Dict())

    fns_map = merge(fn_map, fns)
    vals_map = merge(val_map, values)

    fn = funcname(ex)
    # special case `F(t) = ...` output from ODE
    # this may be removed if it proves a bad idea....
    if fn == "Equality" && lhs(ex).is_Function
        return walk_expression(rhs(ex), values=values, fns=fns)
    end

    if fn == "Symbol" || fn == "Dummy" || fn == "IndexedBase"
        str_ex = string(ex)
        return get(vals_map, str_ex, Symbol(str_ex))
    elseif fn in ("Integer" , "Float")
        return N(ex)
    elseif fn == "Rational"
        return N(numerator(ex))// N(denominator(ex))
        ## piecewise requires special treatment
    elseif fn == "Piecewise"
        return _piecewise([walk_expression(cond, values=values, fns=fns) for cond in args(ex)]...)
    elseif fn == "ExprCondPair"
        val, cond = args(ex)
        return (val, walk_expression(cond, values=values, fns=fns))
    elseif fn == "Tuple"
        return walk_expression.(args(ex), values=values, fns=fns)
    elseif fn == "Indexed"
        return Expr(:ref, [walk_expression(a, values=values, fns=fns) for a in args(ex)]...)
    elseif fn == "Pow"
        a, b = args(ex)
        b == 1//2 && return Expr(:call, :sqrt, walk_expression(a, values=values, fns=fns))
        b == 1//3 && return Expr(:call, :cbrt, walk_expression(a, values=values, fns=fns))
        return Expr(:call, :^,  [walk_expression(aᵢ, values=values, fns=fns) for aᵢ in (a,b)]...)
    elseif haskey(vals_map, fn)
        return vals_map[fn]
    end

    as = args(ex)
    Expr(:call, map_fn(fn, fns_map), [walk_expression(a, values=values, fns=fns) for a in as]...)
end

"""
    lambdify(ex, vars=free_symbols();
             fns=Dict(), values=Dict, use_julia_code=false,
             invoke_latest=true)

Take a symbolic expression and return a `Julia` function or expression to build a function.

* `ex::Sym` a symbolic expression with 0, 1, or more free symbols

* `vars` a container of symbols to use for the function arguments. The default is `free_symbols` which has a specific ordering. Specifying `vars` allows this default ordering of arguments to be customized. If `vars` is empty, such as when the symbolic expression has *no* free symbols, a variable arg constant function is returned.

* `fns::Dict`, `vals::Dict`: Dictionaries that allow customization of the function that walks the expression `ex` and creates the corresponding AST for a Julia expression. See `SymPy.fn_map` and `SymPy.val_map` for the default mappings of sympy functions and values into `Julia`'s AST.

* `use_julia_code::Bool`: use SymPy's conversion to an expression, the default is `false`

* `invoke_latest=true`: if `true` will call `eval` and `Base.invokelatest` to return a function that should not have any world age issue. If `false` will return a Julia expression that can be `eval`ed to produce a function.

Example:

```jldoctest lambdify
julia> using SymPyPythonCall

julia> @syms x y z
(x, y, z)

julia> ex = x^2 * sin(x)
 2
x ⋅sin(x)

julia> fn = lambdify(ex);

julia> fn(pi)
0.0

julia> ex = x + 2y + 3z
x + 2⋅y + 3⋅z

julia> fn = lambdify(ex);

julia> fn(1,2,3) # order is by free_symbols
14

julia> ex(x=>1, y=>2, z=>3)
14

julia> fn = lambdify(ex, (y,x,z));

julia> fn(1,2,3)
13
```

!!! note

    The default produces slower functions due to the calls to `eval` and
    `Base.invokelatest`.  In the following `g2` (which, as seen, requires
    additional work to compute) is as fast as calling `f` (on non symbolic
    types), whereas `g1` is an order of magnitude slower in this example.

```julia lambdify
julia> @syms x
(x,)

julia> f(x) = exp(cot(x))
f (generic function with 1 method)

julia> g1 = lambdify(f(x));

julia> ex = lambdify(f(x), invoke_latest=false);

julia> @eval g2(x) = (\$ex)(x)
g2 (generic function with 1 method)
```

An alternative, say, is to use `GeneralizedGenerated`'s `mk_function`, as follows:

```julia
julia> using GeneralizedGenerated

julia> body = convert(Expr, f(x))
:(exp(cot(x)))

julia> g3 = mk_function((:x,), (), body)
function = (x;) -> begin
    (Main).exp((Main).cot(x))
end
```

This function will be about 2-3 times slower than `f`.

"""
function  lambdify(ex::Sym, vars=free_symbols(ex);
              fns=Dict(), values=Dict(),
              use_julia_code=false,
              invoke_latest=true)

    if isempty(vars)
        # can't call N(ex) here...
        v = ex.evalf()
        if v.is_real == Sym(true)
            val = _convert(Real, ↓(v))
        else
            val = Complex(convert(Real, ↓(real(v))), convert(Real, ↓(imag(v))))
        end
        return (ts...) -> val
    end

    body = convert_expr(ex, fns=fns, values=values, use_julia_code=use_julia_code)
    ex = expr_to_function(body, vars)

    if invoke_latest
        fn = eval(ex)
        return (args...) -> Base.invokelatest(fn, args...)
    else
        ex
    end
end

# convert symbolic expression to julia AST
# more flexibly than `convert(Expr, ex)`
function convert_expr(ex::Sym;
                      fns=Dict(), values=Dict(),
                      use_julia_code=false)
    _convert_expr(Val(use_julia_code), ex, fns=fns, values=values)
end

# _convert_expr(use_julia_code::Val(true}, ex; kwargs...) defined in sympy
function _convert_expr(::Val{false}, ex::SymbolicObject; fns=Dict(), values=Dict())
    walk_expression(ex; fns = fns, values=values)
end


# take an expression and arguments and return an Expr of a generic function
function  expr_to_function(body, vars)
    syms = Symbol.(vars)
    Expr(:function, Expr(:call, gensym(), syms...), body)
end

# from @mistguy cf. https://github.com/JuliaPy/SymPy.jl/issues/218
# T a data type to convert to, when specified
function lambdify(exs::Array{S, N}, vars = union(free_symbols.(exs)...); T::DataType=Nothing, kwargs...) where {S <: Sym, N}
    f = lambdify.(exs, (vars,)) # prevent broadcast in vars
    if T == Nothing
        (args...) -> map.(f, args...)
    else
        (args...) -> convert(Array{T,N}, map.(f, args...))
    end
end

Base.convert(::Type{Function}, ex::Sym) = lambdify(ex)
