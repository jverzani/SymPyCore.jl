# SymPyCore

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://jverzani.github.io/SymPyCore.jl/dev)

[![Build Status](https://github.com/jverzani/SymPyCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jverzani/SymPyCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

[SymPy](https://www.sympy.org/) is a Python library for symbolic mathematics.

At present, there are two means to call `Python` code from `Julia`. As such, two packages have been developed to call into SymPy:

* [SymPy.jl](https://github.com/JuliaPy/SymPy.jl) is a long-standing `Julia` package using `PyCall.jl` to provide a "`Julia`n" interface to SymPy.

* [SymPyPythonCall.jl](https://github.com/jverzani/SymPyPythonCall.jl) is a `Julia` package using `PythonCall.jl` to provide a "`Julia`n" interface to SymPy providing a nearly identical experience as `SymPy.jl`.

The `SymPyCore` package aims to unify the underlying code, leaving only a small amount of glue code in the primary packages. As of version `0.2` `SymPyPythonCall.jl` uses the `SymPyCore` backend. The [SymPyPyCall.jl](https://github.com/jverzani/SymPyPyCall.jl) package uses `SymPyCore` and `PyCall`, like `SymPy`. It is expected that the next breaking version of `SymPy` will be based on `SymPyPyCall`.

To use `SymPyCore` you should install one of the two primary packages, and load that into a session. Installation of either `SymPyPythonCall` or `SymPyPyCall` should install the core package, the glue package, and arrange for the underlying sympy library of Python to be installed.
