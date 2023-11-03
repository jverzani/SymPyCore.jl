# Load this from external packages
using SymPyCore
using LinearAlgebra
using SpecialFunctions
using Test

path = @__DIR__
include(joinpath(path, "test-legacy.jl")) # need to clean these up!
include(joinpath(path, "test-core.jl"))
include(joinpath(path, "test-math.jl"))
include(joinpath(path, "test-matrix.jl"))
include(joinpath(path, "test-specialfuncs.jl"))
include(joinpath(path, "test-ode.jl"))
VERSION >= v"1.9.0" && include(joinpath(path, "test-extensions.jl"))
#include(joinpath(path, "test-lambdify.jl"))
#include(joinpath(path, "test-logical.jl"))
#include(joinpath(path, "test-permutations.jl"))
#include(joinpath(path, "test-physics.jl"))
#include(joinpath(path, "test-external-module.jl"))
