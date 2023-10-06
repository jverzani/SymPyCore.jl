# matrix
# SymMatrix has methods to expose.
# XXX has issue with @inferred
# XXX link into pyconvert...

Base.promote_op(::O, ::Type{S}, ::Type{Sym{T}}) where {O,T, S <: Number} = Sym{T}
Base.promote_op(::O, ::Type{Sym{T}}, ::Type{S}) where {O,T, S <: Number} = Sym{T}
Base.promote_op(::O, ::Type{Sym{T}}, ::Type{Sym{T}}) where {O,T} = Sym{T} # This helps out linear alg

Base.eachrow(M::Matrix{T}) where {T <: SymbolicObject} = (M[i,:] for i ∈ 1:size(M,1))
function Base.view(A::AbstractArray{T,N}, I::Vararg{Any,M}) where {T <: SymbolicObject, N,M}
    A[I...] # can't take view!!
end

call_matrix_meth(M::Matrix{T}, meth::Symbol, args...; kwargs...) where {T <: Sym} =
    ↑(getproperty(↓(M), meth)(↓(args)...; ↓ₖ(kwargs)...))


LinearAlgebra.qr(A::AbstractArray{Sym,2}) = ↑(↓(A).QRdecomposition())

# solve Ax=b for x, avoiding generic `lu`, which can be very slow for bigger n values
# fix suggested by @olof3 in issue 355
function LinearAlgebra.:\(A::AbstractArray{Sym,2}, b::AbstractArray{S,1}) where {S}
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

LinearAlgebra.norm(x::AbstractVector{T}, args...; kwargs...) where {T <: SymbolicObject} =
    ↑(getproperty(sympy.Matrix(Tuple(xᵢ for xᵢ ∈ x)), :norm)(↓(args)...; ↓ₖ(kwargs)...))


## Issue #359 so that A  +  λI is of type Sym
Base.:+(A::AbstractMatrix{T}, J::UniformScaling) where {T <: SymbolicObject}    = _sym_plus_I(A,J)
Base.:+(A::AbstractMatrix, J::UniformScaling{T}) where {T <: SymbolicObject}    = _sym_plus_I(A,J)
Base.:+(A::AbstractMatrix{T}, J::UniformScaling{T}) where {T <: SymbolicObject} = _sym_plus_I(A,J)

Base.:-(J::UniformScaling, A::AbstractMatrix{T}) where {T <: SymbolicObject}    = (-A) + J
Base.:-(J::UniformScaling{T}, A::AbstractMatrix) where {T <: SymbolicObject}    = (-A) + J
Base.:-(J::UniformScaling{T}, A::AbstractMatrix{T}) where {T <: SymbolicObject} = (-A) + J

function _sym_plus_I(A::AbstractArray{T,N}, J::UniformScaling{S}) where {T, N, S}
    n = LinearAlgebra.checksquare(A)
    B = convert(AbstractArray{promote_type(T,S),N}, copy(A))
    for i ∈ 1:n
        B[i,i] += J.λ
    end
    B
end
