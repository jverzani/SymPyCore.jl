# Basic overview

An interface between `Julia` and the SymPy library of `Python` requires a connection between the two languages. The `PythonCall` package provides a means to  call into an underlying sympy library in `Python`. (As well as `PyCall`.) For example

```@setup overview
using SymPyPythonCall
PythonCall = SymPyPythonCall.PythonCall
```

```julia
julia> import PythonCall
```

```@repl overview
_sympy_ = PythonCall.pyimport("sympy");
```

The `_sympy_` object holds references to the underlying sympy library. As an example, the following creates a symbolic variable, `x`, and calls the `sin` function on it:

```@repl overview
x = _sympy_.symbols("x")
_sympy_.sin(x)
x.is_commutative
x.conjugate()
typeof(x)
```

The `PythonCall` package provides some basic operations for `Py` objects, such as basic math operations:

```@repl overview
x + x
x * x
x ^ x
```

`SymPyPythonCall`, which uses `SymPyCore`, wraps the `Py` objects in its `Sym` class to provide a means to dispatch familiar `Julia` generics:

```@repl overview
using SymPyPythonCall
```

```@repl overview
x = symbols("x") # or @syms x
simplify(2sin(x)*cos(x))
```

By wrapping the Python object in a `Julia` struct, there are many advantages, such as:

* The type can be used for dispatch, allowing `Julia` generic functions to have methods specialized for symbolic objects.
* The `getproperty` method can be specialized. This allows object methods, like `x.conjugate` to have arguments translated from `Sym` objects to `Python` objects when being called.
* The `show` method can be used to adjust printing of objects


The package also provides methods for some sympy methods, such as `simplify` above. To make this work, there needs to be a means to take `Sym` objects to their `Py` counterparts and a means to take `Py` objects to a symbolic type. As these conversions may be type dependent two operators (`↓` and  `↑`) are used internally to allow the definition along these lines:

```julia
simplify(x::Sym, args...; kwargs...) = ↑(sympy.simplify(↓(x), ↓(args)...; ↓(kwargs)...))
```

(Though there is some overhead introduced, it does not seem to be significant compared to computational cost of most symbolic computations.)

The `expand_log` function is not wrapped as such, but can still be called from the `sympy` object exported by `SymPyPythonCall`:

```@repl overview
@syms x::real
simplify(log(2x))
sympy.expand_log(log(2x))
```

Methods of `sympy` are also called using the conversion operators above.

### Some functions of SymPy are Julia methods

A few select functions of SymPy are available as `Julia` methods where *typically* the dispatch is based on the first element being symbolic. Other methods must by qualified, as in `sympy.expand_log`. Historically, `SymPy` was pretty expansive with what it chose to export, but that is no longer the case. Currently, only a few foundational function are exported. E.g., `expand` but not `expand_log`; `simplify` but not `trigsimp`. This should reduce name collisions with other packages. The drawback, is we can add more `Julia`n interfaces when a method is defined. Open an issue, should you think this advantageous.

## Using other SymPy modules

We now show how to access one of the numerous external modules of `sympy` beyond those exposed immediately by `SymPy`. In this case, the `stats` module.


```@repl overview
_stats_ = PythonCall.pyimport("sympy.stats");
```

The `stats` module holds several probability functions, similar to the `Distributions` package of `Julia`. This set of commands creates a normally distributed random variable, `X`, with symbolic parameters:

```@repl overview
𝑋,mu = _sympy_.symbols("X, mu")
sigma = _sympy_.symbols("sigma", positive=true)
X = _stats_.Normal(𝑋, mu, sigma)
_stats_.E(X)
_stats_.E(X^2)
_stats_.variance(X)
```

The one thing to note is the method calls return `Py` objects, as there is no intercepting of the method calls done the way there is for the `sympy` module.  Wrapping `_stats_` in `Sym` uses the `getproperty` specialization:

```@repl overview
stats = Sym(_stats_);
@syms 𝑋, μ, σ::positive
X = stats.Normal(𝑋, μ, σ)
stats.variance(X)
```

Next statements like $P(X > \mu)$ can be answered by specifying the inequality using `Gt` in the following:

```@repl overview
stats.P(Gt(X, μ))
```

The unicode `≧` operator (`\geqq[tab]`) is an infix alternative to `Gt`.

A typical calculation for the normal distribution is the area one or more standard deviations larger than the mean:

```jldoctest overview
julia> stats.P(X ≧ μ + 1 * σ)
sqrt(2)*(-sqrt(2)*pi*exp(1/2)*erf(sqrt(2)/2)/2 + sqrt(2)*pi*exp(1/2)/2)*exp(-1/2)/(2*pi)
```

The familiar  answer could be found by calling `N` or `evalf`.

One more distribution is illustrated, the uniform distribution over a symbolic interval $[a,b]$:

```@repl overview
@syms 𝑈 a::real b::real
U = stats.Uniform(𝑈, a, b)
stats.E(U)
stats.variance(U) |> factor
```

### The mpmath library

According to its [website](https://mpmath.org/):
`mpmath` is a free (BSD licensed) Python library for real and complex floating-point arithmetic with arbitrary precision. It has been developed by Fredrik Johansson since 2007, with help from many contributors.
For Sympy, versions prior to 1.0 included `mpmath`, but SymPy now depends on it`mpmath` as an external dependency.


The `mpmath` library provides numeric, not symbolic routines. To access these directly, the `mpmath` library can be loaded, in the manner just described.

```@repl overview
_mpmath_ = PythonCall.pyimport("mpmath")
mpmath = Sym(_mpmath_)
```

To compare values, consider the `besselj` function which has an implementation in `Julia`'s `SpecialFunctions` package, `SymPy` itself, and `mpmath`. `SymPyCore` provides an overloaded method for a symbolic second argument which is available once `SpecialFunctions` is loaded.

```@repl overview
using SpecialFunctions
@syms x
nu, c = 1//2, pi/3
(mpmath.besselj(nu,c), besselj(nu, x)(c).evalf(), besselj(nu, c))
```



## Different output types

`SymPyPythonCall` provides a few conversions into containers of symbolic objects, like for lists, tuples, finite sets, and matrices
.
Not all outputs are so simple to incorporate and are simply wrapped in the `Sym` type.

Conversion to a workable `Julia` structure can require some massaging. This example shows how to get at the pieces of the `Piecewise` type.

The output of many integration problems is a piecewise function:

```@repl overview
@syms n::integer x::real
u = integrate(x^n, x)
```

The `u` object is of type `Sym`, but there are no methods for working with it. The `.args` call will break this into its argument, which again will by symbolic. The `Introspection.args` function will perform the same thing.

```@repl overview
as = Introspection.args(u)
```

The `as` object is a tuple of `Sym` objects. Consider the first one:

```@repl overview
c1 = first(as)
```

The value of `c1` prints as a tuple, but is of type `Sym` and sympy type `CondExprPair`. Though the underlying python type is iterable or indexable, the wrapped type is not. It can  be made iterable in a manner of ways: by calling `↓(c1)`; by finding the underlying Python object through the attribute `.o`, as in `c1.o`; or by calling the `Py` method of `PythonCall`, as in `PythonCall.Py(c1)`. More generically, `PythonCall` provides a `PyIterable` wrapper. As there is no defined `lastindex`, the latter is a bit more cumbersome to use. This pattern below, expands the conditions into a dictionary:

```@repl overview
[Sym(↓(a)[1]) => Sym(↓(a)[0]) for a ∈ as]
```

The Python object, `↓(a)` is indexed, so 0-based indexing is used above. These pieces are then converted to `Sym` objects for familiarity.
