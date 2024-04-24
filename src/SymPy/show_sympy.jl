_fix_powers(x) = replace(string(x), r"\*\*" => "^")
sstr(x::SymbolicObject)   = _fix_powers(_sympy_.sstr(↓(x)))
pretty(x::SymbolicObject) = _fix_powers(_sympy_.pretty(↓(x)))
latex(x::SymbolicObject)  = string(_sympy_.latex(↓(x)))
srepr(x::SymbolicObject)  = string(_sympy_.srepr(↓(x)))

function Base.show(io::IO, x::SymbolicObject)
    #out = _sympy_.printing.pretty(x.o) # or .sstr
    out = _sympy_.printing.str.sstr(x.o) # or .pretty
    out = replace(string(out), r"\*\*" => "^")
    print(io, out)
end

function Base.show(io::IO, ::MIME"text/plain", x::SymbolicObject)
    out = _sympy_.printing.pretty(x.o) # or .sstr
    #out = _sympy_.printing.str.sstr(x.o) # or .pretty
    out = replace(string(out), r"\*\*" => "^")
    print(io, out)
end

#=
function Base.show(io::IO,  ::MIME"text/plain", x::Array{T, N}) where {N, T<:SymbolicObject)
    o = x.o
    out = string(_sympy_.printing.str.sstr(o)) # or .pretty
    out = replace(out, r"\*\*" => "^")
    print(io, out)
end
=#

## --------------------------------------------------
## LaTeX printing

function Base.show(io::IO,  ::MIME"text/latex", x::SymbolicObject)
    out = _sympy_.latex(↓(x), mode="inline",fold_short_frac=false)
    print(io, string(out))
end

function  Base.show(io::IO, M::MIME"text/latex", x::AbstractArray{<:Sym})
    show(io, M, sympy.ImmutableMatrix(x))
end

function Base.show(io::IO, ::MIME"text/latex", d::Dict{T,S}) where {T<:SymbolicObject, S<:Any}
    Latex(x::Sym) = latex(x)
    Latex(x) = sprint(io -> show(IOContext(io, :compact => true), x))

    out = "\\begin{equation*}\\begin{cases}"
    for (k,v) in d
        out = out * Latex(k) * " & \\text{=>} &" * Latex(v) * "\\\\"
    end
    out = out * "\\end{cases}\\end{equation*}"
    print(io, as_markdown(out))
end

as_markdown(x) = x# Markdown.parse("``$x``") #???

function toeqnarray(x::AbstractVector{T}) where {T <: SymbolicObject}
    a = join([latex(x[i]) for i in 1:length(x)], "\\\\")
end

function toeqnarray(x::AbstractMatrix{T}) where {T <: SymbolicObject}
    sz = size(x)
    a = join([join(map(latex, x[i,:]), "&") for i in 1:sz[1]], "\\\\")
end
