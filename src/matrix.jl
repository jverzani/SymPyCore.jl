# matrix
# SymMatrix has methods to expose.
# XXX has issue with @inferred
# XXX link into pyconvert...

Base.promote_op(::O, ::Type{S}, ::Type{T}) where {O, T<:Sym, S <: Number} = T
Base.promote_op(::O, ::Type{T}, ::Type{S}) where {O, T<:Sym, S <: Number} = T
Base.promote_op(::O, ::Type{T}, ::Type{T′}) where {O, T<:Sym, T′<:Sym} = T

# Base.promote_op(::O, ::Type{S}, ::Type{T}) where {O, T<:Sym, S <: Number} =
#     Sym{T}
# Base.promote_op(::O, ::Type{Sym{T}}, ::Type{S}) where {O, T, S <: Number} =
#     Sym{T}
# Base.promote_op(::O, ::Type{Sym{T}}, ::Type{Sym{T}}) where {O,T} =
#     Sym{T} # This helps out linear alg

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


LinearAlgebra.qr(A::AbstractArray{Sym,2}) = ↑(↓(A).QRdecomposition())

# solve Ax=b for x, avoiding generic `lu`, which can be very slow for bigger n values
# fix suggested by @olof3 in issue 355
function LinearAlgebra.:\(A::AbstractMatrix{T}, b::AbstractVector) where {T<:Sym}
    _backslash(A,b)
end
function _backslash(A,b)
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

# function LinearAlgebra.:\(A::AbstractArray{T,2}, B::AbstractArray{S,2}) where {T <: Sym, S}
#     hcat([A \ bⱼ for bⱼ in eachcol(B)]...)
# end

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


## Issue #359 so that A  +  λI is of type Sym
Base.:+(A::AbstractMatrix{T}, J::UniformScaling) where {T <: SymbolicObject}    = _sym_plus_I(A,J)
Base.:+(A::AbstractMatrix, J::UniformScaling{T}) where {T <: SymbolicObject}    = _sym_plus_I(A,J)
Base.:+(A::AbstractMatrix{T}, J::UniformScaling{T′}) where {T <: SymbolicObject, T′ <: SymbolicObject} = _sym_plus_I(A,J)

## ----


Base.:-(J::UniformScaling, A::AbstractMatrix{T}) where {T <: SymbolicObject}    = (-A) + J
Base.:-(J::UniformScaling{T}, A::AbstractMatrix) where {T <: SymbolicObject}    = (-A) + J
Base.:-(J::UniformScaling{T}, A::AbstractMatrix{T′}) where {T <: SymbolicObject,T′ <: SymbolicObject} = (-A) + J

function _sym_plus_I(A::AbstractArray{T,N}, J::UniformScaling{S}) where {T, N, S}
    n = LinearAlgebra.checksquare(A)
    B = convert(AbstractArray{promote_type(T,S),N}, copy(A))
    for i ∈ 1:n
        B[i,i] += J.λ
    end
    B
end

## ----
## handle ambiguities -- whack-a-mole?
## There are still a few to manage
Base.:+(A::LinearAlgebra.Diagonal{S, V}, J::UniformScaling{T}) where {S, V<:AbstractVector{S}, T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.UpperHessenberg, J::UniformScaling{T}) where {T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.UpperHessenberg{U,V}, J::UniformScaling{T}) where {U,V,T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.Tridiagonal{S, V}, J::UniformScaling{T}) where {S, V<:AbstractVector{S}, T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.SymTridiagonal{S, V}, J::UniformScaling{T}) where {S, V<:AbstractVector{S}, T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.UnitLowerTriangular{S, V}, J::UniformScaling{T}) where {S, V, T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.UnitLowerTriangular{S, V}, J::UniformScaling{T}) where {S, V<:AbstractMatrix{S}, T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.UnitUpperTriangular, J::UniformScaling{T}) where {T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.Bidiagonal, J::UniformScaling{T}) where {T<:SymbolicObject} = _sym_plus(A,J)
Base.:+(A::LinearAlgebra.BitMatrix, J::UniformScaling{T}) where {T<:SymbolicObject} = _sym_plus(A,J)

#
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.BitMatrix) where {T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.Diagonal) where {T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.Diagonal{U,V}) where {U,V,T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.Tridiagonal) where {T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.Tridiagonal{U,V}) where {U,V,T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.SymTridiagonal) where {T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.SymTridiagonal{U,V}) where {U,V,T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.Bidiagonal) where {T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.Bidiagonal{U,V}) where {U,V,T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.UpperHessenberg) where {T<:SymbolicObject} = (-A) + J
Base.:-(J::LinearAlgebra.UniformScaling{T}, A::LinearAlgebra.UpperHessenberg{U,V}) where {U,V,T<:SymbolicObject} = (-A) + J

#
Base.:\(A::LinearAlgebra.Bidiagonal{T,V}, x::AbstractVector) where {T<:SymbolicObject, V<:AbstractVector{T}} = _backslash(A,x)
Base.:\(A::LinearAlgebra.Tridiagonal{T,V}, x::AbstractVector) where {T<:SymbolicObject, V<:AbstractVector{T}} = _backslash(A,x)
Base.:\(A::LinearAlgebra.SymTridiagonal{T,V}, x::AbstractVector) where {T<:SymbolicObject, V<:AbstractVector{T}} = _backslash(A,x)

#
Base.:\(A::Union{LinearAlgebra.Adjoint{T, <:LinearAlgebra.Bidiagonal}, LinearAlgebra.Transpose{T, <:LinearAlgebra.Bidiagonal}}, x::AbstractVector) where {T<:Sym} = _backslash(A, x)
