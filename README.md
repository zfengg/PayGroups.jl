# PayGroups

[![Build Status](https://github.com/zfengg/PayGroups.jl/workflows/CI/badge.svg)](https://github.com/zfengg/PayGroups.jl/actions)
[![Coverage](https://codecov.io/gh/zfengg/PayGroups.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/zfengg/PayGroups.jl)

A simple interactive solution to group payment.

Why this package?

It solves the frequent but annoying payment issues in our life, especially after a trip with friends favoring a (partial) AA payment plan.

[![asciicast](https://asciinema.org/a/427746.svg)](https://asciinema.org/a/427746?t=7)

> Try it out @ [Repl.it](https://replit.com/@zfengg/PayGroupsjl). It's fun!

## Usage
### Install with [Julia](https://julialang.org/downloads/)'s built-in package manager
```julia
julia> ] add PayGroups
```
and quick start with
```julia
julia> using PayGroups
julia> igroupay() # interactive & return a PayGroup
```

### Clone this repo and run with julia
```bash
git clone https://github.com/zfengg/PayGroups.jl.git
julia PayGroups.jl/run.jl
```

### Online via [Repl.it](https://replit.com/@zfengg/PayGroupsjl)

https://user-images.githubusercontent.com/42152221/127734458-e71469d5-460f-4622-a779-f35235a76e64.mov

## [Compile](https://github.com/zfengg/PayGroups.jl/tree/compile)
Ready to compile with [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl) by switching to branch [complie](https://github.com/zfengg/PayGroups.jl/tree/compile) and run:
```bash
julia compile.jl # excutable @ compiled/bin/PayGroups
```
