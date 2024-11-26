# matrix
# SymMatrix has methods to expose.
# XXX has issue with @inferred
# XXX link into pyconvert...

Base.promote_op(::O, ::Type{S}, ::Type{T}) where {O, T<:Sym, S <: Number} = T
Base.promote_op(::O, ::Type{T}, ::Type{S}) where {O, T<:Sym, S <: Number} = T
Base.promote_op(::O, ::Type{T}, ::Type{T′}) where {O, T<:Sym, T′<:Sym} = T

Base.eachrow(M::Matrix{T}) where {T <: SymbolicObject} = (M[i,:] for i ∈ 1:size(M,1))

# XXX for *some* reason this was a good idea. Doesn't seem to be necessary
# now, but if that reason resurfaces, will have to see
#function Base.view(A::AbstractArray{T,N}, I::Vararg{Any,M}) where {T <: SymbolicObject, N,M}
#    A[I...] # can't take view!!
#end

call_matrix_meth(M::Matrix{T}, meth::Symbol, args...; kwargs...) where {T <: Sym} =
    ↑(getproperty(↓(M), meth)(↓(args)...; ↓ₖ(kwargs)...))


## -- special methods
function LinearAlgebra.transpose(A::AbstractVecOrMat{T}) where {T <: Sym}
    LinearAlgebra.Transpose{T,typeof(A)}(A)
end
function LinearAlgebra.adjoint(A::AbstractVecOrMat{T}) where {T <: Sym}
    LinearAlgebra.Adjoint{T,typeof(A)}(A)
end
Base.promote_op(::Union{typeof(adjoint),typeof(transpose)}, ::Type{T}) where {T<: Sym} = T # issue #77


#LinearAlgebra.qr(A::AbstractArray{<:Sym,2}) = ↑(↓(A).QRdecomposition())

## ----

# XXX what keyword arguments to support?
function LinearAlgebra.eigvecs(A::AbstractMatrix{T}) where {T <: Sym}
    eigs = A.eigenvects()
    hcat((hcat(v...) for (λ,k,v) ∈ eigs)...)
end

# XXX what keyword arguments to support?
function LinearAlgebra.eigvals(A::AbstractMatrix{T}) where {T <: Sym}
    eigs = A.eigenvects()
    vcat((fill(λ, N(k)) for (λ,k,v) ∈ eigs)...)
end

# add sortby
#
function LinearAlgebra.eigen(A::AbstractMatrix{T}) where {T <: Sym}
    LinearAlgebra.Eigen(eigvals(A), eigvecs(A))
end

## ----

## Issue #359 so that A  +  λI is of type Sym
Base.promote_op(::O, ::Type{S}, ::Type{T}) where {O, P, S<:Sym{P}, R, T<:UniformScaling{R}} = S
Base.promote_op(::O, ::Type{T}, ::Type{S}) where {O, P, S<:Sym{P}, R, T<:UniformScaling{R}} = S

## ----
# solve Ax=b for x, avoiding generic `lu`, which can be very slow for bigger n values
# fix suggested by @olof3 in issue 355
# This is causing many ambiguities

function LinearAlgebra.:\(A::AbstractMatrix{<:SymbolicObject},
    b::AbstractVecOrMat)
    _backslash(A,b)
end

# use solve
# lu(A) works, *but* doesn't simplify (https://github.com/JuliaPy/SymPy.jl/issues/355) so can have exponentially growing complexity
function _backslash(A, b::AbstractVector)
    m,n  = size(A)
    x =  [Sym("x$i") for  i in 1:n]
    out = solve(A*x-b, x)
    isempty(out) && throw(SingularException(0)) # Could also return out here?
    ret = Vector{Sym}(undef, n)
    for (i,xᵢ)  in enumerate(x)
        ret[i] =  get(out,  xᵢ, xᵢ)
    end
    return ret
end

function _backslash(A, B::AbstractMatrix)
    hcat([A \ bⱼ for bⱼ in eachcol(B)]...)
end
