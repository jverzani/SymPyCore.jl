module SymPyCore

using SpecialFunctions
using LinearAlgebra
using Markdown
import CommonSolve
import CommonSolve: solve
using CommonEq
using RecipesBase
using Latexify
using TermInterface

include("types.jl")
include("equality.jl")
include("utils.jl")
include("decl.jl")
include("gen_methods.jl")
include("mathops.jl")
include("mathfuns.jl")
include("numbers.jl")
include("matrix.jl")
include("lambdify.jl")
include("patternmatch.jl")
include("plot_recipes.jl")
include("latexify_recipe.jl")


## Staging ground

ask(x::Bool, args...) = x
ask(x::Nothing, args...) = x


## ambiguities detected by Aqua
Sym(x::Base.TwicePrecision)  = Sym(_sympy_.sympify(x))
Sym(x::Base.AbstractChar) = Sym(string(x))
Sym{T}(x::Base.TwicePrecision) where T = Sym{T}(_sympy_.sympify(x))
Sym{T}(x::Base.AbstractChar) where T = Sym{T}(string(x))

SymFunction(x::Base.TwicePrecision) = nothing
SymFunction(x::Base.AbstractChar) = SymFunction(string(x))
SymFunction(x::SymFunction) = x

SymFunction{T}(x::Base.TwicePrecision) where T = nothing
SymFunction{T}(x::Base.AbstractChar) where T = SymFunction{T}(string(x))
SymFunction{T}(x::SymFunction{T}) where T = x


end
