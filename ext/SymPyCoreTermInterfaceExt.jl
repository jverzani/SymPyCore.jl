module SymPyCoreTermInterfaceExt

using SymPyCore
import TermInterface

#==
Check if x represents an expression tree. If returns true, it will be assumed that operation(::T) and arguments(::T) methods are defined. Defining these three should allow use of TermInterface.simplify on custom types. Optionally symtype(x) can be defined to return the expected type of the symbolic expression.
==#
function TermInterface.iscall(x::SymPyCore.Sym)
    SymPyCore._iscall(x)
end

#==
Returns the head of the S-expression.

In other symbolic expression languages, such as SymbolicUtils.jl, the head of a node can correspond to operation and children can correspond to arguments.
==#
TermInterface.head(ex::SymPyCore.SymbolicObject) = TermInterface.operation(ex)
TermInterface.children(ex::SymPyCore.SymbolicObject) = TermInterface.arguments(ex)

#=
Returns true if x is an expression tree. If true, head(x) and children(x) methods must be defined for x. Optionally, if x represents a function call, iscall(x) should be true, and operation(x) and arguments(x) should also be defined.
=#
function TermInterface.isexpr(ex::SymPyCore.SymbolicObject)
    TermInterface.iscall(ex) && return true

    return false
end


#==
Returns the head (a function object) performed by an expression tree. Called only if iscall(::T) is true. Part of the API required for simplify to work. Other required methods are arguments and iscall
==#
function TermInterface.operation(ex::SymPyCore.SymbolicObject)
    SymPyCore._operation(ex)
end


#==
Returns the arguments (a Vector) for an expression tree. Called only if iscall(x) is true. Part of the API required for simplify to work. Other required methods are operation and iscall
==#
function TermInterface.arguments(ex::SymPyCore.SymbolicObject)
    SymPyCore._arguments(ex)
end

#==
Constructs an expression. `T` is a constructor type, `head` and `children` are
the head and tail of the S-expression.
`metadata` is any metadata attached to this expression.

Note that `maketerm` may not necessarily return an object of type `T`. For example,
it may return a representation which is more efficient.

This function is used by term-manipulation routines to construct terms generically.
In these routines, `T` is usually the type of the input expression which is being manipulated.
For example, when a subexpression is substituted, the outer expression is re-constructed with
the sub-expression. `T` will be the type of the outer expression.

Packages providing expression types _must_ implement this method for each expression type.

Giving `nothing` for `metadata` should result in a default being selected.
==#
function TermInterface.maketerm(T::Type{<:SymPyCore.SymbolicObject}, head, args, metadata)
    SymPyCore._similarterm(T, head, args, metadata)
end


end
