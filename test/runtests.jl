if lowercase(get(ENV, "CI", "false")) == "true"
    include("install_dependencies.jl")
end

using SymPy
using Test
import SymbolicUtils  # test loading extension

include("tests.jl")
include("test-math.jl")
include("test-matrix.jl")
include("test-logical.jl")
#include("test-specialfuncs.jl")  ## XXX NEEDS WORK
#include("test-permutations.jl")
include("test-physics.jl")
include("test-external-module.jl")
include("test-latexify.jl")
include("test-ode.jl")