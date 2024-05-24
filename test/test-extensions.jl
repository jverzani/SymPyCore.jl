# test extensions

import SymbolicUtils

@testset "SymbolicUtils" begin
    @syms x
    @test !SymbolicUtils.iscall(x) # istree deprecated
    @test SymbolicUtils.iscall(sin(x))
    @test SymbolicUtils.operation(sin(x)) == sin
    @test only(SymbolicUtils.arguments(sin(x))) == x
end
