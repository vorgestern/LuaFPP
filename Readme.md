
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

# How to use: First ..
    local fpp=require "luafpp"

## Directories
These do what you would expect:

    fpp.pwd()                               returns current directory
    local ok,err=fpp.cd ".local/demo"       changes current directory
    if not ok then print(err) end
    local ok,err=fpp.mkdir ".local/empty"   creates a directory
    if not ok then print(err) end
    local ok,err=fpp.rmdir ".local/empty"   deletes empty directory
    if not ok then print(err) end
    local ok=X.rmrf ".local/various"        true if file/folder existed, false (not nil) if not
    local ok,err=fpp.rmrf ".local/empty"    equivalent of `rm -rf`
    if not ok then print(err) end
    local dirs,err=fpp.subdirs ".local"     returns a list of subdirectories
    if not dirs then print(err)
    else for _,p in ipairs(dirs) do ...
    end
    assert(X.exists "hier")                 Check whether directory exists (true/nil)

## Files
These do what you would expect:

    local ok,err=fpp.touch ".local/demo/main.cpp"           Touch/create file
    if not ok then print(err) end
    local s,err=fpp.filesize ".local/demo/main.cpp"         Query file size in bytes
    if not s then print(err) end
    local t,err=fpp.type ".local/demo/main.cpp"             Query file type ("file", "dir)
    if not s then print(err) end
    local p,err=fpp.permissions ".local/demo/main.cpp"      Query file permissions ()
    if not p then print(err) end
    local l,err=fpp.numlink ".local/demo/main.cpp"          Query number or links ()
    if not p then print(err) end
    assert(X.exists "hier/Makefile")                        Check whether file exists (true/nil)

## Paths
These are more difficult to describe than to implement:

    fpp.absolute
    fpp.relative
    fpp.canonical
    fpp.weakly_canonical

## Walking directories

    fpp.walkdir(".local", "rN", nil)

# To do

- Come up with a better representation of file type.
- Introduce callbacks to filter walking recursion.
- Introduce postprocessing utilities for output from walking directories.
