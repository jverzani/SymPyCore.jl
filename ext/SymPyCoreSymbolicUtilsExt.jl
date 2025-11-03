module SymPyCoreSymbolicUtilsExt

import SymbolicUtils
𝐓 = SymbolicUtils.BasicSymbolic

# setup some utilities
import SymPyCore

SymPyCore._issymbol(x::𝐓) = SymbolicUtils.issym(x)

@static if pkgversion(SymbolicUtils) >= v"4"
    SymPyCore._value(x::𝐓) = SymbolicUtils.unwrap_const(x)
    SymPyCore._makesymbol(::Type{𝐓{T}}, 𝑥::Symbol) where {T} = SymbolicUtils.Sym{T}(𝑥; type = Number, shape = SymbolicUtils.ShapeVecT())
else
    SymPyCore._value(x::𝐓) = x
    SymPyCore._makesymbol(::Type{<:𝐓}, 𝑥::Symbol) = SymbolicUtils.Sym{Number}(𝑥)
end

end
