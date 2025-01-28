Base.promote_rule(::Type{S}, ::Type{T})  where {S<:Number, T<:Sym}= T
Base.promote_rule(::Type{S}, ::Type{T})  where {S<:AbstractIrrational, T<:Sym}= T
Base.promote_rule(::Type{Bool}, ::Type{T}) where {T <: Sym} = T
Base.promote_rule(::Type{Bool}, ::Type{T}) where {T <: Sym{Nothing}} = Sym

Base.promote_rule(::Type{Nothing}, ::Type{T}) where {T <: Sym} = T
Base.promote_rule(::Type{Nothing}, ::Type{T}) where {T <: Sym{Nothing}} = Nothing

Base.convert(::Type{T}, o::Number) where {T <: Sym} = Sym(o)
Base.convert(::Type{T}, o::Number) where {P, T <: Sym{P}} = Sym{P}(o)
Base.convert(::Type{T}, o::Nothing) where {T <: Sym} = Sym(nothing)


import Base: +, -, *, /, //, \, ^, inv
+(x::T, y::SymbolicObject) where {T <: SymbolicObject} = T(↓(x) + ↓(y))
*(x::T, y::SymbolicObject) where {T <: SymbolicObject} = T(↓(x) * ↓(y))
-(x::T, y::SymbolicObject) where {T <: SymbolicObject} = T(↓(x) - ↓(y))
(-)(x::T) where {T <: SymbolicObject}     = T(-↓(x))
/(x::T, y::SymbolicObject) where {T <: SymbolicObject} = T(↓(x) / ↓(y))
^(x::T, y::SymbolicObject)  where {T <: SymbolicObject} = T(↓(x) ^ ↓(y))
^(x::SymbolicObject, y::Rational) = x^convert(Sym,y)
#^(x::Sym, y::Integer) = x^convert(Sym,y) # no Union{Integer, Rational}, as that has ambiguity
//(x::Sym, y::Int) = x / Sym(y)
//(x::Sym, y::Rational) = x / Sym(y)
//(x::Sym, y::Sym) = x / y

\(x::Sym, y::Sym) = (y'/x')' # ?

Base.inv(x::Sym) = ↑(↓(x).__pow__(-1))

# special case Boolean; issue   351
# promotion for Boolean here is to 0 or  1,  not False,  True
+(x::Bool, y::Sym)::Sym = Sym(Int(x)) + y #Sym(Int(x)).__add__(y)
*(x::Bool, y::Sym)::Sym = Sym(Int(x)) * y #.__mul__(y)
-(x::Bool, y::Sym)::Sym = Sym(Int(x)) - y #.__sub__(y)
/(x::Bool, y::Sym)::Sym = Sym(Int(x)) / y #.__truediv__(y)
^(x::Bool, y::Sym)::Sym = Sym(Int(x))^y   #.__pow__(y)
+(x::Sym, y::Bool)::Sym = ↑(↓(x).__add__(Int(y)))
*(x::Sym, y::Bool)::Sym = ↑(↓(x).__mul__(Int(y)))
-(x::Sym, y::Bool)::Sym = ↑(↓(x).__sub__(Int(y)))
/(x::Sym, y::Bool)::Sym = ↑(↓(x).__truediv__(Int(y)))
^(x::Sym, y::Bool)::Sym = ↑(↓(x).__pow__(Int(y)))

# strict conversion Sym(true) only
function Base.convert(::Type{Bool}, x::Sym{T}) where {T}
    y = ↓(x)
    hasproperty(y, :is_Boolean) && return _convert(Bool, y)
    hasproperty(y, :__bool__) && return _convert(Bool, y)
    return false
end
