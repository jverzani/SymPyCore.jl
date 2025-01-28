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
    operation::Function = (x::Sym) -> SymPyCore.operation(x)
    arguments::Function = (x::Sym) -> SymPyCore.args(x, _sympy_)
    iscall::Function    = (x::Sym) -> SymPyCore.iscall(x)
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
# Methods for TermInterface
function TermInterface.iscall(x::SymbolicObject)
    hasproperty(↓(x), :is_Atom) && return !x.is_Atom
    return false
end

function TermInterface.operation(x::SymbolicObject)
    @assert iscall(x)
    nm = funcname(x)
    λ = get(sympy_fn_julia_fn, nm, nothing)
    isnothing(λ) && return getfield(Main, Symbol(nm))
    return first(λ)
end

TermInterface.arguments(x::SymbolicObject) = [aᵢ for aᵢ in args(x)]

function TermInterface.maketerm(T::Type{<:SymbolicObject}, head, args, metadata)
    return head(Iterators.flatten(args)...)
end

# make symbols
function TermInterface.maketerm(T::Type{<:SymbolicObject}, ::Nothing, args, metadata)
    Sym.(args)
end

## -----
# desired extensions to TermInterface for `exchange`
# is x a variable
function issym(x::SymbolicObject)
    iscall(x) && return false
    o = ↓(x)
    return o.is_Atom && !o.is_number
end

makesymbol(T::Type{<:SymbolicObject}, x::Symbol) = maketerm(T, nothing, (x,), nothing)

value(x) = N(x)

## Exchange
## Use TermInterface to switch between different symbolic types
_issymbol(x) = false
_issymbol(x::Sym) = issym(x)

_value(x) = x
_value(x::Sym) = value(x)

_makesymbol(T::Type{<:SymbolicObject}, x::Symbol) = makesymbol(T, x)

"""
    exchange(T, ex::𝑇)
    exchange(T)

Exchange an expression in one symbolic representation with another.

## Example

This shows how to exchange between `SymPy` with `SymbolicUtils`:

```
import SymPy
T = SymPy.Sym

import SymbolicUtils
𝐓 = SymbolicUtils.BasicSymbolic

import SymPyCore: exchange, _issymbol, _value, _makesymbol
_issymbol(x::𝐓) = SymbolicUtils.issym(x)
_value(x::𝐓) = x
_makesymbol(::Type{<:𝐓}, 𝑥::Symbol) = SymbolicUtils.Sym{Number}(𝑥)

SymPy.@syms x y
ex = x * tanh(exp(x)) - max(0, y)

ex |> exchange(𝐓) isa 𝐓
ex |> exchange(𝐓) |> exchange(T) isa T

SymbolicUtils.@syms x y
ex = y*cos(x)^2
ex′ = exchange(T, ex)
𝑥, 𝑦 = SymPy.free_symbols(ex′)
ex′ = SymPy.integrate(ex′, 𝑥) # y*(x/2 + sin(x)*cos(x)/2)
exchange(𝐓, ex′)              # y*((1//2)*x + (1//2)*sin(x)*cos(x))
```

**EXPERIMENTAL** -- interface is subject to change.

"""
function exchange(T, ex)
    if iscall(ex)
        op = operation(ex)
        args = arguments(ex)
        args′ = exchange.(T, args)
        return maketerm(T, op, collect(args′), metadata(ex))
    elseif _issymbol(ex)
        return _makesymbol(T, Symbol(ex))
    else
        return _value(ex)
    end
end

exchange(T) = Base.Fix1(exchange, T)

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

map_fn(key, fn_map) = haskey(fn_map, key) ? fn_map[key] :
    isdefined(@__MODULE__, Symbol(key)) ? Symbol(key) :
    error("Lambdify doesn't know what to do with $key. Sorry.")

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
operation_name(ex) = funcname(ex)
const _vd = Dict{String, Symbol}()
const _fd = Dict{String, Symbol}()


function walk_expression(ex;
                     values=_vd,
                     fns=_fd)

    fns_map = merge(fn_map, fns) # these modify
    vals_map = merge(val_map, values)

    op = operation_name(ex)

    # base cases variables, numbers
    if !iscall(ex)
        if any(==(op),  ("Symbol", "Dummy", "IndexedBase"))
            str_ex = string(ex)
            return get(vals_map, str_ex, Symbol(str_ex))
        elseif any(==(op), ("Integer", "Float"))
            return N(ex)
        elseif any(==(op), ("Rational",))
            return N(numerator(ex)) / N(denominator(ex))
        end
    end

    # special cases
    haskey(vals_map, op) && return vals_map[op]

    hasmethod(walk_expression_case, (Val{Symbol(op)}, typeof(ex))) &&
        return walk_expression_case(Val(Symbol(op)), ex; values, fns)

    # special case `F(t) = ...` output from ODE
    # this may be removed if it proves a bad idea....
    if op == "Equality" && lhs(ex).is_Function
        return walk_expression(rhs(ex); values, fns)
    end

    op′ = map_fn(op, fns_map)
    args′ = walk_expression.(args(ex); values, fns)

    Expr(:call, op′, args′...)

end


function walk_expression_case(::Val{:Piecewise}, ex; values=_vd, fns=_fd)
    return _piecewise(walk_expression.(args(ex); values, fns)...)
end

function walk_expression_case(::Val{:ExprCondPair}, ex; values=_vd, fns=_fd)
        val, cond = args(ex)
        return (val, walk_expression(cond; values, fns))
end

function walk_expression_case(::Val{:Tuple}, ex; values=_vd, fns=_fd)
    args′ = walk_expression.(args(ex); values, fns)
    return Expr(:tuple, args′...)
end

function walk_expression_case(::Val{:Indexed}, ex; values=_vd, fns=_fd)
    args′ = walk_expression.(args(ex); values, fns)
    return Expr(:ref, args′...)
end

function walk_expression_case(::Val{:Pow}, ex; values=_vd, fns=_fd)
    a, b = args(ex)
    aargs′ = walk_expression(a; values, fns)
    b == 1//2 && return Expr(:call, :sqrt, aargs′)
    b == 1//3 && return Expr(:call, :cbrt, aargs′)
    bargs′ = walk_expression.(b; values, fns)
    return Expr(:call, :^, aargs′, bargs′)
end

function _integral_case(op::Val{X}, ex; values=_vd, fns=_fd) where X
    expr, lims... = args(ex)

    respect = first.(args.(lims))

    fxargs = walk_expression(expr; values=values, fns=fns)
    fn_expr = Expr(:->, Expr(:tuple, Symbol.(respect)...), fxargs)


    lim_ranges = [Expr(:tuple, walk_expression.(Base.tail(args(lim)), values=values, fns=fns)...) for lim in lims]

    op = map_fn(string(X), fns)

    return Expr(:call, op, fn_expr, lim_ranges...)
end
walk_expression_case(op::Val{:Integral}, ex; values=_vd, fns=_fd) =
    _integral_case(op, ex; values, fns)
walk_expression_case(op::Val{:NonElementaryIntegral}, ex; values=_vd, fns=_fd) =
    _integral_case(op, ex; values, fns)




struct 𝐹{F,E,N} <: Function

    λ::F
    expr::E
    xs::NTuple{N, Symbol}
end

function Base.show(io::IO, ::MIME"text/plain", F::𝐹)
    vars = isempty(F.xs) ? "no variables" :
        length(F.xs) == 1 ? "a single variable $(only(F.xs))" :
        "variables $(F.xs)"
    print(io, "Callable function with $vars")
end

(F::𝐹)() = F.λ()
(F::𝐹)(x) = F.λ(x...)
(F::𝐹)(x, xs...) = F.λ(x, xs...)

function Base.iterate(F::𝐹, state=nothing)
    isnothing(state) && return (F.xs,1)
    state == 1 && return ((), 2)
    state == 2 && return (F.expr, 3)
    return nothing
end

#

"""
    lambdify(ex, vars...;
             fns=Dict(), values=Dict,
             expression = Val{false},
             conv = walk_expression,
             use_julia_code=false,
             invoke_latest=true)

Take a symbolic expression and return a `Julia` struct subtyping `Function` or expression to build a function. The struct contains the expression.

* `ex::Sym` a symbolic expression with 0, 1, or more free symbols

* `vars` Either a tuple of variables or each listed separately, defaulting to `free_symbols(ex)` and its ordering. If `vars` is empty, a 0-argument function is returned.

* `fns::Dict`, `vals::Dict`: Dictionaries that allow customization of the function that walks the expression `ex` and creates the corresponding AST for a Julia expression. See `SymPy.fn_map` and `SymPy.val_map` for the default mappings of sympy functions and values into `Julia`'s AST.

# `expression`: the default, `Val{false}`, will return a callable struct; passing `Val{true}` will return the expression. (This is also in the `expr` field of the struct, so changing this is unnecessary.) (See also `invoke_latest=false`.)

* `conv`: a method to convert a symbolic expression into an expression. The default is part of this package; the alternative, the unexpored `julia_code`, is from the Python package. (See also `use_julia_code`)

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

A performant and easy alternative, say, is to use `GeneralizedGenerated`'s `mk_function`, as follows:

```julia
julia> using GeneralizedGenerated, BenchmarkTools

julia> f(x,p) = x*tanh(exp(p*x));

julia> @syms x p; g = lambdify(f(x,p), x, p)
Callable function with variables (:x, :p)

julia> gg = mk_function(g...);

julia> @btime \$g(1,2)
  48.862 ns (1 allocation: 16 bytes)
0.9999992362042291

julia> @btime \$gg(1,2)
 1.391 ns (0 allocations: 0 bytes)
0.9999992362042291

julia> @btime \$f(1,2)
  1.355 ns (0 allocations: 0 bytes)
0.9999992362042291

```

As seen, the function produced by `GeneralizedGenerated` is as performant as the original, and **much** more so than calling that returned by `lambdify`, which uses a call to `Base.invokelatest`.

"""
function lambdify(ex::SymbolicObject; kwargs...)
    vars = free_symbols(ex)
    _λfy(ex, vars...; kwargs...)
end
lambdify(ex::SymbolicObject, xs...; kwargs...) = _λfy(ex, xs...; kwargs...)
lambdify(ex::SymbolicObject, xs::Tuple; kwargs...) = _λfy(ex, xs...; kwargs...)

# from @mistguy cf. https://github.com/JuliaPy/SymPy.jl/issues/218
# T a data type to convert to, when specified
function lambdify(exs::Array{S, N}, vars = union(free_symbols.(exs)...); T::DataType=Nothing, kwargs...) where {S <: Sym, N}
    #f = λfy.(exs, (vars,)) # prevent broadcast in vars
    f = _λfy.(exs, vars...) # prevent broadcast in vars
    if T == Nothing
        (args...) -> map.(f, args...)
    else
        (args...) -> convert(Array{T,N}, map.(f, args...))
    end
end


function _λfy(ex, xs...;
              invoke_latest = true,
              use_julia_code=false,
              expression = Val{false},
              conv = walk_expression,
              kwargs...)

    # legacy arguments
    use_julia_code && (conv = julia_code)
    !invoke_latest && (expression = Val{true})

    body = conv(ex; kwargs...)
    syms = Symbol.(xs)
    λ = Expr(:->, Expr(:tuple, syms...), body)

    if expression == Val{true}
        return λ
    else
        fn = eval(λ)
        λ′ = (args...) -> Base.invokelatest(fn, args...)
        return 𝐹(λ′, body, syms)
        return 𝐹(GeneralizedGenerated.mk_function(expression_module, λ), body, syms)
    end
end

julia_code() = nothing # stub for function to convert in SymPy/

# convert alternative to lambdify
Base.convert(::Type{Function}, ex::Sym) = lambdify(ex)

# Should deprecate, as one can just use lambdify and grab expr
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
