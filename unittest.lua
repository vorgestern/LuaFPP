
-- Prepare Lua's search path so ulutest will be found.
local bpattern={
    ["/"]=";ulutest/?.so",
    ["\\"]=";ulutest\\?.dll",
}
package.cpath=package.cpath..(bpattern[package.config:sub(1,1)] or "")

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
},

{
    name="filesize",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.filesize)) end),
    TT("number", function(T) T:ASSERT_EQ("number", type(X.filesize "ulutest/README.md")) end),
    TT("value", function(T) T:ASSERT_EQ(1073, X.filesize "ulutest/Makefile") end),
},

{
    name="subdirs",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.subdirs)) end),
    TT("table", function(T) T:ASSERT_EQ("table", type(X.subdirs ".")) end),
},

{
    name="walkdir",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.walkdir)) end),
    TT("table", function(T) T:ASSERT_EQ("table", type(X.walkdir ".")) end),
},

{
    name="touch",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.touch)) end),
    TT("boolean", function(T) T:ASSERT_EQ("boolean", type(X.touch "Readme.md")) end),
    TT("true", function(T) T:ASSERT_EQ(true, X.touch "Readme.md") end),
    TT("false", function(T) T:ASSERT_EQ(false, X.touch "notpresent/,.dll") end),
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
        local a=X.canonical "src/none/../main.cpp"
        local sep=package.config:sub(1,1)
        T:ASSERT(a:match "src"..sep.. "main.cpp")
    end),
    -- TT("removesepsep", ..)
    -- TT("removesepdotsep", ..)
},

{
    name="weakly_canonical",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.weakly_canonical)) end),
},

{
    name="relative",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.relative)) end),
},

{
    name="mkdir",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.mkdir)) end),
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
    TT("rwxrwxrwx", function(T) T:ASSERT_EQ("rwxrwxrwx", X.permissions "Makefile") end),
}

)
