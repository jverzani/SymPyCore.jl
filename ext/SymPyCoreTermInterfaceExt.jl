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
f x is a term as defined by iscall(x), exprhead(x) must return a symbol, corresponding to the head of the Expr most similar to the term x. If x represents a function call, for example, the exprhead is :call. If x represents an indexing operation, such as arr[i], then exprhead is :ref. Note that exprhead is different from operation and both functions should be defined correctly in order to let other packages provide code generation and pattern matching features.
function TermInterface.exprhead(x::SymPyCore.SymbolicObject) # deprecated
    :call # this is not right
end
==#

#==
Returns the head (a function object) performed by an expression tree. Called only if iscall(::T) is true. Part of the API required for simplify to work. Other required methods are arguments and iscall
==#
function TermInterface.operation(x::SymPyCore.SymbolicObject)
    SymPyCore._operation(x)
end


#==
Returns the arguments (a Vector) for an expression tree. Called only if iscall(x) is true. Part of the API required for simplify to work. Other required methods are operation and iscall
==#
function TermInterface.arguments(x::SymPyCore.SymbolicObject)
    SymPyCore._arguments(x)
end

#==
Construct a new term with the operation f and arguments args, the term should be similar to t in type. if t is a TermInterface.Term object a new Term is created with the same symtype as t. If not, the result is computed as f(args...). Defining this method for your term type will reduce any performance loss in performing f(args...) (esp. the splatting, and redundant type computation). T is the symtype of the output term. You can use TermInterface.promote_symtype to infer this type. The exprhead keyword argument is useful when creating Exprs.
==#
function TermInterface.maketerm(t::SymPyCore.SymbolicObject, f, args;
                                   metadata=nothing, exprhead=:call)
    SymPyCore._similarterm(t, f, args; metadata=metadata, exprhead=exprhead)
end


end
