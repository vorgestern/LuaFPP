
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
    name="pwd",
    TT("present", function(T) T:ASSERT_EQ("function", type(X.pwd)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.pwd())) end),
    TT("usable", function(T)
        local k=io.open(X.pwd().."/test.lua")
        T:ASSERT(k)
        k:close()
        -- Prove we are reading this file.
        local result=nil -- expect 21
        for line in io.lines(X.pwd().."/test.lua") do
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
}

)
