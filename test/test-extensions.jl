# test extensions

import SymbolicUtils
using SymPyCore: exchange, Sym

@testset "SymbolicUtils exchange" begin
    T = Sym
    𝐓 = SymbolicUtils.BasicSymbolic

    SymbolicUtils.@syms a b
    @test a*cos(b) |> exchange(T) isa T
    @test a*cos(b) |> exchange(T) |> exchange(𝐓) isa 𝐓
end
