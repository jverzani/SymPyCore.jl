# test extensions

import SymbolicUtils

@testset "SymbolicUtils" begin
    @syms x
    @test !SymbolicUtils.istree(x)
    @test SymbolicUtils.istree(sin(x))
    @test SymbolicUtils.operation(sin(x)) == sin
    @test only(SymbolicUtils.arguments(sin(x))) == x
end
