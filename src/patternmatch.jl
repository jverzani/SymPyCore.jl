## Pattern matching modifications


"""
    Wild(x)

create a "wild card" for pattern matching
"""
Wild(x::Symbol) = Wild(string(x)) # Wild(::String) in syjmpy.jl

"""
    match(pattern, expression, ...)

Match a pattern against an expression; returns a dictionary of matches.

If a match is unsuccesful, returns an *empty* dictionary. (SymPy returns "nothing")

The order of the arguments follows `Julia`'s `match` function, not `sympy.match`, which can be used directly, otherwise.
"""
function Base.match(pat::Sym, ex::Sym, args...; kwargs...)
    out = ex.match(pat, args...; kwargs...)
    out == nothing && return Dict()
    out
end

"""
    replace(expression, pattern, value, ...)
    replace(expression, pattern => value; kwargs...)

In the expression replace a mathcing pattern with the value. Returns the modified expression.

# Extended help

From: [SymPy Docs](http://docs.sympy.org/dev/modules/core.html)

Traverses an expression tree and performs replacement of matching
subexpressions from the bottom to the top of the tree. The default
approach is to do the replacement in a simultaneous fashion so changes
made are targeted only once. If this is not desired or causes
problems, `simultaneous` can be set to `false`. In addition, if an
expression containing more than one `Wild` symbol is being used to match
subexpressions and the `exact` flag is `true`, then the match will only
succeed if non-zero values are received for each `Wild` that appears in
the match pattern.


Differences from SymPy:

* "types" are specified via calling `func` on the head of an expression: `func(sin(x))` -> `sin`, or directly through `sympy.sin`

* functions are only supported by calling into the glue package.

Examples (from the SymPy docs)

```julia
julia> using SymPy

julia> @syms x, y, z
(x, y, z)

julia> f = log(sin(x)) + tan(sin(x^2))
log(sin(x)) + tan(sin(x^2))

```

## "type" -> "type"

Types are specified through `func`:

```julia
julia> func = Introspection.func
func (generic function with 1 method)

julia> replace(f, func(sin(x)), func(cos(x))) # type -> type
log(cos(x)) + tan(cos(x^2))
```

The value `sympy.sin` does not work, as it is wrapped. Using `↓(sympy).sin` will work:
```
julia> replace(f, ↓(sympy).sin, ↓(sympy).cos)
log(cos(x)) + tan(cos(x^2))
```



## "pattern" -> "expression"

Using "`Wild`" variables allows a pattern to be replaced by an expression:

```julia
julia> a, b = Wild("a"), Wild("b")
(a_, b_)

julia> replace(f, sin(a), tan(2a))
log(tan(2*x)) + tan(tan(2*x^2))

julia> replace(f, sin(a), tan(a/2))
log(tan(x/2)) + tan(tan(x^2/2))

julia> f.replace(sin(a), a)
log(x) + tan(x^2)

julia> (x*y).replace(a*x, a)
y

```

In the SymPy docs we have:

Matching is exact by default when more than one Wild symbol is used: matching fails unless the match gives non-zero values for all Wild symbols."

```julia
julia> replace(2x + y, a*x+b, b-a)  # y - 2
y - 2

julia> replace(2x + y, a*x+b, b-a, exact=false)  # y + 2/x
    2
y + ─
    x
```

## "type" -> "function"

To replace with a more complicated function, requires some assistance from `Python`, as an anonymous function must be defined witin Python, not `Julia`. This is how it might be done:

```
julia> import PyCall

julia> ## Anonymous function a -> sin(2a)
       PyCall.py\"\"\"
       from sympy import sin, Mul
       def anonfn(*args):
           return sin(2*Mul(*args))
       \"\"\")


julia> replace(f, sympy.sin, PyCall.py"anonfn")
                   ⎛   ⎛   2⎞⎞
log(sin(2⋅x)) + tan⎝sin⎝2⋅x ⎠⎠
```

## "pattern" -> "func"

The function is redefined, as a fixed argument is passed:

```julia
julia> PyCall.py\"\"\"
       from sympy import sin
       def anonfn(a):
           return sin(2*a)
       \"\"\"

julia> replace(f, sin(a), PyCall.py"anonfn")
                   ⎛   ⎛   2⎞⎞
log(sin(2⋅x)) + tan⎝sin⎝2⋅x ⎠⎠
```

## "func" -> "func"

```julia

julia> PyCall.py\"\"\"
       def fn1(expr):
           return expr.is_Number

       def fn2(expr):
           return expr**2
       \"\"\"

julia> replace(2*sin(x^3), PyCall.py"fn1", PyCall.py"fn2")
     ⎛ 9⎞
4⋅sin⎝x ⎠
```

```julia
julia> PyCall.py\"\"\"
       def fn1(x):
           return x.is_Mul

       def fn2(x):
           return 2*x
       \"\"\"

julia> replace(x*(x*y + 1), PyCall.py"fn1", PyCall.py"fn2")
2⋅x⋅(2⋅x⋅y + 1)
```
"""
function Base.replace(ex::Sym, query::Sym, fn::Function; exact=true, kwargs...)
    ## XXX this is failing!
    ex.replace(query, ↓((args...) ->fn(args...)); exact=exact, kwargs...)
end


function Base.replace(ex::Sym, query::Any, value; exact=true, kwargs...)
    ex.replace(query, value; exact=exact, kwargs...)
end

function Base.replace(ex::Sym, qv::Pair; kwargs...)
    replace(ex, first(qv), last(qv); kwargs...)
end
