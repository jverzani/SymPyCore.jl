module SymPyCoreSymbolicUtilsExt

import SymPyCore
import SymbolicUtils

# set up so exchange will work

function SymPyCore.makesym(T::Type{<:SymbolicUtils.BasicSymbolic}, 𝑥::Symbol, m=nothing)
    SymbolicUtils.Sym{Number}(𝑥) # add metadata
end

function SymPyCore.is_symbolic_variable(x::SymbolicUtils.BasicSymbolic)
     !SymPyCore.TermInterface.isexpr(x)
end

function SymPyCore.symbol_metadata(x::SymbolicUtils.BasicSymbolic)
    SymPyCore.is_symbolic_variable(x) || throw(ArgumentError("not a symbol"))
    x.name, x.metadata
end

function SymPyCore.is_symbolic_number(x::SymbolicUtils.BasicSymbolic)
    isa(x,Number)
end

function SymPyCore.as_number(x::SymbolicUtils.BasicSymbolic)
    x
end




end
