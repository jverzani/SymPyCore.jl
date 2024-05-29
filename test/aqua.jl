using Aqua
using SymPyCore

testtarget = SymPyCore

Aqua.test_unbound_args(testtarget)
Aqua.test_undefined_exports(testtarget)
Aqua.test_project_extras(testtarget)
Aqua.test_stale_deps(testtarget)
Aqua.test_deps_compat(testtarget)
Aqua.test_piracies(testtarget)
Aqua.test_persistent_tasks(testtarget)

Aqua.test_ambiguities([testtarget, Base, Core])
