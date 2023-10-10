"""

Plotting of symbolic objects.

The `Plots` package provide a uniform interface to many of `Julia`'s
plotting packages. `SymPy` plugs into `Plots`' "recipes."

The basic goal is that when `Plots` provides an interface for function
objects, this package extends the interface to symbolic expressions.

In particular:


* `plot(ex::Sym, a, b; kwargs...)` will plot a function evaluating `ex` over [a,b]

Example. Here we use the default backend for `Plots` to make a plot:

```julia
using Plots
@syms x
plot(x^2 - 2x, 0, 4)
```



* `plot(ex1, ex2, a, b; kwargs...)` will plot the two expressions in a parametric plot over the interval `[a,b]`.

Example:

```julia
@syms x
plot(sin(2x), cos(3x), 0, 4pi) ## also
```

For a few backends (those that support `:path3d`) a third symbolic
expression may be added to have a 3d parametric plot rendered:

```julia
plot(sin(x), cos(x), x, 0, 4pi) # helix in 3d
```

* `plot(xs, ys, expression)` will make a contour plot (for many backends).

```julia
@syms x y
plot(range(0,stop=5, length=50), range(0,stop=5, length=50), x*y)
```



* To plot the surface  `z=ex(x,y)` over a region we have `Plots.surface`. For example,

```julia
@syms x y
surface(-5:5, -5:5, 25 - x^2 - y^2)
```


* To plot two or more functions at once, the style `plot([ex1, ex2], a, b)` does not work. Rather, use
    `plot(ex1, a, b); plot!(ex2)`, as in:

```julia
@syms x
plot(sin(x), 0, 2pi)
plot!(cos(x))
```

"""
sympy_plotting = nothing
export sympy_plotting


## Recipes for hooking into Plots

@recipe f(::Type{T}, v::T) where {T<:Sym} = lambdify(v)


## for vectors of expressions
## This does not work. See: https://github.com/JuliaPlots/RecipesBase.jl/issues/19
#@recipe f(ss::AbstractVector{Sym}) = lambdify.(ss)
#@recipe  function f{T<:Array{Sym,1}}(::Type{T}, ss::T)  Function[lambdify(s) for s in ss]  end

## --------------------------------------------------
