# A SymPyCore introduction

This document provides an introduction to using SymPy within `Julia` via `SymPyCore`
It has examples from the [Introductory Tutorial](https://docs.sympy.org/latest/tutorials/intro-tutorial/index.html) of SymPy that is translated into `Julia` commands in this documentation.


```@setup introduction
using SymPyPythonCall
```

## Overview

In this document, we use `SymPy` to refer to either the `SymPy` or `SymPyPythonCall` packages that interface `Julia` with SymPy from `Python` using `SymPyCore`. The only difference being the glue package for interop between `Julia` and `Python`.

`SymPy` provides a `Julia`n interface to SymPy, a `Python` library for symbolic math, as alternative to working with `Python` objects directly using one of the glue packages. See the [overview](./overview.html) page for more details. Some brief implementation details are:

* Symbolic values in `Python` are wrapped in a subtype, typically `Sym{T}`, of `SymbolicObject{T}` or a container holding such values. The conversion from a Python object to a symbolic object in `Julia` is implemented in the `↑` method. Similarly, the  `↓` method takes a symbolic object and finds a Python counterpart for passing to underlying methods of SymPy.

* For many generic methods in `Base`, `LinearAlgebra`, or `SpecialFunctions` -- when there is a SymPy counterpart -- a method is made which dispatches on its first argument being symbolic. The basic pattern is akin to `Base.sin(x::Sym) = sympy.sin(x)` where `sympy.sin(x)` is essentially `↑(_sympy_.sin(↓(x)))` -- here `_sympy_` is the object holding the reference to the Python module, and `_sympy_.sin` the reference to its `sin` function. The `sympy` object handles the up and down conversions.

* For many primary functions of SymPy, such as `simplify`, `factor`, `expand`, etc., new methods are made for use within `Julia`. Less foundational functions of SymPy, such as `trigsimp` or `expand_log` are referenced as `sympy.trigsimp` or `sympy.expand_log`. The `sympy` object is not a `Julia` module, but this use is reminiscent of qualifying a function from a module.

* SymPy, being a Python library, has many methods for its objects. For example, a symbolic object, `obj` has a `diff` method accessed by `obj.diff(...)`. A object also has a `subs` method for substitution, accessed through `obj.subs(...)`. The same "dot" style is used for Python and `Julia`.

* For commonly used object methods, a `Julia`n interface is defined. For `diff` a `diff(obj::Sym, ...)` method is defined. For `subs` a `subs(obj::Sym, ...)` interface is defined, and exported. As `subs` has paired-off values, specifying the substitution, the `Julia`n interface allows pairs notation (`a => b`) to be used.

## The package

Either the `SymPy` or `SymPyPythonCall` packages needs to be loaded, e.g., `using SymPy`. The two can't be used in the same session.

When either is installed, the `SymPyCore` package is installed; the underlying glue package (either `PyCall` or `PythonCall`) should be installed; and that glue package should install the `sympy` library of `Python`.

## Symbols

At the core of `SymPy` is the introduction of symbolic variables that
differ quite a bit from `Julia`'s variables. Symbolic variables do not
immediately evaluate to a value, rather the "symbolicness" propagates
when interacted with. To keep things manageable, SymPy does some
simplifications along the way.

Symbolic expressions are primarily of the `Sym` type and can be constructed in the standard way:

```@repl introduction
x = Sym("x")
```

This creates a symbolic object `x`, which can be manipulated through further function calls.

### The `@syms` macro

There is the `@syms` macro that makes creating multiple variables a
bit less typing, as it creates variables in the local scope -- no
assignment is necessary. Compare these similar ways to create symbolic
variables:

```@repl introduction
@syms a b c
a,b,c = Sym("a"), Sym("b"), Sym("c")
```

Here are two ways to make related variables:

```@repl introduction
@syms xs[1:5]
ys = [Sym("y$i") for i in 1:5]
```

The former much more succinct, but the latter pattern of use when the number of terms is a variable.


The `@syms` macro is recommended, and will be modeled in the following, as it makes the specification of assumptions, collections of indexed variables,  and symbolic functions more natural.

### Assumptions

In `Python`'s SymPy documentation the `symbols` constructor is
suggested as idiomatic for producing symbolic objects. This function
can similarly be used within `Julia`. With `symbols` (and with
`@syms`) it is possible to pass assumptions onto the variables. A list
of possible assumptions is
[here](http://docs.sympy.org/dev/modules/core.html#module-sympy.core.assumptions). Some
examples are:

```@repl introduction
u = symbols("u")
x = symbols("x", real=true)
y1, y2 = symbols("y1, y2", positive=true)
alpha = symbols("alpha", integer=true, positive=true)
```

As seen, the `symbols` function can be used to make one or more variables with zero, one or more assumptions.

We jump ahead for a second to illustrate, but here we see that `solve` will respect these assumptions, by failing to find solutions to these equations:

```@repl introduction
solve(x^2 + 1)   # ±i are not real
```

```@repl introduction
solve(y1 + 1)    # -1 is not positive
```

----

The `@syms` macro allows annotations, akin to type annotations, to specify assumptions on new variables:

```@repl introduction
@syms u1::positive u2::positive
solve(u1 + u2)  # empty, though solving u1 - u2 is not.
```

Additionally you can rename arguments using pair notation:

```@repl introduction
@syms a1=>"α₁" a2=>"α₂"
```

In this example, the Julia variables `a1` and `a2` are defined to store SymPy
symbols with the "pretty" names `α₁` and `α₂` respectively.

As can be seen, there are several ways to create symbolic values, but
the recommended way is to use `@syms`.

### Special constants

`Julia` has its math constants, like `pi` and `e`, `SymPy` as well. A few of these have `Julia` counterparts provided by `SymPyCore`. For example, these two constants are defined (where `oo` is for infinity):

```@repl introduction
PI,  oo  # also Sym(pi) or Sym(Inf)
```

Numeric values themselves can be symbolic. This example shows the
difference. The first `asin` call dispatches to `Julia`'s `asin`
function, the second to `SymPy`'s:

```@repl introduction
[asin(1), asin(Sym(1))]
```


## Substitution

SymPy provides a means to substitute values in for the symbolic expressions. The specification requires an expression, a variable in the expression to substitute in for, and a new value. For example, this is one way to make a polynomial in a new variable:

```@repl introduction
@syms x y
ex = x^2 + 2x + 1
ex.subs(x, y)
```


Substitution can also be numeric:

```@repl introduction
ex.subs(x, 0)
```

The output has no free variables, but is still symbolic.

Expressions with more than one variable can have multiple substitutions, where each is expressed as a tuple:

```@repl introduction
@syms x,y,z
ex = x + y + z
ex.subs([(x,1), (y, pi)])
```


!!! note
    The SymPy documentation for many functions can be read from the terminal using `Base.Docs.getdoc(ex)`, as in `Base.Docs.getdoc(sin(x))`.


The `SymPyCore` package also offers a more `Julia`n interface, through the method `subs`. This replaces the specification of pairs by a tuple with the `=>` infix operator for `Pair` construction:

```@repl introduction
subs(ex, x=>1, y=>pi)
```


For `subs`, the simple substitution `ex.object(x,a)` or `subs(ex, x=>s)` is similar to simple function evaluation, so `Julia`'s call notation for symbolic expressions is reserved for substitution, where to specify the pairing off of `x` and `a`, the `=>`  pairs notation is used.

This calling style will be equivalent to the last:

```@repl introduction
ex(x=>1, y=>pi)
```

A straight call is also possible, where the order of the variables is determined by `free_symbols`. This is useful for expressions of a single variable, but being more explicit through the use of paired values is recommended.


## Conversion from symbolic to numeric

SymPy provides two identical means to convert a symbolic math
expression to a number. One is `evalf`, the other `N`. Within `Julia`
we decouple this, using `N` to also convert to a `Julian` value and
`evalf` to leave the conversion as a symbolic object.  The `N`
function converts symbolic integers, rationals, irrationals, and
complex values, while attempting to find an appropriate `Julia` type
for the value.

To see the difference, we use both on `PI`:

```@repl introduction
N(PI)  # converts to underlying pi irrational
```

Whereas, `evalf` will produce a symbolic numeric value:

```@repl introduction
(PI).evalf()
```


The `evalf` call allows for a precision argument to be passed through the second argument. This is how 30 digits of $\pi$ can be extracted:

```@repl introduction
PI.evalf(30)
```

This is a SymPy, symbolic number, not a `Julia` object. Composing with `N`

```@repl introduction
N(PI.evalf(30))
```

will produce a `Julia` number,


Explicit conversion via `convert(T, ex)` can also be done in some cases, but may need to be combined with a call to `evalf` in some compound cases.


## Algebraic expressions

`SymPyCore` overloads many of `Julia`'s functions to work with symbolic objects, such as seen above with `asin`. The usual mathematical operations such as `+`, `*`, `-`, `/` etc. work through `Julia`'s promotion mechanism, where numbers are promoted to symbolic objects, others dispatch internally to related SymPy functions.

In most all  cases, thinking about this distinction between numbers and symbolic numbers is unnecessary, as numeric values passed to `SymPyCore` functions are typically promoted to symbolic expressions. This conversion will take math constants to their corresponding `SymPyCore` counterpart, rational expressions to rational expressions, and floating point values to floating point values. However there are edge cases. An expression like `1//2 * pi * x` will differ from the seemingly identical  `1//2 * (pi * x)`. The former will produce a floating point value from `1//2 * pi` before being promoted to a symbolic instance. Using the symbolic value `PI` makes this expression work either way.

Most of `Julia`'s
[mathematical](http://julia.readthedocs.org/en/latest/manual/mathematical-operations/#elementary-functions)
functions are overloaded to work with symbolic expressions. `Julia`'s
generic definitions are used, as possible. This also introduces some
edge cases. For example, `x^(-2)` will balk due to the negative,
integer exponent, but either `x^(-2//1)` or `x^Sym(-2)` will work as
expected, as the former call first dispatches to a generic definition,
but the latter two expressions do not.




### The expand, factor, collect, and simplify functions

`SymPyCore makes it very easy to work with polynomial and rational expressions.

First we create some variables:

```@repl introduction
@syms x y z
```


A typical polynomial expression in a single variable can be written in two common ways, expanded or factored form. Using `factor` and `expand` can move between the two.

For example,

```@repl introduction
p = x^2 + 3x + 2
factor(p)
```

Or

```@repl introduction
expand(prod((x-i) for i in 1:5))
```

The `factor` function factors over the rational numbers, so something like this with obvious factors is not finished:

```@repl introduction
factor(x^2 - 2)
```

When expressions involve one or more variables, it can be convenient to be able to manipulate them. For example,
if we define `q` by:

```@repl introduction
q = x*y + x*y^2 + x^2*y + x
```

Then we can collect the terms by the variable `x`:

```@repl introduction
sympy.collect(q, x)
```

or the variable `y`:

```@repl introduction
sympy.collect(q, y)
```

These are identical expressions, though viewed differently.

!!! note
    `SymPy`'s `collect` function has a different meaning than the `collect` generic, which turns an iterable into a vector or, more generally, an array. The expression above dispatches to `SymPy`'s as `q` is symbolic.

A more broad-brush approach is to let `SymPyCore` simplify the values. In this case, the common value of `x` is factored out:

```@repl introduction
simplify(q)
```

The `simplify` function attempts to apply the dozens of functions related to simplification that are part of SymPy. It is also possible to apply these functions one at a time, for example `sympy.trigsimp` does trigonometric simplifications.

The SymPy tutorial illustrates that `expand` can also result in simplifications through this example:

```@repl introduction
expand((x + 1)*(x - 2) - (x - 1)*x)
```


These methods are not restricted to polynomial expressions and will
work with other expressions. For example, `factor` identifies the
following as a factorable object in terms of the variable `exp(x)`:

```@repl introduction
factor(exp(2x) + 3exp(x) + 2)
```

### Rational expressions: apart, together, cancel

When working with rational expressions, SymPy does not do much
simplification unless asked. For example this expression is not
simplified:

```@repl introduction
r = 1/x + 1/x^2
```

To put the terms of `r` over a common denominator, the `together` function is available:

```@repl introduction
together(r)
```

The `apart` function does the reverse, creating a partial fraction decomposition from a ratio of polynomials:

```@repl introduction
apart( (4x^3 + 21x^2 + 10x + 12) /  (x^4 + 5x^3 + 5x^2 + 4x))
```

Some times SymPy will cancel factors, as here:

```@repl introduction
top = (x-1)*(x-2)*(x-3)
bottom = (x-1)*(x-4)
top/bottom
```

(This might make math faculty a bit upset, but it is in line with student thinking.)

However, with expanded terms, the common factor of `(x-1)` is not cancelled:

```@repl introduction
r = expand(top) / expand(bottom)
```

The `cancel` function instructs SymPy to perform cancellations. It
takes rational functions and puts them in a canonical $p/q$ form with
no common (rational) factors and leading terms which are integers:

```@repl introduction
cancel(r)
```
### Powers

The SymPy [tutorial](http://docs.sympy.org/dev/tutorial/simplification.html#powers) offers a thorough explanation on powers and which get simplified and under what conditions. Basically

* The simplicfication $x^a x^b = x^{a+b}$ is always true. However

* The simplification $x^a y^a=(xy)^a$ is only true with assumptions, such as $x,y \geq 0$ and $a$ is real, but not in general. For example, $x=y=-1$ and $a=1/2$ has $x^a \cdot y^a = i \cdot i =  -1$, where as $(xy)^a = 1$.

* As well, the simplification $(x^a)^b = x^{ab}$ is only true with assumptions. For example $x=-1, a=2$, and $b=1/2$ gives $(x^a)^b = 1^{1/2} = 1$, whereas $x^{ab} = -1^1 = -1$.


We see that with assumptions, the following expression does simplify to $0$:

```@repl introduction
@syms x::nonnegatve y::nonnegative  a::real
simplify(x^a * y^a - (x*y)^a)
```

However, without assumptions this is not the case

```@repl introduction
@syms x,y,a
simplify(x^a * y^a - (x*y)^a)
```

The `simplify` function calls `powsimp` to simplify powers, as above. The `powsimp` function has the keyword argument `force=true` to force simplification even if assumptions are not specified:

```@repl introduction
sympy.powsimp(x^a * y^a - (x*y)^a, force=true)
```

### Trigonometric simplification

For trigonometric expressions, `simplify` will use `trigsimp` to simplify:

```@repl introduction
@syms theta::real
p = cos(theta)^2 + sin(theta)^2
```

Calling either `simplify` or `trigsimp` will apply the Pythagorean identity:

```@repl introduction
simplify(p)
```

The `trigsimp` function is, of course,  aware of the double angle formulas:

```@repl introduction
simplify(sin(2theta) - 2sin(theta)*cos(theta))
```

The `expand_trig` function will expand such expressions:

```@repl introduction
sympy.expand_trig(sin(2theta))
```

## Polynomials

### Coefficients of a polynomial

Returning to polynomials, there are a few functions to find various pieces of the polynomials. First we make a general quadratic polynomial:

```@repl introduction
@syms a,b,c,x
p = a*x^2 + b*x + c
```

If given a polynomial, like `p`, there are different means to extract the coefficients:

* SymPy provides a `coeffs` method for `Poly` objects, but `p` must first be converted to one.

* SymPy provides the `coeff` method for expressions, which allows extraction of a coefficient for a given monomial




The `ex.coeff(monom)` call will return the corresponding coefficient of the monomial:

```@repl introduction
p.coeff(x^2) # a
p.coeff(x)   # b
```

The constant can be found through substitution:

```@repl introduction
p(x=>0)
```

Though one could use some trick like this to find all the coefficients, that is cumbersome, at best.

```@repl introduction
vcat([p.coeff(x^i) for i in N(degree(p,gen=x)):-1:1], [p(x=>0)])
```




Polynomials are a special class in SymPy and must be constructed. The `poly` constructor can be used. As there is more than one free variable in `p`, we specify the variable `x` below:

```@repl introduction
q = sympy.poly(p, x)
q.coeffs()
```


### Polynomial roots: solve, real_roots, polyroots, nroots

SymPy provides functions to find the roots of a polynomial. In
general, a polynomial with real coefficients of degree $n$ will have
$n$ roots when multiplicities and complex roots are accounted for. The
number of real roots is consequently between $0$ and $n$.

For a *univariate* polynomial expression (a single variable), the real
roots, when available, are returned by `real_roots`. For example,

```@repl introduction
real_roots(x^2 - 2)
```

Unlike `factor` -- which only factors over rational factors --
`real_roots` finds the two irrational roots here. It is well known
(the
[Abel-Ruffini theorem](http://en.wikipedia.org/wiki/Abel%E2%80%93Ruffini_theorem))
that for degree 5 polynomials, or higher, it is not always possible to
express the roots in terms of radicals. However, when the roots are
rational SymPy can have success:


```@repl introduction
p = (x-3)^2*(x-2)*(x-1)*x*(x+1)*(x^2 + x + 1)
real_roots(p)
```


In this example, the degree of `p` is 8, but only the 6 real roots
returned, the double root of $3$ is accounted for. The two complex
roots of `x^2 + x+ 1` are not considered by this function. The complete set
of distinct roots can be found with `solve`:

```@repl introduction
solve(p)
```

This finds the complex roots, but does not account for the double
root. The `roots` function of SymPy does.



The output of calling `roots` will be a dictionary whose keys are the roots and values the multiplicity.

```julia
roots(p)
```

When exact answers are not provided, the `roots` call is contentless:

```@repl introduction
p = x^5 - x + 1
sympy.roots(p)
```

Calling `solve` seems to produce very little as well:

```@repl introduction
rts = solve(p)
```

But in fact, `rts` contains lots of information. We can extract numeric values quite easily with `N`:

```@repl introduction
N.(rts)
```

These are numeric approximations to irrational values. For numeric
approximations to polynomial roots, the `nroots` function is also
provided. The answers are still symbolic:

```@repl introduction
nroots(p)
```

## Solving equations

### The solve function

The `solve` function is more general purpose than just finding roots of univariate polynomials. The function tries to solve for when an expression is $0$, or a set of expressions are all $0$.

For example, it can be used to solve when $\cos(x) = \sin(x)$:

```@repl introduction
solve(cos(x) - sin(x))
```

Though there are infinitely many correct solutions, these are within a certain range.

The
[solveset](http://docs.sympy.org/latest/modules/solvers/solveset.html)
function appears in version 1.0 of SymPy and is an intended
replacement for `solve`. Here we see it describes all solutions:

```@repl introduction
u = solveset(cos(x) - sin(x))
```

The output of `solveset` is a set, rather than a vector or
dictionary.

```@repl introduction
v = solveset(x^2 - 4)
```



Solving within Sympy has limits. For example, there is no symbolic solution here:

```@repl introduction
try  solve(cos(x) - x)  catch err "error" end # wrap command for doctest of error
```

(And hence the error message generated.)

For such an equation, a numeric method would be needed, similar to the `Roots` package. For example:

```@repl introduction
nsolve(cos(x) - x, 1)
```

Though it can't solve everything, the `solve` function can also solve
equations of a more general type. For example, here it is used to
derive the quadratic equation:

```@repl introduction
@syms a::real, b::real, c::real
p = a*x^2 + b*x + c
xs = solve(p, x);
```

The extra argument `x` is passed to `solve` so that `solve` knows
which variable to solve for.

### The `solveset` function

The `solveset` function is similar:

```@repl introduction
solveset(p, x); # Set with two elements
```

If the `x` value is not given, `solveset` will error and  `solve` will try to find a
solution over all the free variables:

```@repl introduction
solve(p)
```

The output of `solveset` in Python is always a set, which may be finite or not. Finite sets are converted to `Set`s in `Julia`. Infinite sets have no natural counterpart and are not realized. Rather, they can be queried, as with "needle `in` haystack". For example:

```@repl introduction
u = solveset(sin(x) ≧ 0)  # [\geqq] or with u  = solveset(Ge(sin(x), 0))
PI/2 in u
3PI/2 in u
```

Infinite sets can have unions and intersections taken:

```@repl introduction
v = solveset(cos(x) ≧ 0)
[3PI/4 in A for A ∈ (u, v, intersect(u, v), union(u, v))]
```

Infinite sets can be filtered by intersecting them with an interval. For example,

```@repl introduction
u = solveset(sin(x) ~ 1//2, x)
intersect(u, sympy.Interval(0, 2PI))  # a finite set after intersection
```

There are more sympy methods for working with sets, beyond those mirroring `Julia` generics.

----

Systems of equations can be solved as well. We specify them within a
tuple of expressions, `(ex1, ex2, ..., exn)` where a found solution
is one where all the expressions are 0. For example, to solve this
linear system: $2x + 3y = 6, 3x - 4y=12$, we have:

```@repl introduction
@syms x::real, y::real
exs = (2x+3y-6, 3x-4y-12)
```

```@repl introduction
d = solve(exs); # Dict(x=>60/17, y=>-6/17)
```


We can "check our work" by plugging into each equation. We take advantage of how the `subs` function allows us to pass in a dictionary:

```@repl introduction
map(ex -> ex.subs(d), exs)
```



The more `Julia`n way to solve a linear  equation, like this   would be as follows:

```@repl introduction
A = Sym[2 3; 3  -4]; b = Sym[6, 12]
A \ b
```

(Rather than use a generic  `lu` solver through `Julia` (which  proved slow for larger  systems),  the `\` operator utilizes  `solve` to perform this  computation.)



In the previous example, the system had two equations and two
unknowns. When that is not the case, one can specify the variables to
solve for as a vector. In this example, we find a quadratic polynomial
that approximates $\cos(x)$ near $0$:

```@repl introduction
a,b,c,h = symbols("a,b,c,h", real=true)

p = a*x^2 + b*x + c

fn = cos;
exs = [fn(0*h)-p(x=>0), fn(h)-p(x => h), fn(2h)-p(x => 2h)]
d = solve(exs, (a,b,c));
d[a], d[b], d[c]
```

Again, a dictionary is returned, though we display its named elements individually. The polynomial itself can be found by
substituting back in for `a`, `b`, and `c`:

```@repl introduction
quad_approx = p.subs(d)
```

Taking the "limit" as $h$ goes to 0 produces the answer $1 - x^2/2$, as  will be shown.

Finally for `solve`, we show one way to re-express the polynomial $a_2x^2 + a_1x + a_0$
as $b_2(x-c)^2 + b_1(x-c) + b_0$ using `solve` (and not, say, an
expansion theorem.)

```@repl introduction
n = 3
@syms x, c
@syms as[1:3]
@syms bs[1:3]
p = sum(as[i]*x^(i-1) for i ∈ 1:n)
q = sum(bs[i]*(x-c)^(i-1) for i ∈ 1:n)
d = solve(p-q, bs)
```


### Solving using logical operators

The `solve` function does not need to just solve `ex = 0`. There are other means to specify an equation. Ideally, it would be nice to say `ex1 == ex2`, but the interpretation of `==` is not for this. Rather, `SymPyCore` introduces `Eq` for equality. So this expression

```@repl introduction
solve(Eq(x, 1))
```

gives ``1``, as expected from solving `x == 1`.

!!! note "Equals"

    Mathematics uses `=` for equations. `Julia` uses `=` for assignment and `==` for generic equality, and `===` to test for identical values. There is no general infix equation operation in `Julia`, though `~` is used by the `Symbolics` package its ecosystem. SymPy uses `Eq` for expressing an equation. For `SymPyCore`, both `Eq` and `~` may be used to indicate an equation between unknowns.

In addition to `Eq`, there are `Lt`, `Le`, `Ge`, `Gt`. The Unicode
operators (e.g., `\leq`  and not  `\leq`)  are not aliased to these, but there are alternatives
`\ll[tab]`, `\leqq[tab]`, `\Equal[tab]`, `\geqq[tab]`, `\gg[tab]` and
`\neg[tab]` to negate.

So, the above could have been written with the following nearly identical expression, though it is entered with `\Equal[tab]`:

```@repl introduction
solve(x ⩵ 1)
```

Or as

```@repl introduction
solve(x ~ 1)
```

Here is an alternative way of asking a previous question on a pair of linear equations:

```@repl introduction
@syms x::real, y::real
exs = (2x+3y ~ 6, 3x-4y ~ 12)
d = solve(exs);
```

Here  is  one other way  to  express  the same

```@repl introduction
Eq.( (2x+3y,3x-4y), (6,12)) |>  solve == d
```

### Solving a linear recurrence

The `rsolve` function solves univariate recurrence with rational coefficients. It's use is like `solve`, though we need to qualify it, as the function does not have a `Julia`n counterpart:

```@repl introduction
@syms y() n
eqn = y(n) ~ y(n-1) + y(n-2)
sympy.rsolve(eqn ,y(n))
```

A possibly familiar solution to the Fibonacci pattern is produced.


## Matrices

A matrix of symbolic values could be represented in `Julia` as either a symbolic matrix or a matrix of symbolic elements. In `SymPy` the default is to use the latter:

```@repl introduction
@syms x y
A = [1 x; x^2 x^3]
```

The `getproperty` method for matrices with symbolic values is overridden to allow object methods to be called:

```@repl introduction
A.det()
```

In addition, many of the generic methods from the `LinearAlgebra` package will work, as shown here where the trace is taken:

```@repl introduction
using LinearAlgebra
tr(A)
```


To create symbolic matrices, a bit of work is needed, as `↑` converts symbolic matrices to matrices of symbolic values. Here are few ways

Using an immutable matrix will work, but we specify the matrix through a tuple of row vectors, as the `ImmutableMatrix` type of SymPy is preserved by `↑`:



```@repl introduction
B = [1 2 3; 3 4 5]
sympy.ImmutableMatrix(tuple(eachrow(B)...))
```

A mutable `Matrix` can be created by inhibiting the call to `↑` and calling `Sym` directly. (This is not recommended, as matrices with symbolic values require an extra call with `↓`.)

```@repl introduction
 Sym(↓(sympy).Matrix(tuple(eachrow(B)...)))
```


The `MatrixSymbol` feature of `SymPy` allows for the definition of sized matrices where the element values are not of interest:

```@repl introduction
A, B = sympy.MatrixSymbol("A", 2, 3), sympy.MatrixSymbol("B", 3, 1)
A * B
```

As seen, `A * B` is defined. The values can be seen through:

```@repl introduction
sympy.Matrix(A * B)
```

However, `B * A` will error:


```@repl introduction
try  B * A catch err "Error" end
```
