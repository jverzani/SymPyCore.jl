using Test
using LinearAlgebra
using SparseArrays

@testset "Matrix" begin
    ## matrices
    @syms x y
    A = [x 1; 1 x]
    B = [x 1; 0 2x]
    v = [x, 2]

    ## These fail for older installations of SymPy
    @test simplify(det(A)) == x^2 - 1

    ## we use inverse for A[:inv]()

    # aliased to use inverse
    @test simplify.(inv(A) * A) ==  [1 0; 0 1]
    @test simplify.(A * inv(A)) == [1 0; 0 1]
    ##XXX    @test simplify.(A[:inv]() - inv(A)) == zeros(2, 2)

    @test adjoint(B) == [adjoint(x) 0; 1 adjoint(2x)]
    @test adjoint(B) == B'
    @test eltype(adjoint(A)) == eltype(A)
    @test eltype(transpose(A)) == eltype(A)


    @test A.dual() == sympy.zeros(2, 2)


    A1 = Sym[25 15 -5; 15 18 0; -5 0 11]
    r = A1.cholesky()
    @test r*r.transpose() == A1


    #    s = LUsolve(A, v)
    s = A.LUsolve(B)
    @test simplify.(A * s) == B

    # norm
    @test norm(A) == sqrt(2 * abs(x)^2 + 2)
    # test norm for different subtypes of AbstractArray
    ## XXX @test norm(A) == norm(Symmetric(A)) LinearAlgebra.Symmetric no long works
    @test norm(A) == norm(view(A, :, :))

    # abs
    @test all(convert.(Bool, abs.(A) .≧ 0))
    @test abs.(A) == abs.(view(A, :, :))

    # is_lower, is_square, is_symmetric much slower than julia only counterparts. May deprecate, but for now they are here
    @syms x::complex # specifically not real
    @test A.is_lower == istril(A)
    @test A.is_square == true
    #@test A.is_symmetric() != issymmetric(A)

    @syms x::real
    A = [x 1; 1 x]
    @test A.is_symmetric() == issymmetric(A)

    @test Set(eigvals(A)) == Set([x-1, x+1])

    # issue with transpose being non-typestable
    @test eltype(transpose(A)) == eltype(A)
    @test eltype(Symmetric(A)) == eltype(A)

    #numerical tests
    M = Sym[1 0 0; 0 1 0; 0 0 x]
    evecs = eigvecs(M)
    @test evecs[:,1] == [1, 0, 0]


    A = Sym[1 2 3; 3 6 2; 2 0 1]
    q, r = A.QRdecomposition()
    @test q * r == A
    @test abs(det(q)) == 1


    # using sympy.Matrix
    L = collect(sympy.Matrix.([[2,3,5], [3,6,2], [8,3,6]]))

    # for v0.4, the vector type is not correctly inferred
    #L = Vector{Sym}[Sym[2,3,5], Sym[3,6,2], Sym[8,3,6]]
    # L = collect(sympy.Matrix.(([[2,3,5]], [[3,6,2]], [[8,3,6]]]))

    L = (Sym[2 3 5],Sym[3 6 2], Sym[8 3 6])
    out = sympy.GramSchmidt(L, true)  # qualify, as L not SymbolicObject type
    for i = 1:3, j = i:3
        @test out[i].dot(out[j]) == (i == j ? 1 : 0)
    end

    A = Sym[4 3; 6 3]
    L, U, _ = A.LUdecomposition()
    @test L == Sym[1 0; 3//2 1]

    A = Sym[1 0; 0 1] * 2
    B = Sym[1 2; 3 4]
    @test A.diagonal_solve(B) == B/2

    M = Sym[1 2 0; 0 3 0; 2 -4 2]
    P, D = M.diagonalize()
    @test D == [1 0 0; 0 2 0; 0 0 3]
    @test P == [-1 0 -1; 0 0 -1; 2 1  2]
    @test D == inv(P) * M * P

    # test SymPy's expm against Julia's expm
    A = [1 2 0; 0 3 0; 2 -4 2]
    M = Sym.(A)
    ## no exp(M)!
    U = M.exp() - exp(A)
    @test maximum(abs.(N.(U))) <= 1e-12

    @syms x, y
    M = [x y; 1 0]
    @test integrate.(M, x) == [x^2/2 x*y; x 0]
    @test integrate.(M, Ref((x, 0, 2))) == [2 2y; 2 0]


    M = Sym[1 3 0; -2 -6 0; 3 9 6]
    @test M.nullspace()[1] ==  reshape(Sym[-3, 1, 0], 3, 1)


    M = Sym[1 2 0; 0 3 0; 2 -4 2]
    # M.cofactor  uses 0-based indexing!
    i, j = 1, 2
    @test M.cofactor(i, j) == (-1)^(i+j) * det(M[setdiff(1:3, i+1), setdiff(1:3, j+1)])
    @test M.adjugate() / M.det() == M.inv()

    M = Sym[ 6  5 -2 -3;
            -3 -1  3  3;
             2  1 -2 -3;
            -1  1  5  5]

    P, J = M.jordan_form()
    @test J == [2 1 0 0;
                0 2 0 0;
                0 0 2 1;
                0 0 0 2]
    @test J == inv(P) * M * P

    ρ, ϕ = symbols("rho, phi")
    X = [ρ*cos(ϕ), ρ*sin(ϕ), ρ^2]
    Y = [ρ, ϕ]
    @test X.jacobian(Y) ==   [cos(ϕ) -ρ*sin(ϕ);
                              sin(ϕ)  ρ*cos(ϕ);
                                  2ρ       0]
    X = [ρ*cos(ϕ), ρ*sin(ϕ)]
    @test convert(Matrix{Sym}, X.jacobian(Y)) == [cos(ϕ) -ρ*sin(ϕ);
                                                  sin(ϕ)  ρ*cos(ϕ)]
    @test X.jacobian(Y) == view(X, :, :).jacobian(view(Y, :, :))

    ## Issue   #359
    if VERSION >= v"1.2"
        @syms a
        A1 = [a 1; 1 a]
        # The first six cases work
        @test isa(A1 + a*I, Matrix{<:Sym})
        @test isa(A1 - a*I, Matrix{<:Sym})
        @test isa(-A1 + a*I, Matrix{<:Sym})
        @test isa(-A1 - a*I, Matrix{<:Sym})
        @test isa(-a*I + A1, Matrix{<:Sym})
        @test isa(a*I + A1, Matrix{<:Sym})
        @test isa(a*I - A1, Matrix{<:Sym})
        @test isa(-a*I - A1, Matrix{<:Sym})

        A2 = [1 2; 2 1]
        @test isa(A2 + a*I, Matrix{<:Sym})
        @test isa(A2 - a*I, Matrix{<:Sym})
        @test isa(-A2 + a*I, Matrix{<:Sym})
        @test isa(-A2 - a*I, Matrix{<:Sym})
        @test isa(-a*I + A2, Matrix{<:Sym})
        @test isa(a*I + A2, Matrix{<:Sym})
        @test isa(a*I - A2, Matrix{<:Sym})
        @test isa(-a*I - A2, Matrix{<:Sym})

    end

    ## Issue #397 adjoint losing type
    A = ones(Sym, 1, 1)
    @test A * A' isa Matrix{<:Sym}

    # issue SymPyCore #77 adjoint of sparse losing type
    @syms x
    m = sparse([1],[1],[x], 2,2)
    @test eltype(m') <: Sym
    @test m + m' == m' + m

    # XXX No SymMatrix?
    # ## Issue 413 with matrix exponential; SymMatrix multiplication
    # @syms a
    # A,A1 = [1 0; 0 a], [1 1; a 2]
    # @test exp(A) == [exp(Sym(1)) 0; 0 exp(a)]
    # B,B1 = convert(SymMatrix,A), convert(SymMatrix,A1)
    # @test B*B1 == convert(SymMatrix, A*A1)

    ## Issue #462 missing pytypemapping
    U = sympy.Matrix(sympy.MatrixSymbol("U",2,2))
    @test U isa Matrix{<:Sym}

    ## Issue 495 with eigenvals
    a = Sym[-5 -6 3; 3 4 -3; 0 0 -2]
    ls = eigvals(a)
    @test ls == sort(ls)
    vs = eigvecs(a)
    for i ∈ 1:3
        λ, v = ls[i], vs[:,i]
        @test (a * v - λ * v == 0 *v)
    end


    @syms a[1:2,1:2]
    ls = eigvals(a)
    vs = eigvecs(a)
    @test simplify.(vs * Diagonal(ls) * inv(vs) -a) == 0*a

    # issue #41 with views
    A = zeros(symtype(), 2, 2)
    A[1,1] = 1
    @test A == [1 0; 0 0]
    A[2,:] .= 2
    @test A == [1 0; 2 2]
end
