module SymPyCore

using SpecialFunctions
using LinearAlgebra
using Markdown
import CommonSolve
import CommonSolve: solve
using CommonEq
using RecipesBase
using Latexify

include("types.jl")
include("utils.jl")
include("decl.jl")
include("gen_methods.jl")
include("mathops.jl")
include("mathfuns.jl")
include("numbers.jl")
include("equations.jl")
include("assumptions.jl")
include("lambdify.jl")
include("plot_recipes.jl")
include("latexify_recipe.jl")

include("matrix.jl")
# include("patternmatch.jl")
# include("permutations.jl")
# include("physics.jl")


# XXX Do we need these?
# include("constructors.jl")
# include("generic.jl")
# include("arithmetic.jl")
# include("conveniences.jl")
# include("logical.jl")
# include("introspection.jl")


## Staging ground

ask(x::Bool, args...) = x
ask(x::Nothing, args...) = x


# Steal this idea from ModelingToolkit
# better than the **hacky** f'(0) stuff
"""
    Differential(x)

Use to find (partial) derivatives.

## Example
```
@syms x y u()
Dx = Differential(x)
Dx(u(x,y))  # resolves to diff(u(x,y),x)
Dx(u)       # will evaluate diff(u(x), x)
```
"""
struct Differential
    x::Sym
end
(∂::Differential)(u::Sym) = diff(u, ∂.x)
(∂::Differential)(u::SymFunction) = diff(u(∂.x), ∂.x)
export Differential



end
