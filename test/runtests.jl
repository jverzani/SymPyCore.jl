# run tests under SymPyPythonCall only
using SymPyPythonCall

include("runtests-sympycore.jl")

include("aqua.jl")
