# test extensions

import TermInterface

@testset "TermInterface" begin
    @syms x
    @test !TermInterface.iscall(x) # istree deprecated
    @test TermInterface.iscall(sin(x))
    @test TermInterface.operation(sin(x)) == sin
    @test only(TermInterface.arguments(sin(x))) == x
end
