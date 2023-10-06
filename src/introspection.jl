# to keep SymPY.Introspection alive
Base.@kwdef struct Introspection{T}
    _sympy_::T
    funcname::Function  = (x::Sym) -> SymPyCore.funcname(x)
    func::Function      = (x::Sym) -> SymPyCore.func(x)
    args::Function      = (x::Sym) -> SymPyCore.args(x)
    class::Function     = (x::Sym) -> SymPyCore.class(x)
    classname::Function = (x::Sym) -> SymPyCore.classname(x)
end
