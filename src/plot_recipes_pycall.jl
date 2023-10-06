## These are pycall specific. Deprecate!!
## ---------------------



## These functions give acces to SymPy's plotting module. They will work if PyPlot is installed, but may otherwise cause an error

## surface plot xvar = Tuple(Sym, Real, Real)
##
"""

Render a parametrically defined surface plot.

Example:
```
@syms u, v
plot_parametric_surface((u*v,u-v,u+v), (u,0,1), (v,0,1))
```

This uses `PyPlot`, not `Plots` for now.
"""
function plot_parametric_surface(exs::Tuple{Sym,Sym,Sym},
                                 xvar=(-5.0, 5.0),
                                 yvar=(-5.0, 5.0),
                                 args...;
                                 kwargs...)

    sympy.plotting.plot3d_parametric_surface(exs..., args...; kwargs...)

end
export plot_parametric_surface





"""
Plot an implicit equation

```
@syms x y
plot_implicit(Eq(x^2+ y^2,3), (x, -2, 2), (y, -2, 2))
```

"""
plot_implicit(ex, args...; kwargs...) = sympy.plotting.plot_implicit(ex, args...; kwargs...)
export plot_implicit
