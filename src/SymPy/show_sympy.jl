function Base.show(io::IO, x::SymbolicObject)
    o = x.o
    out = _sympy_.printing.str.sstr(o) # or .pretty
    out = replace(out, r"\*\*" => "^")
    print(io, out)
end
