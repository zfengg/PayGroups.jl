using Pkg
Pkg.activate(".")
Pkg.instantiate()
using PackageCompiler
run(`rm -rf compiled`)
create_app(".", "compiled")
