## Equality involves
## =  assignment has no change
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
    a, b = convert(Bool3, x), convert(Bool3, y)
    a == b == true  && return true
    a == b == false && return true

    if hasproperty(↓(x), "equals") && hasproperty(↓(y), "equals")
        u = ↑(↓(x).equals(↓(y)))
        v = convert(Bool3, u)
        v == true && return true
        v == false && return false
    end
    return (hash(x) == hash(y))
end

# Bool3: used with ==; true, false or nothing
struct Bool3 end
function Base.convert(::Type{Bool3}, x::Sym{T}) where {T}
    y = ↓(x)
    if hasproperty(y, "is_Boolean")
        if _convert(Bool, y.is_Boolean)
            return _convert(Bool, y)
        end
    elseif hasproperty(y, "__bool__")
        _convert(Bool, y != ↓(Sym(nothing))) && return _convert(Bool, y)
    end
    return nothing
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
    if isinf(x)
        sign(x) == -1 && return true
        sign(x) == 1  && return false
    end
    if isinf(y)
        sign(y) == -1 && return false
        sign(y) == 1  && return true
    end

    u,v = convert(Bool3, x), convert(Bool3, y)
    u != nothing && v != nothing && return isless(u,v)

    if x.is_real == true && y.is_real == true
        return Lt(x, y) == Sym(true) ? true : false
    end

    if hasproperty(↓(x), "compare")
        out = x.compare(y)
    elseif hasproperty(↓(y), "compare")
        out = - (y.compare(x))
    else
        @show :huh_shouldnt_get_here, x, y
        out = -1
    end

    out == -1  ? true : false

end

Base.:<(x::S, y) where {T,S<:SymbolicObject{T}} = <(promote(x,y)...)
Base.:<(x, y::S) where {T, S<:SymbolicObject{T}} = <(promote(x,y)...)
Base.:<(x::S, y::Missing) where {T,S<:SymbolicObject{T}} = missing
Base.:<(::Missing, y::S)  where {T,S<:SymbolicObject{T}} = missing
function Base.:<(x::S, y::S) where {T,S<:SymbolicObject{T}}

    (isnan(x) || isnan(y)) && return false
    isless(x, y)

end
