# Some sample usage

The SymPy Tutorial Translation covers more, but this shows some basics

!!! note
    We use SymPy for the Python package and `SymPy` to refer to an implementation in `Julia` using `SymPyCore`. (Currently `SymPy` stands for either `SymPyPyCall` and `SymPy_PythonCall`, though that should evolve.)

## Overview

`SymPy` uses one of two glue packages between `Julia` and `Python` to provide a `Julia`n interface to SymPy, a `Python` library for symbolic math. To do so we have:

* Symbolic values in `Python` are wrapped in a subtype, typically `Sym{T}`, of `SymbolicObject{T}` or a container holding such values. The conversion from a Python object to a symbolic object in `Julia` is implemented in the `↑` method. Similarly, the  `↓` method takes a symbolic object and finds a Python counterpart for passing to underlying methods of SymPy.

* For many generic methods in `Base`, `LinearAlgebra`, or `SpecialFunctions` -- when there is a SymPy counterpart -- a method is made which dispatches on its first argument being symbolic. The basic pattern is akin to `Base.sin(x::Sym) = sympy.sin(x)` where `sympy.sin(x)` is essentially `↑(_sympy_.sin(↓(x)))` -- here `_sympy_` is the object holding the reference to the Python module, and `_sympy_.sin` the reference to its `sin` function. The `sympy` object handles the up and down conversions.

* For many primary functions of SymPy, such as `simplify`, `factor`, `expand`, etc., new methods are made for use within `Julia`. Less foundational functions of SymPy, such as `trigsimp` or `expand_log` are referenced as `sympy.trigsimp` or `sympy.expand_log`. The `sympy` object is not a `Julia` module, but this use is reminiscent of qualifying a function from a module.

* SymPy, being a Python library, has many methods for its objects. For example, a symbolic object, `obj` has a `diff` method accessed by `obj.diff(...)`. A object also has a `subs` method for substitution, accessed through `obj.subs(...)`. The same "dot" style is used for Python and `Julia`.

* For commonly used object methods, a `Julia`n interface is defined. For `diff` a `diff(obj::Sym, ...)` method is defined. For `subs` a `subs(obj::Sym, ...)` interface is defined, and exported. As `subs` has paired-off values, specifying the substitution, the `Julia`n interface allows pairs notation (`a => b`) to be used.


## Symbolic variables

The `symbols` function in SymPy is used to create symbolic variables. In `SymPy` this is available, as well, but we illustrate the use of the `@syms` macro for variable creation. The macro allows single variables, groups of variables, variables with assumptions, and symbolic functions to be defined:

```@repl Julia
using SymPy_PythonCall
```

```@repl Julia
@syms x, y, t::real, xs[1:5], F()
```

The `Sym` constructor can take a `Julia` value into its symbolic counterpart

```@repl Julia
Sym(1), Sym(1/2), Sym(1//2)
```

The latter shows that rational values are converted without loss of exactness, but floating point values, like `1/2`, do not magically become exact. A mix of symbolic and non-symbolic values will promote to symbolic, so an expression like this can also be used to create the symbolic fraction.

```@repl Julia
Sym(1) / 2
```

The special symbolic values `PI`, `E`, `IM`, `oo` are symbolic values and conveniences for `Sym(pi)`, `Sym(ℯ)`, `Sym(im)`, and `Sym(Inf)`.

The `N` function turns symbolic numbers into `Julia`n counterparts with an attempt to preserve the type:

```@repl Julia
N(Sym(1//2)), N(PI)
```

## Solving equations

SymPy can be used to solve various equation types. An equation can be specified by `Eq` or the convenient `~` infix-operator, used below.

Linear equation

```@repl Julia
solve(2x + 5 ~ 3x - 6, x)
```

Or a system of linear equations, grouped in a tuple


```@repl Julia
eqs = (2x + 3y ~ 7, 3x + 7y ~ 8)
solve(eqs, (x, y))
```

Some tractable non-linear equations can be solved

```@repl Julia
solve(sin(x) ~ 1//2, x)
```

This is **different** from `solve(sin(x) ~ 1/2, x)`

The `solveset` function of SymPy is the suggested interface, as it always return set objects as an answer:

```@repl Julia
u = solveset(sin(x) ~ 1//2, x)
```

The output may be a finite set (in which case a `Set` container is used) or an infinite set, as above. While mathematically rigorous, these are a bit moe work to use. The `in` method can be used to query:

```@repl Julia
PI/6 in u
```

An infinite set may be made into a finite set, through intersection. For example:

```@repl Julia
J = sympy.Interval(0, 2PI)
u.intersect(J)
```

(As `intersect` is a `Julia` generic function, there is a specialization for symbolic values allowing that to have been `intersect(u, J)`.)



## Working with expressions

Symbolicness should flow through Julia expressions, leaving further symbolic expressions

```@repl Julia
x + 1//2 + x^2 + cos(x)/(1 + exp(x))
```


```@repl Julia
evalpoly(x, (1,2,3,4,5))
```

```@repl Julia
@syms a[0:5]
sum(a[i+1] * x^i for i in 0:5)
```

### Substitution

Substitution allows part of a symbolic expression to be replaced. Subsitution rules form the basics of simplification routines. The `subs` function has an interface using pairs notation:


```@repl Julia
@syms a b c x
p = a*x^2 + b*x + c
subs(p, x=> x + 1)
subs(p, x=> 2)
```

The latter shows the "call" syntax for symbolic objects uses `subs`.


### Simplify

We use the call notation to put in a root of the polynomial:

```@repl Julia
r1 = (-b + sqrt(b^2 - 4a*c))/(2a)
ex = p(x => r1)
```

It isn't `0`, or is it? The combination of powers and roots needs simplification. The `simplify` function can do so:

```@repl Julia
simplify(ex)
```

The `simplify` function utilizes several more special-purpose simplification functions, such as `trigsimp` and `logsimp`. These must be qualified, as in `sympy.trigsimp`.

### Expand, factor

The `factor` and `expand` functions counterparts

```@repl Julia
ex = (x-1)*(x-2)*(x-3)
expand(ex)
factor(expand(ex))
```

The `factor` function can factor `x^2 - 4` but doesn't factor `x^2 - 5`, as it needs a wider type for its answers. The `solve` function can find when `x^2 - 5` is zero, and this can be used to factor:

```@repl Julia
ex = x^2 - 5
factor(ex)
prod(x - xi for xi in solve(ex, x))
```

The functions `numerator`, `denominator`, `cancel`, `together`, `apart` are used to work with rational expressions.

## Calculus

The three main operations from first semester calculus are all available along with other functionality:

```@repl Julia
@syms a x
limit(sin(a*x)/x, x=>0)
diff(exp(-a*x), x)
integrate(cos(x)^2*sin(x)^3, x)
```
