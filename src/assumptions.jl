##http://docs.sympy.org/dev/_modules/sympy/assumptions/ask.html#ask
Q_predicates = (:antihermitian,
                :bounded, :finite, # bounded deprecated
                :commutative,
                :complex,
                :composite,
                :even,
                :extended_real,
                :hermitian,
                :imaginary,
                :infinitesimal,
                :infinity, :infinite, # :infinity deprecated
                :integer,
                :irrational,
                :rational,
                :algebraic,
                :transcendental,
                :negative,
                :nonzero, :zero,
                :positive,
                :prime,
                :real,
                :odd,
                :is_true,
                :nonpositive,
                :nonnegative
#                :symmetric,
#                :invertible,
#                :singular,
#                :orthogonal,
#                :unitary,
#                :normal,
#                :positive_definite,
#                :upper_triangular,
#                :lower_triangular,
#                :diagonal,
#                :triangular,
#                :unit_triangular,
#                :fullrank,
#                :square,
#                :real_elements,
#                :complex_elements,
#                :integer_elements
)

# macro make_struct(struct_name, schema...)
#     esc(
#         quote
#             struct $(struct_name)
#             $(schema...)
#             end
#         end
#     )

Base.@kwdef struct 𝑄{T}
    _sympy_::T
    antihermitian::Function = (x) ->  ↑(_sympy_.Q.antihermitian(↓(x)))
    finite::Function        = (x) ->  ↑(_sympy_.Q.finite(↓(x)))
    commutative::Function   = (x) ->  ↑(_sympy_.Q.commutative(↓(x)))
    complex::Function       = (x) ->  ↑(_sympy_.Q.complex(↓(x)))
    composite::Function     = (x) ->  ↑(_sympy_.Q.composite(↓(x)))
    even::Function          = (x) ->  ↑(_sympy_.Q.(↓(x)))
    extended_real::Function = (x) ->  ↑(_sympy_.Q.extended_real(↓(x)))
    hermitian::Function     = (x) ->  ↑(_sympy_.Q.hermitian(↓(x)))
    imaginary::Function     = (x) ->  ↑(_sympy_.Q.imaginary(↓(x)))
    infinitesimal::Function = (x) ->  ↑(_sympy_.Q.infinitesimal(↓(x)))
    inifinite::Function     = (x) ->  ↑(_sympy_.Q.inifinite(↓(x)))
    integer::Function       = (x) ->  ↑(_sympy_.Q.integer(↓(x)))
    irrational::Function    = (x) ->  ↑(_sympy_.Q.irrational(↓(x)))
    rational::Function      = (x) ->  ↑(_sympy_.Q.rational(↓(x)))
    algebraic::Function     = (x) ->  ↑(_sympy_.Q.algebraic(↓(x)))
    transcendental::Function = (x) -> ↑(_sympy_.Q.transcendental(↓(x)))
    negative::Function      = (x) ->  ↑(_sympy_.Q.negative(↓(x)))
    nonzero::Function       = (x) ->  ↑(_sympy_.Q.nonzero(↓(x)))
    zero::Function          = (x) ->  ↑(_sympy_.Q.zero(↓(x)))
    positive::Function      = (x) ->  ↑(_sympy_.Q.positive(↓(x)))
    prime::Function         = (x) ->  ↑(_sympy_.Q.prime(↓(x)))
    real::Function          = (x) ->  ↑(_sympy_.Q.real(↓(x)))
    odd::Function           = (x) ->  ↑(_sympy_.Q.odd(↓(x)))
    is_true::Function       = (x) ->  ↑(_sympy_.Q.is_true(↓(x)))
    nonpositive::Function   = (x) ->  ↑(_sympy_.Q.nonpositive(↓(x)))
    nonnegative::Function   = (x) ->  ↑(_sympy_.Q.nonnegative(↓(x)))
    # Matrix things
    symmetric::Function  = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.symmetric(_sympy_.Matrix((↓).(x))))
    invertible::Function = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.invertible(_sympy_.Matrix((↓).(x))))
    orthogonal::Function = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.X(_sympy_.Matrix((↓).(x))))
    unitary::Function    = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.unitary(_sympy_.Matrix((↓).(x))))
    normal::Function     = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.normal(_sympy_.Matrix((↓).(x))))
    positive_definite::Function = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.positive_definite(_sympy_.Matrix((↓).(x))))
    upper_triangular::Function  = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.upper_triangular(_sympy_.Matrix((↓).(x))))
    lower_triangular::Function  = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.lower_triangular(_sympy_.Matrix((↓).(x))))
    diagonal::Function   = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.diagonal(_sympy_.Matrix((↓).(x))))
    triangular::Function = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.triangular(_sympy_.Matrix((↓).(x))))
    square::Function     = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.square(_sympy_.Matrix((↓).(x))))
    real_elements::Function     = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.real_elements(_sympy_.Matrix((↓).(x))))
    complex_elements::Function  = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.complex_elements(_sympy_.Matrix((↓).(x))))
    integer_elements::Function  = (x::Array{<:Sym,2}) -> ↑(_sympy_.Q.integer_elements(_sympy_.Matrix((↓).(x))))
end
