

for (pmod, pmeth, jmod, jmeth) ∈ SymPyCore.generic_methods
    @eval begin
        ($(jmod).$(jmeth))(x::Sym, args...; kwargs...) =
            ↑($(pmod).$(pmeth)(↓(x), ↓(args)...; ↓ₖ(kwargs)...))
    end
end

for (pmod, pmeth, jmeth) ∈ SymPyCore.new_exported_methods
    @eval begin
        ($(jmeth))(x::Sym, args...; kwargs...) =
            ↑($(pmod).$(pmeth)(↓(x), ↓(args)...; ↓ₖ(kwargs)...))
        export $(jmeth)
    end
end

for (smeth, jmod, jmeth) ∈ SymPyCore.matrix_meths
    @eval begin
        ($(jmod).$(jmeth))(M::Matrix{T}, args...; kwargs...) where {T <: Sym} =
            ↑(↓(M).$(smeth)(↓(args)...; ↓ₖ(kwargs)...))
    end
end



for (ometh, jmod, jmeth) ∈ SymPyCore.object_methods
    @eval begin
        ($(jmod).$(jmeth))(x::Sym, args...; kwargs...) =
            ↑(↓(x).$(ometh)(↓(args)...; ↓ₖ(kwargs)...))
    end
end

## degree functions (need PI defined)
Base.sinpi(x::Sym) = sin(PI*x)
Base.cospi(x::Sym) = cos(PI*x)
Base.sinc(x::Sym) = iszero(x) ? one(x) : sinpi(x)/(PI*x)
Base.cosc(x::Sym) = cospi(x)/x - sinc(x)/x
Base.deg2rad(x::Sym) = x * PI/180
Base.rad2deg(x::Sym) = x * 180 /  PI

for fn ∈ (:sin,:cos, :tan, :sec, :csc, :cot)
    f = Symbol(string(fn) * "d")
    saf = Symbol("a" * string(fn))
    af = Symbol("a" * string(fn) * "d")
    @eval begin
        (Base.$f)(x::Sym)  = $(sympy).$(fn)(deg2rad(x))
        (Base.$af)(x::Sym) = rad2deg(($sympy).$(saf)(x))
    end
end


## Add methods for "solve functions"
for meth ∈ (:solve, :linsolve, :nonlinsolve, :nsolve, :dsolve)
    m = Symbol(meth)
    @eval begin
        ($meth)(V::AbstractArray{T,N}, args...; kwargs...) where {T <: SymbolicObject, N} = sympy.$meth(V, args...; kwargs...)
        ($meth)(Ts::NTuple{N,T}, args...; kwargs...) where {N, T <: SymbolicObject} =
            sympy.$meth(Ts, args...; kwargs...)
        ($meth)(Ts::Tuple, args...; kwargs...) =
            sympy.$meth(Ts, args...; kwargs...)
    end
end
