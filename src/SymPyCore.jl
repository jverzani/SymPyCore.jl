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
include("equality.jl")
include("utils.jl")
include("decl.jl")
include("gen_methods.jl")
include("mathops.jl")
include("mathfuns.jl")
include("numbers.jl")
include("matrix.jl")
include("assumptions.jl")
include("lambdify.jl")
include("patternmatch.jl")
include("plot_recipes.jl")
include("latexify_recipe.jl")


## Staging ground

ask(x::Bool, args...) = x
ask(x::Nothing, args...) = x


end
