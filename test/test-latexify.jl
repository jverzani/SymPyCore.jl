using Test

@testset "Latexify" begin
  @syms α
  @test_nowarn SymPyCore.Latexify.latexify(- 3/(8*α) + 1/(8*α^2))
  @test  occursin("\\cdot", SymPyCore.Latexify.latexify(- 3/(8*α) + 1/(8*α^2), cdot=true))
  @test !occursin("\\cdot", SymPyCore.Latexify.latexify(- 3/(8*α) + 1/(8*α^2), cdot=false))
end
