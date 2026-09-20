
-- Prepare Lua's search path so locally built copies of luafpp and ulutest will be found.
local bpattern={
    ["/"]="./?.so;LuaAide/ulutest/?.so;",
    ["\\"]=".\\?.dll;LuaAide\\ulutest\\?.dll;",
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

local TCASE=function(name)
    return function(tests)
        tests.name=name
        return tests
    end
end

ULU.RUN {

TCASE "version" {
    TT("present", function(T) T:ASSERT_EQ("string", type(X.version)) end),
    TT("value", function(T) T:ASSERT_EQ("0.1.3", X.version) end)
},

TCASE "url" {
    TT("present", function(T) T:ASSERT_EQ("string", type(X.url)) end),
    TT("value", function(T) T:ASSERT_EQ("https://github.com/vorgestern/LuaFPP.git", X.url) end)
},

TCASE "pwd" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.pwd)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.pwd())) end),
    TT("usable", function(T)
        local k=io.open(X.pwd().."/unittest.lua")
        T:ASSERT(k)
        k:close()
        -- Prove we are reading this file.
        local result=nil -- expect 21
        for line in io.lines(X.pwd().."/unittest.lua") do
            result=result or line:match "%-%- expect (%d+)"
            -- print(result, line)
        end
        T:ASSERT_EQ("21", result)
    end),
},

TCASE "cd" {
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
        local ok,err=X.cd "testdir/none"
        T:ASSERT_NIL(ok)
        T:ASSERT_EQ("string", type(err))
    end),
},

TCASE "exists" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.exists)) end),
    TT("bool true", function(T) T:ASSERT_EQ("boolean", type(X.exists "Readme.md")) end),
    TT("file not found", function(T) T:ASSERT_NIL(X.exists("testdir/none")) end)
},

TCASE "filesize" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.filesize)) end),
    TT("number", function(T) T:ASSERT_EQ("number", type(X.filesize "Readme.md")) end),
    TT("value", function(T)
        local text="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        io.output("filesize.test","b"):write(text)
        io.close()
        io.output(io.stdout)
        T:ASSERT_EQ(26, X.filesize "filesize.test")
        local a,b=os.remove "filesize.test"
        T:ASSERT_EQ(nil,b)
        T:ASSERT(a)
    end),
    TT("no error", function(T) local size,err=X.filesize "testdir/project/Makefile"; T:ASSERT_EQ("number", type(size)); T:ASSERT_NIL(err) end),
    TT("file not found", function(T) local size,err=X.filesize "testdir/none"; T:ASSERT_NIL(size); T:ASSERT_EQ("string", type(err)) end)
},

TCASE "subdirs" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.subdirs)) end),
    TT("table", function(T)
        T:ASSERT_EQ("table", type(X.subdirs "testdir"))
        T:ASSERT_EQ(2, #X.subdirs "testdir")
    end),
    TT("dir does not exist", function(T)
        local dirs,err=X.subdirs "testdir/none"
        T:ASSERT_NIL(dirs)
        T:ASSERT_EQ("string", type(err))
    end)
},

 TCASE "walkdir" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.walkdir)) end),
    TT("table", function(T) T:ASSERT_EQ("table", type(X.walkdir ".")) end)
},

TCASE "walkdir-N" {
    TT("list", function(T)
        T:ASSERT_EQ("table", type(X.walkdir("testdir", "N")))
        T:ASSERT_EQ(13, #X.walkdir("testdir/project", "rN"))
        T:ASSERT_EQ(15, #X.walkdir("testdir/project", ".rN"))
        T:ASSERT_EQ(4, #X.walkdir("testdir/project", "N"))
        T:ASSERT_EQ("string", type(table.concat(X.walkdir("testdir/project", "rN"))))
    end),
    TT("ignore", function(T)
        T:ASSERT(#X.walkdir("testdir/project", "N") < #X.walkdir("testdir/project", ".N")) -- .N finds aditional files
    end),
    TT("recursive", function(T)
        T:ASSERT(#X.walkdir("testdir/project", "N") < #X.walkdir("testdir/project", "rN")) -- rN finds aditional files
    end),
},

TCASE "touch" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.touch)) end),
    TT("boolean", function(T) T:ASSERT_EQ("boolean", type(X.touch "testdir/project/Makefile")) end),
    TT("true", function(T) T:ASSERT_EQ(true, X.touch "testdir/project/Readme.md") end),
    TT("false", function(T) T:ASSERT_EQ(false, X.touch "testdir/var/notpresent/,.dll") end),
},

TCASE "absolute" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.absolute)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.absolute ".")) end),
    -- Cannot come up with a scenario that will fail.
    TT("DISABLED_errormessage", function(T)
        local flag,result=X.absolute "./../../../../../../../../notpresent"
        T:ASSERT_EQ(nil,flag)
        T:ASSERT_EQ("xx", result)
    end),
},

TCASE "canonical" {
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

TCASE "weakly_canonical" {
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

TCASE "relative" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.relative)) T:PRINTF "This test is not very useful so far" end),
},

TCASE "mkdir" {
    setup=function(T)
        T:ASSERT_NOTNIL(X.rmrf "testdir/var/neu") -- Accept true (deleted) or false (nothing to delete), but not nil (failure)
    end,
    TT("present", function(T) T:ASSERT_EQ("function", type(X.mkdir)) end),
    TT("success", function(T)
        T:ASSERT_NIL(X.exists "testdir/var/neu")
        T:ASSERT(X.mkdir "testdir/var/neu")
        T:ASSERT_EQ("d", X.type "testdir/var/neu")
    end),
    -- teardown=function(T) end
},

TCASE "rmdir" {
    setup=function(T)
        T:ASSERT(X.mkdir "testdir/var/empty")
        T:ASSERT_NOTNIL(X.rmrf "testdir/var/neu1")
    end,
    TT("present", function(T) T:ASSERT_EQ("function", type(X.rmdir)) end),
    TT("success", function(T)
        T:ASSERT(X.mkdir "testdir/var/empty")
        T:ASSERT(X.rmdir "testdir/var/empty")
    end),
    TT("fail, not empty", function(T)
        T:ASSERT_NIL(X.exists "testdir/var/neu1")
        T:ASSERT(X.mkdir "testdir/var/neu1")
        T:ASSERT(X.mkdir "testdir/var/neu1/mehr")
        T:ASSERT_NIL(X.rmdir "testdir/var/neu1")
    end),
},

TCASE "rmrf" {
    setup=function(T)
        T:ASSERT(X.mkdir "testdir/var/empty")
        T:ASSERT(X.rmrf "testdir/var/neu1")
    end,
    TT("present", function(T) T:ASSERT_EQ("function", type(X.rmrf)) end),
    TT("success for empty dir", function(T)
        T:ASSERT(X.mkdir "testdir/var/demo_rmrf")
        T:ASSERT(X.rmrf "testdir/var/demo_rmrf")
    end),
    TT("success for nonempty dir", function(T)
        T:ASSERT_NIL(X.exists "testdir/var/demo_rmrf")
        T:ASSERT(X.mkdir "testdir/var/demo_rmrf")
        T:ASSERT(X.mkdir "testdir/var/demo_rmrf/details")
        T:ASSERT(X.rmrf "testdir/var/demo_rmrf")
    end),
    TT("success for regular file", function(T)
        T:ASSERT_NIL(X.exists "testdir/var/demo_rmrf.txt")
        io.output "testdir/var/demo_rmrf.txt" :write "hoppla"
        io.close()
        io.output(io.stdout)
        T:ASSERT(X.exists "testdir/var/demo_rmrf.txt")
        local ok,err=X.rmrf "testdir/var/demo_rmrf.txt"
        T:ASSERT_NIL(err)
        T:ASSERT(ok)
        T:ASSERT_NIL(X.exists "testdir/var/demo_rmrf.txt")
    end),
    TT("success/false for inexistent file or folder", function(T)
        T:ASSERT_NIL(X.exists "testdir/var/demo_rmrf.txt")
        T:ASSERT_EQ(false, X.rmrf "testdir/var/demo_rmrf.txt")  -- return false if file does not exists
    end),
},

TCASE "numlinks" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.numlinks)) T:PRINTF "This test is not very useful so far" end),
    TT("number", function(T) T:ASSERT_EQ("number", type(X.numlinks "Makefile")) end),
},

TCASE "type" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.type)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.type "Makefile")) end),
    TT("value F", function(T) T:ASSERT_EQ("f", X.type "Makefile") end),
    TT("value D", function(T) T:ASSERT_EQ("d", X.type "src") end),
},

TCASE "permissions" {
    TT("present", function(T) T:ASSERT_EQ("function", type(X.permissions)) end),
    TT("string", function(T) T:ASSERT_EQ("string", type(X.permissions "Makefile")) end),
    TT("rwxrwxrwx", function(T) T:ASSERT(X.permissions "Makefile" :match "rw.r..r..") end),
},

TCASE "copy_options" {
    TT("present", function(T) T:ASSERT_EQ("table", type(X.copy_options)) end),
    TT("expected_values", function(T)
        for k,e in ipairs {"none", "skip_existing", "overwrite_existing", "update_existing", "recursive",
            "copy_symlinks", "skip_symlinks", "directories_only", "create_symlinks","create_hard_links"} do
                T:EXPECT_EQ("userdata", type(X.copy_options[e]))
        end
    end),
    TT("string representation", function(T)
        for k,e in ipairs {"none", "skip_existing", "overwrite_existing", "update_existing", "recursive",
            "copy_symlinks", "skip_symlinks", "directories_only", "create_symlinks","create_hard_links"} do
                T:EXPECT_EQ(e, tostring(X.copy_options[e]))
        end
        T:EXPECT_EQ("overwrite_existing|recursive", tostring(X.copy_options.overwrite_existing | X.copy_options.recursive))
    end),
    TT("string representation (or'd)", function(T)
        local co=X.copy_options
        local K={"skip_existing", "overwrite_existing", "update_existing", "recursive",
            "copy_symlinks", "skip_symlinks", "directories_only", "create_symlinks","create_hard_links"}
        for j1=1,#K do
            local k1=K[j1]
            T:ASSERT_EQ(tostring(co[k1]), tostring(co[k1] | co[k1]))
            for j2=j1+1,#K do
                local k2=K[j2]
                T:ASSERT_EQ(k1.."|"..k2, tostring(co[k1] | co[k2]))
            end
        end
        T:EXPECT_EQ("overwrite_existing|recursive", tostring(X.copy_options.overwrite_existing | X.copy_options.recursive))
    end),
    TT("numeric", function(T)
        for k,e in ipairs {"none", "skip_existing", "overwrite_existing", "update_existing", "recursive",
            "copy_symlinks", "skip_symlinks", "directories_only", "create_symlinks","create_hard_links"} do
                T:EXPECT_EQ("number", type(X.copy_options[e]:numeric()))
        end
    end),
    TT("numeric (or'd)", function(T)
        local co=X.copy_options
        local K={"skip_existing", "overwrite_existing", "update_existing", "recursive",
            "copy_symlinks", "skip_symlinks", "directories_only", "create_symlinks","create_hard_links"}
        for j1=1,#K do
            local opt1=co[K[j1]]
            T:ASSERT_EQ(opt1:numeric(), (opt1|opt1):numeric())
            for j2=j1+1,#K do
                local opt2=co[K[j2]]
                T:ASSERT_EQ(opt1:numeric()|opt2:numeric(), (opt1|opt2):numeric())
            end
        end
    end),
    TT("has_bitops", function(T)
        local co=X.copy_options
        local optneu=co.skip_existing | co.recursive;
        T:ASSERT_EQ("userdata", type(optneu))
        T:ASSERT_EQ(co.recursive, optneu & co.recursive)
        T:ASSERT_EQ(co.skip_existing, optneu & co.skip_existing)
    end),
},

TCASE "copy_file" {
    setup=function(T)
        T:ASSERT(X.exists "testdir/project/Readme.md")
        os.remove "testdir/var/Readme.md"
    end,
    TT("present", function(T) T:ASSERT_EQ("function", type(X.copy_file)) end),
    TT("existing", function(T)
        T:ASSERT(X.copy_file("testdir/project/Readme.md", "testdir/var/Readme.md"))
    end),
    TT("nooverwrite", function(T)
        T:ASSERT_NIL(X.copy_file("testdir/project/hiersrc/Readme.md", "testdir/var/Readme.md"))
    end),
    TT("allow_overwrite", function(T)
        T:ASSERT(X.copy_file("testdir/project/hiersrc/App1/Readme.md", "testdir/var/Readme.md", X.copy_options.overwrite_existing))
    end),
    teardown=function(T)
        T:ASSERT(X.exists "testdir/var/Readme.md")
        os.remove "testdir/var/Readme.md"
    end,
},

}
