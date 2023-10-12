## Equality invovles
## =  assignement has no change
## ==  - we want to promote to Sym to compare
## hash - call out to
## ===
## isequal
## isless

## Equality
#=
Generic equality operator. Falls back to ===. Should be implemented for all types with a notion of equality, based on the abstract value
  that an instance represents. For example, all numeric types are compared by numeric value, ignoring type. Strings are compared as sequences
  of characters, ignoring encoding. For collections, == is generally called recursively on all contents, though other properties (like the
  shape for arrays) may also be taken into account.

This operator follows IEEE semantics for floating-point numbers: 0.0 == -0.0 and NaN != NaN.
=#
import Base: ==
Base.:(==)(x::S, y) where {T, S<:SymbolicObject{T}}  = ==(promote(x,y)...)
Base.:(==)(x, y::S) where {T, S<:SymbolicObject{T}} = ==(promote(x,y)...)
Base.:(==)(x::S, y::Number) where {T, S<:SymbolicObject{T}}  = ==(promote(x,y)...)
Base.:(==)(x::Number, y::S) where {T, S<:SymbolicObject{T}} = ==(promote(x,y)...)
Base.:(==)(x::S, y::Missing) where {T, S<:SymbolicObject{T}}  = missing
Base.:(==)(x::Missing, y::S) where {T, S<:SymbolicObject{T}} = missing

function Base.:(==)(x::SymbolicObject, y::SymbolicObject)

    isnan(x) && isnan(y) && return false

    if hasproperty(↓(x), "is_Boolean") && convert(Bool, ↑(↓(x).is_Boolean))
        u = convert(Bool, x)
        hasproperty(↓(y), "is_Boolean") && convert(Bool, ↑(↓(y).is_Boolean)) || return false
        v = convert(Bool, y)
        return u == v
    end

    if hasproperty(↓(x), "equals")
        !hasproperty(↓(y), "equals") && return false
        ↓(x).equals == ↓(y).equals || return false
        u = x.equals(y)
        return convert(Bool, u == Sym(true))
    end

    return (hash(x) == hash(y))
end

#=
Similar to ==, except for the treatment of floating point numbers and
of missing values. isequal treats all floating-point NaN values as
equal to each other, treats -0.0 as unequal to 0.0, and missing as
equal to missing. Always returns a Bool value.
=#
function Base.isequal(x::T, y::T) where {T <: SymbolicObject}
    isnan(x) && isnan(y) && return true
    x == y
end


Base.isless(x::S, y) where {T,S<:SymbolicObject{T}} = isless(promote(x,y)...)
Base.isless(x, y::S) where {T, S<:SymbolicObject{T}} = isless(promote(x,y)...)
Base.isless(x::S, y::Missing) where {T,S<:SymbolicObject{T}} = true
Base.isless(::Missing, y::S)  where {T,S<:SymbolicObject{T}} = false
function Base.isless(x::S, y::S) where {T,S<:SymbolicObject{T}}

    (isnan(x) || isnan(y)) && return !isnan(x)

    if x.is_real == true && y.is_real == true
        return Lt(x, y) == Sym(true) ? true : false
    end

    if hasproperty(↓(x), "compare")
        out = x.compare(y)
    elseif hasproperty(↓(y), "compare")
        out = - (y.compare(x))
    else
        @show :huh, x, y
        out = -1
    end

    out == -1  ? true : false

end
