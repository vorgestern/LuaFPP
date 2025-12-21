
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

    git submodule init
    git submodule update --init --recursive
    make

creates luafpp.so.
Copy to where Lua will find it with 'require luafpp'

# How to use: First ..
    fpp=require "luafpp"

## Directories
These do what you would expect:

<pre>
    <b>fpp.pwd</b>()                                  returns current directory

    local ok,err=<b>fpp.cd</b> ".local/"              changes current directory
    if not ok then error(err) end

    local ok,err=<b>fpp.mkdir</b> "demo/more/empty"   creates a directory (or hierarchy)

    local ok,err=<b>fpp.rmdir</b> "demo/more/empty"   deletes empty directory (i.e. 'empty')

    local ok=<b>fpp.rmrf</b> "demo"                   equivalent of `rm -rf`
                                               true if file/folder existed,
                                               false (not nil) if not

    local dirs,err=<b>fpp.subdirs</b> ".local"        returns a list of subdirectories
    if not dirs then print(err)
    else for _,p in ipairs(dirs) do ...
    end

    assert(<b>fpp.exists</b> "hier")                  Check whether directory exists (true/nil)
</pre>

## Files
These do what you would expect:

<pre>
    local ok,err=<b>fpp.touch</b> ".local/demo/main.cpp"           Touch/create file

    local s,err=<b>fpp.filesize</b> ".local/demo/main.cpp"         Query file size in bytes

    local p,err=<b>fpp.permissions</b> ".local/demo/main.cpp"      Query file permissions ()

    local l,err=<b>fpp.numlink</b> ".local/demo/main.cpp"          Query number of links ()

    assert(<b>fpp.exists</b> ".local/demo/main.cpp")               Check whether file exists
                                                            (true/nil)
</pre>

## File-/Dir-Types

<pre>
    local t,err=<b>fpp.type</b> ".local/demo/main.cpp"     Query file type as a single letter.
                                                    Uses single-letter-codes documented
                                                    in find (1) for the -type criterion:
                                                    <b>b</b> block (buffered) special
                                                    <b>c</b> character (unbuffered) special
                                                    <b>d</b> directory
                                                    <b>p</b> named pipe (FIFO)
                                                    <b>f</b> regular file
                                                    <b>l</b> symbolic link
                                                    <b>s</b> socket
</pre>

## Paths
These are more difficult to describe than to implement:

<pre>
    <b>fpp.absolute</b>
    <b>fpp.relative</b>
    <b>fpp.canonical</b>
    <b>fpp.weakly_canonical</b>
</pre>

## Walking directories

<pre>
    <b>fpp.walkdir</b>(&lt;dir&gt;, &lt;opts&gt;)  returns a table with files and folders in <dir>
                                opts is a string with letters in random order:
                                    r  recurse
                                    .  do not skip files and folders starting with '.'
                                    N|T|H (one of these) output format
                                        N a string per item (file or folder)
                                        T a table per item {name, type, catpath}
                                        H a table per item {name, type, catpath, content={..}}
                                opts defaults to "T"
                                In tables:
                                type is the return value of <b>fpp.type</b> on the object.
                                catpath is a string representation of path starting with &lt;dir&gt;.
                                content is the result of recursing into folders.
</pre>

# To do

    Introduce callbacks to filter walking recursion.
    Introduce postprocessing utilities for output from walking directories.

## Done

    Come up with a better representation of file type.
