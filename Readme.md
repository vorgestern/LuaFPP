
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

    local content=fpp.walkdir "."
    for j,e in ipairs(content) do print(j, e.type, e.catpath) end

# Requirements
+ C++ 20
+ Lua 5.4

# How to build
## Linux

    make

creates luafpp.so.
Copy to where Lua will find it with 'require luafpp'

# How to use: First ..
    fpp=require "luafpp"

## Directories
These do what you would expect:

    fpp.pwd()                                  returns current directory

    local ok,err=fpp.cd ".local/"              changes current directory
    if not ok then error(err) end

    local ok,err=fpp.mkdir "demo/more/empty"   creates a directory (or hierarchy)

    local ok,err=fpp.rmdir "demo/more/empty"   deletes empty directory (i.e. 'empty')

    local ok=fpp.rmrf "demo"                   equivalent of `rm -rf`
                                               true if file/folder existed,
                                               false (not nil) if not

    local dirs,err=fpp.subdirs ".local"        returns a list of subdirectories
    if not dirs then print(err)
    else for _,p in ipairs(dirs) do ...
    end

    assert(X.exists "hier")                    Check whether directory exists (true/nil)

## Files
These do what you would expect:

    local ok,err=fpp.touch ".local/demo/main.cpp"           Touch/create file

    local s,err=fpp.filesize ".local/demo/main.cpp"         Query file size in bytes

    local p,err=fpp.permissions ".local/demo/main.cpp"      Query file permissions ()

    local l,err=fpp.numlink ".local/demo/main.cpp"          Query number of links ()

    assert(X.exists ".local/demo/main.cpp")                 Check whether file exists
                                                            (true/nil)

## File-/Dir-Types

    local t,err=fpp.type ".local/demo/main.cpp"     Query file type as a single letter.
                                                    Uses single-letter-codes documented
                                                    in find (1) for the -type criterion:
                                                    b block (buffered) special
                                                    c character (unbuffered) special
                                                    d directory
                                                    p named pipe (FIFO)
                                                    f regular file
                                                    l symbolic link
                                                    s socket

## Paths
These are more difficult to describe than to implement:

    fpp.absolute
    fpp.relative
    fpp.canonical
    fpp.weakly_canonical

## Walking directories

    fpp.walkdir(<dir>, <opts>)  returns a table with files and folders in <dir>
                                opts is a string with letters in random order:
                                    r  recurse
                                    .  do not skip filenames starting with '.'
                                    N|T|H (one of these) output format
                                        N a string per item (file or folder)
                                        T a table per item {name, type, catpath}
                                        H a table per item {name, type, catpath, content={..}}
                                opts defaults to "T"
                                In tables:
                                type is     "f"|"d"
                                catpath is a string representation of path starting with <dir>

# To do

    Introduce callbacks to filter walking recursion.
    Introduce postprocessing utilities for output from walking directories.

## Done

    Come up with a better representation of file type.
