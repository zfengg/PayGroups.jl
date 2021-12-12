# PayGroups

[![Build Status](https://github.com/zfengg/PayGroups.jl/workflows/CI/badge.svg)](https://github.com/zfengg/PayGroups.jl/actions)
[![Coverage](https://codecov.io/gh/zfengg/PayGroups.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/zfengg/PayGroups.jl)

A simple interactive solution to group payment.

Why this package?

It solves the frequent but annoying payment issues in our life, especially after a trip with friends favoring a (partial) AA payment plan.

[![asciicast](https://asciinema.org/a/427746.svg)](https://asciinema.org/a/427746?t=7)

> Try it out @ [Repl.it](https://replit.com/@zfengg/groupay). It's fun!

## Install

### Locally with [Julia](https://julialang.org/downloads/)

Clone this repo or download [groupay.jl](groupay.jl)

```julia
julia> ] add PayGroups
```
After installation, the easiest way to use `PayGroups`:
```julia
julia> using PayGroups
julia> igroupay() # interactive & return a PayGroup
```

### Online by [Repl.it](https://replit.com/@zfengg/groupay)

https://user-images.githubusercontent.com/42152221/127734458-e71469d5-460f-4622-a779-f35235a76e64.mov
