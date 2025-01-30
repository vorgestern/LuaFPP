
-- Prepare Lua's search path so ulutest will be found.
local bpattern={
    ["/"]="ulutest/?.so;",
    ["\\"]="ulutest\\?.dll;",
}
package.cpath=(bpattern[package.config:sub(1,1)] or "")..package.cpath

local ok,X=pcall(require, "luafpp")

if not ok then
    error("\n\tThis is a test suite for 'luafpp'."..
    "\n\tHowever, require 'luafpp' failed."..
    "\n\tBuild it right here.")
end

local ok,ULU=pcall(require, "ulutest")

if not ok then
    error("\n\tThis is a Unit Test implemented with 'ulutest'."..
    "\n\tHowever, require 'ulutest' failed."..
    "\n\tBuild it as a submodule right here.")
end

local TT=ULU.TT

ULU.RUN(

{
    name="version",
    TT("present", function(T) T:ASSERT_EQ("string", type(X.version)) end),
    TT("value", function(T) T:ASSERT_EQ("0.1", X.version) end)
},

{
    name="url",
    TT("present", function(T) T:ASSERT_EQ("string", type(X.url)) end),
    TT("value", function(T) T:ASSERT_EQ("https://github.com/vorgestern/LuaFPP.git", X.url) end)
},

{
    name="pwd",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.pwd)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.pwd())) end),
    TT("usable", function(T)
        local k=io.open(X.pwd().."/unittest.lua")
        T:ASSERT(k)
        k:close()
        -- Prove we are reading this file.
        local result=nil -- expect 21
        for line in io.lines(X.pwd().."/unittest.lua") do
            result=result or line:match "--expect (%d+)"
            -- print(result, line)
        end
        T:ASSERT_EQ("21", result)
    end),
},

{
    name="cd",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.cd)) end),
    TT("void", function(T) T:ASSERT_EQ("nil", type(X.cd())) end),
    TT("usable", function(T)
        local here=X.pwd()
        X.cd "src"
        local where=X.pwd()
        X.cd ".."
        T:ASSERT_EQ(here, X.pwd())
        local sep=package.config:sub(1,1)
        T:ASSERT_EQ(here..sep.."src", where)
    end),
    TT("dir does not exist", function(T)
        local ok,err=X.cd "hier/none"
        T:ASSERT_NIL(ok)
        T:ASSERT_EQ("string", type(err))
    end),
},

{
    name="exists",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.exists)) end),
    TT("bool true", function(T) T:ASSERT_EQ("boolean", type(X.exists "ulutest/README.md")) end),
    TT("file not found", function(T) T:ASSERT_NIL(X.exists("hier/none")) end)
},

{
    name="filesize",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.filesize)) end),
    TT("number", function(T) T:ASSERT_EQ("number", type(X.filesize "ulutest/README.md")) end),
    TT("value", function(T) T:ASSERT_EQ(1038, X.filesize "ulutest/Makefile") end),
    TT("no error", function(T) local size,err=X.filesize "hier/project/Makefile"; T:ASSERT_EQ("number", type(size)); T:ASSERT_NIL(err) end),
    TT("file not found", function(T) local size,err=X.filesize "hier/none"; T:ASSERT_NIL(size); T:ASSERT_EQ("string", type(err)) end)
},

{
    name="subdirs",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.subdirs)) end),
    TT("table", function(T)
        T:ASSERT_EQ("table", type(X.subdirs "hier"))
        T:ASSERT_EQ(2, #X.subdirs "hier")
    end),
    TT("dir does not exist", function(T)
        local dirs,err=X.subdirs "hier/none"
        T:ASSERT_NIL(dirs)
        T:ASSERT_EQ("string", type(err))
    end)
},

{
    name="walkdir",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.walkdir)) end),
    TT("table", function(T) T:ASSERT_EQ("table", type(X.walkdir ".")) end)
},

{
    name="walkdir-N",
    TT("list", function(T)
        T:ASSERT_EQ("table", type(X.walkdir("hier", "N")))
        T:ASSERT_EQ(14, #X.walkdir("hier/project", "rN"))
        T:ASSERT_EQ(4, #X.walkdir("hier/project", "N"))
        T:ASSERT_EQ("string", type(table.concat(X.walkdir("hier/project", "rN"))))
    end),
    TT("ignore", function(T)
        T:ASSERT(#X.walkdir("hier/project", "N") < #X.walkdir("hier/project", ".N")) -- .N finds aditional files
    end),
    TT("recursive", function(T)
        T:ASSERT(#X.walkdir("hier/project", "N") < #X.walkdir("hier/project", "rN")) -- rN finds aditional files
    end),
},

{
    name="touch",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.touch)) end),
    TT("boolean", function(T) T:ASSERT_EQ("boolean", type(X.touch "hier/project/Makefile")) end),
    TT("true", function(T) T:ASSERT_EQ(true, X.touch "hier/project/Readme.md") end),
    TT("false", function(T) T:ASSERT_EQ(false, X.touch "hier/var/notpresent/,.dll") end),
},

{
    name="absolute",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.absolute)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.absolute ".")) end),
    -- Cannot come up with a scenario that will fail.
    TT("DISABLED_errormessage", function(T)
        local flag,result=X.absolute "./../../../../../../../../notpresent"
        T:ASSERT_EQ(nil,flag)
        T:ASSERT_EQ("xx", result)
    end),
},

{
    name="canonical",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.canonical)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.canonical ".")) end),
    TT("removedotdot", function(T)
        local a,b=X.canonical "src/../src/main.cpp"
        T:ASSERT_EQ(nil,b)
        local sep=package.config:sub(1,1)
        T:ASSERT(a:match "src"..sep.. "main.cpp")
    end),
    -- TT("removesepsep", ..)
    -- TT("removesepdotsep", ..)
},

{
    name="weakly_canonical",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.weakly_canonical)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.weakly_canonical ".")) end),
    TT("removedotdot", function(T)
        local a,b=X.canonical "src/../src/main.cpp"
        T:ASSERT_EQ(nil,b)
        local sep=package.config:sub(1,1)
        T:ASSERT(a:match "src"..sep.. "main.cpp")
    end),
    -- TT("removesepsep", ..)
    -- TT("removesepdotsep", ..)
},

{
    name="relative",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.relative)) end),
},

{
    name="mkdir",
    -- Use of setup/teardown has not been implemented yet.
    -- However, the makefile clears hier/var before running the unittest,
    -- so `make test` is guaranteed to work, whereas `lua unittest.lua`
    -- might fail on repeated executions.
    setup=function(T)
        T:ASSERT(X.rmdir "hier/var/neu")
    end,
    TT("present", function(T) T:ASSERT_EQ("function", type(X.mkdir)) end),
    TT("success", function(T)
        T:ASSERT_NIL(X.exists "hier/var/neu")
        T:ASSERT(X.mkdir "hier/var/neu")
        T:ASSERT_EQ(".D......", X.type "hier/var/neu")
    end),
    -- teardown=function(T) end
},

{
    name="rmdir",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.rmdir)) end),
},

{
    name="numlinks",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.numlinks)) end),
    TT("number", function(T) T:ASSERT_EQ("number", type(X.numlinks "Makefile")) end),
},

{
    name="type",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.type)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.type "Makefile")) end),
    TT("value F", function(T) T:ASSERT_EQ("F.......", X.type "Makefile") end),
    TT("value D", function(T) T:ASSERT_EQ(".D......", X.type "src") end),
},

{
    name="permissions",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.permissions)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.permissions "Makefile")) end),
    TT("rwxrwxrwx", function(T) T:ASSERT(X.permissions "Makefile" :match "rw.r..r..") end),
}

)
