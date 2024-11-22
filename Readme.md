
# Purpose
Expose the functions and types of C++ std::filesystem to Lua scripts.<br/>
Provide source with zero config and zero #ifdef.

# Examples

    fpp=require "luafpp"
    print("Use luafpp version", fpp.version)
    print("Working directory", fpp.pwd())
    local here=fpp.pwd()
    fpp.cd ".."
    print("Parent directory", fpp.pwd())
    fpp.cd(here)
    local tree=fpp.walkdir "."
    for j,e in ipairs(tree) do print(j,e.type, e.abspath) end

# Requirements
+ C++ 20
+ Lua 5.4

# How to build
## Linux

    make

creates luafpp.so.
Copy to where Lua will find it with 'require luafpp'
