## --------------------------------------------------
## Subs

## Call
## Call symbolic object with natural syntax
## ex(x=>val)
## how to do from any symbolic object?
(ex::Sym)() = ex

## without specification, variables to substitute for come from ordering of `free_symbols`:
function (ex::Sym)(args...)
    if ex.is_Permutation == true
        return ↑(↓(ex)(map(↓, args)...))
    end

    # need to check if callable.
    # This is a total hack!
    if ex.is_Function == true && string(ex.o.__class__.__name__) == "UndefinedFunction"
        return ↑(↓(ex)(map(↓, args)...))
    end

    xs = free_symbols(ex)
    return subs(ex, Dict(zip(xs, args)))
end

## can use a Dict or pairs to specify:
function (ex::Sym)(x::Dict)
    for (k,v) in x
        ex = subs(ex, Pair(k, Sym(v)))
    end
    ex
end
(ex::Sym)(kvs::Pair...) = ex(Dict(kvs...))

##################################################
## subs
##
"""
`subs` is used to substitute a value in an expression with another
value.
Examples:

```jldoctest subs
julia> using SymPyPythonCall



julia> @syms x,y
(x, y)

julia> ex = (x-y)*(x+2y)
(x - y)⋅(x + 2⋅y)

julia> subs(ex, (y, y^2)) |> show
(x - y^2)*(x + 2*y^2)

julia> subs(ex, (x,1), (y,2))
-5

julia> subs(ex, (x,y^3), (y,2))
72

julia> subs(ex, y, 3)
(x - 3)⋅(x + 6)
```

There is a curried form of `subs` to use with the chaining `|>` operator

```jldoctest subs
julia> ex |> subs(x,ℯ)
(ℯ - y)⋅(2⋅y + ℯ)
```
The use of pairs gives a convenient alternative:

```jldoctest subs
julia> subs(ex, x=>1, y=>2)
-5

julia> ex |> subs(x=>1, y=>2)
-5
```


"""
function subs(ex::T, y::Tuple{Any, Any}; kwargs...) where {T <: SymbolicObject}
    ex.subs(y[1], Sym(y[2]), kwargs...)
end

# Alternate interfaces

subs(ex::T, y::Tuple{Any, Any}, args...; kwargs...) where {T <: SymbolicObject} = subs(subs(ex, y), args...)
subs(ex::T, y::S, val; kwargs...)                   where {T <: SymbolicObject, S<:SymbolicObject} = subs(ex, (y,val))
subs(ex::T, dict::Dict; kwargs...)                  where {T <: SymbolicObject} = subs(ex, dict...)
subs(ex::T, d::Pair...; kwargs...)                  where {T <: SymbolicObject} = subs(ex, ((p.first, p.second) for p in d)...)
subs(exs::Tuple{T, N}, args...; kwargs...)          where {T <: SymbolicObject, N} = map(u -> subs(u, args...;kwargs...), exs)
subs(x::Number, args...; kwargs...) = x

## curried versions to use with |>
subs(x::SymbolicObject, y; kwargs...) = ex -> subs(ex, x, y; kwargs...)
subs(;kwargs...)                      = ex -> subs(ex; kwargs...)
subs(dict::Dict; kwargs...)           = ex -> subs(ex, dict...; kwargs...)
subs(d::Pair...; kwargs...)           = ex -> subs(ex, [(p.first, p.second) for p in d]...; kwargs...)


##################################################
## doit
##
"""
    doit

Evaluates objects that are not evaluated by default. Alias for object method.

## Extended help
Examples:

```jldoctest doit
julia> using SymPyPythonCall

julia> @syms x f()
(x, f)

julia> D = Differential(x)
Differential(x)

julia> df = D(f(x)); show(df)
Derivative(f(x), x)

julia> dfx = subs(df, (f(x), x^2));  show(dfx)
Derivative(x^2, x)

julia> doit(dfx)
2⋅x
```

Set `deep=true` to apply `doit` recursively to force evaluation of nested expressions:

```jldoctest doit
julia> @syms g()
(g,)

julia> dgfx = g(dfx);  show(dgfx)
g(Derivative(x^2, x))

julia> doit(dgfx) |> show
g(Derivative(x^2, x))

julia> doit(dgfx, deep=true)
g(2⋅x)
```

There is also a curried form of `doit`:
```jldoctest doit
julia> dfx |> doit
2⋅x

julia> dgfx |> doit(deep=true)
g(2⋅x)
```

"""
doit(ex::T; deep::Bool=false) where {T<:SymbolicObject} = ex.doit(deep=deep)
doit(; deep::Bool=false)                                = ((ex::T) where {T<:SymbolicObject}) -> doit(ex, deep=deep)

## simplify(ex::SymbolicObject, ...) is exported
"""
    simplify

SymPy has dozens of functions to perform various kinds of simplification. There is also one general function called `simplify` that attempts to apply all of these functions in an intelligent way to arrive at the simplest form of an expression. (See [Simplification](https://docs.sympy.org/latest/tutorial/simplification.html) for details on `simplify` and other related functionality). Other simplification functions are available through the `sympy` object.

For non-symbolic expressions, `simplify` returns its first argument.
"""
simplify(x, args...;kwargs...) = x

##################################################
##
## access documentation of SymPy
"""
    SymPy.Doc(f::Symbol, [module=sympy])

Return docstring of `f` found within the specified module.

Examples
```
SymPy.Doc(:sin)
SymPy.Doc(:det, sympy.matrices)
## add module to query
SymPy.pyimport_conda("sympy.crypto.crypto", "sympy")
SymPy.Doc(:padded_key, sympy.crypto)
```
"""
struct Doc
    u
    m
end
Doc(u::Union{Symbol, Function}) = Doc(Symbol(u), sympy)
function Base.show(io::IO, u::Doc)
    v = getproperty(u.m, Symbol(u.u)).__doc__
    print(io, v)
end


"""
    free_symbols(ex)
    free_symbols(ex::Vector{Sym})

Return vector of free symbols of expression or vector of expressions. The results are orderded by
`sortperm(string.(fs))`.

Example:

```jldoctest
julia> using SymPyPythonCall

julia> @syms x y z a
(x, y, z, a)

julia> free_symbols(2*x + a*y) # [a, x, y]
3-element Vector{Sym{PythonCall.Py}}:
 a
 x
 y


julia> free_symbols([x^2, x^2 - 2x*y + y^2])
2-element Vector{Sym{PythonCall.Py}}:
 x
 y
```
"""
function free_symbols(ex::S) where {T, S<:SymbolicObject{T}}
    !hasproperty(↓(ex), :free_symbols) && return Sym{T}[]
    fs = collect(↓(ex).free_symbols)
    isempty(fs) && return Sym{T}[]
    return Sym.(fs[sortperm(string.(fs))] )
end

# over container
function free_symbols(exs::Vector{S}) where {S}
    return sort(unique(reduce(vcat, free_symbols.(exs))))
end

function free_symbols(exs::Tuple)
    map(free_symbols, exs)
end
