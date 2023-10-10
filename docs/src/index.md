# SymPyCore.jl

Documentation for SymPyCore.jl.



[SymPy](https://www.sympy.org/) is Python library for symbolic mathematics.

As there are two means to call `Python` code from `Julia`, two packages have been developed to call into SymPy:

* [SymPy.jl](https://github.com/JuliaPy/SymPy.jl) is a `Julia` package using `PyCall.jl` to provide a "`Julia`n" interface to SymPy.

* [SymPyPythonCall.jl](https://github.com/jverzani/SymPyPythonCall.jl) is a `Julia` package using `PythonCall.jl` to provide a "`Julia`n" interface to SymPy providing a nearly identical experience as `SymPy.jl`.

The `SymPyCore` package aims to unify the underlying code, leaving only a small amount of glue code in the primary packages. Currently these are called `SymPyPyCall` and `SymPy_PythonCall` to avoid the name collision, but it is expected that the next breaking versions of `SymPy` and `SymPyPythonCall` will use `SymPyCore`.

----

While both glue packages provide a means to interact directly with the `sympy` library in `Python`, `SymPyCore` adds some conveniences, including many `Julia`n idioms for easier use within `Julia`.

The *Example usage* page shows basic usages. The translation of the *SymPy Tutorial* is extensive.
