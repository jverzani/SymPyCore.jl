Introductory Tutorial
=====================

!!! tip "Julia differences"

    This is a translation of the
	[SymPy Tutorial](https://docs.sympy.org/latest/tutorials/intro-tutorial/index.html)
	using the `SymPyCore` package for `Julia` to
	show the similarities and differences when calling into the Python package from `Julia`.
	This version of the tutorial is not endorsed by any member of the SymPy project.
	If its presence is believed to be inconsistent with the licensing of the original tutorial,
	notification would be appreciated.
	As much as possible, the Python text is kept and clarified through comments
	flagged with "Julia differences," though some minor formatting changes were made.

    Some notable differences using SymPy under `Julia`:

    * Julia uses `^` not `**` for exponentiation
    * Julia is ``1``-based, not ``0``-based
	* Julia uses `"` for strings, not `'`
    * The macro `@syms` is primarily used to create symbolic variables and functions, not `symbols`.
    * Many sympy calls of the form `obj.method(args...)` are wrapped in the `Julian` style `method(obj, args...)`.
    * when methods are not wrapped, use `sympy.method` or `obj.method` as needed.
	* The name method in `Julia` is used for specializations of *generic* functions. The package wraps numerous generic methods from Base `Julia` specialized on the first argument being symbolic. (E.g., for the ``\sin`` function a definition like the following is provided: `Base.sin(x::Sym) = sympy.sin(x)`.)
	* method in sympy is used for an object method; A function like `sympy.method` is the underlying function from `SymPy`.)

This tutorial aims to give an introduction to SymPy for someone who has not
used the library before.  Many features of SymPy will be introduced in this
tutorial, but they will not be exhaustive. In fact, virtually every
functionality shown in this tutorial will have more options or capabilities
than what will be shown.  The rest of the SymPy documentation serves as API
documentation, which extensively lists every feature and option of each
function.

These are the goals of this tutorial:

!!! note "note bene"
    This is mainly here for you, the person who is editing and adding to
    this tutorial. Try to keep these principles in mind.

* To give a guide, suitable for someone who has never used SymPy (but who has
  used Python and knows the necessary mathematics).

* To be written in a narrative format, which is both easy and fun to follow.
  It should read like a book.

* To give insightful examples and exercises, to help the reader learn and to
  make it entertaining to work through.

* To introduce concepts in a logical order.

  In other words, don't try to get ahead of yourself.

* To use good practices and idioms, and avoid antipatterns.  Functions or
  methodologies that tend to lead to antipatterns are avoided. Features that
  are only useful to advanced users are not shown.

* To be consistent.  If there are multiple ways to do it, only the best way is
  shown.

  For example, there are at least five different ways to create Symbols.
   ``symbols`` is the only one that is general and doesn't lead to
   antipatterns, so it is the only one used.

* To avoid unnecessary duplication, it is assumed that previous sections of
  the tutorial have already been read.

Feedback on this tutorial, or on SymPy in general is always welcome. Just
write to our [mailing list](https://groups.google.com/forum/?fromgroups#!forum/sympy).
