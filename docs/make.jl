using Documenter

using Pkg
Pkg.activate("/tmp")
Pkg.develop(path="/Users/verzani/julia/SymPyCore/")
Pkg.develop(path="/Users/verzani/julia/SymPyCore/SymPyPyCall/")

using SymPyPyCall
using SymPyCore

makedocs(
    sitename = "SymPyCore",
    format = Documenter.HTML(),
    modules = [SymPyCore],
    warnonly = [:cross_references, :missing_docs],
    pages = [
        "Home" => "index.md",
        "Reference/API" => "reference.md",
        "Tutorial" => [
            "Home" => "Tutorial/index.md",
            "Preliminaries" => "Tutorial/preliminaries.md",
            "Introduction" => "Tutorial/intro.md",
            "Basic operations" => "Tutorial/basic_operations.md",
            "Simplification" => "Tutorial/simplification.md",
            "Calculus" => "Tutorial/calculus.md",
            "Solvers" => "Tutorial/solvers.md",
            "Matrices" => "Tutorial/matrices.md",
            "Manipulation" => "Tutorial/manipulation.md",
            "Gotchas" => "Tutorial/gotchas.md",
            "printing" => "Tutorial/printing.md",
            "Next" => "Tutorial/next.md"

        ],
    ],

)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
