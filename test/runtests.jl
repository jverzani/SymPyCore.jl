# run tests under SymPyPythonCall only
using SymPyPythonCall

include("runtests-sympycore.jl")

VERSION >= v"1.9.0" && include(joinpath(path, "test-extensions.jl"))
include("aqua.jl")
