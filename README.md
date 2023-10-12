# SymPyCore

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://jverzani.github.io/SymPyCore.jl/dev)

[![Build Status](https://github.com/jverzani/SymPyCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jverzani/SymPyCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

[SymPy](https://www.sympy.org/) is Python library for symbolic mathematics.

As present there are two means to call `Python` code from `Julia`, two packages have been developed to call into SymPy:

* [SymPy.jl](https://github.com/JuliaPy/SymPy.jl) is a `Julia` package using `PyCall.jl` to provide a "`Julia`n" interface to SymPy.

* [SymPyPythonCall.jl](https://github.com/jverzani/SymPyPythonCall.jl) is a `Julia` package using `PythonCall.jl` to provide a "`Julia`n" interface to SymPy providing a nearly identical experience as `SymPy.jl`.

The `SymPyCore` package aims to unify the underlying code, leaving only a small amount of glue code in the primary packages. Currently these are called `SymPyPyCall` and `SymPyPythonCall` to avoid the name collision, but it is expected that the next breaking versions of `SymPy` and `SymPyPythonCall` will use `SymPyCore`.

To use `SymPyCore` you should install one of the two primary packages, and load that into a session.
