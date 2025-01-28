module SymPyCoreSymbolicUtilsExt

import SymbolicUtils
𝐓 = SymbolicUtils.BasicSymbolic

# setup some utilities
import SymPyCore
SymPyCore._issymbol(x::𝐓) = SymbolicUtils.issym(x)
SymPyCore._value(x::𝐓) = x
SymPyCore._makesymbol(::Type{<:𝐓}, 𝑥::Symbol) = SymbolicUtils.Sym{Number}(𝑥)

end
