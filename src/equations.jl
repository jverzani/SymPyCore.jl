# Define ~ usage
Base.:~(lhs::Number, rhs::Sym) = ~(promote(lhs, rhs)...)
Base.:~(lhs::Sym, rhs::Number) = ~(promote(lhs, rhs)...)
Base.:~(lhs::Sym, rhs::Sym) = Eq(lhs, rhs)
