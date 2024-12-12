
local X=require "luafpp"

print "luafpp:"
for k,v in pairs(X) do print("==", k, v) end

print("pwd", X.pwd())

X.cd "LuaAide" print("pwd", X.pwd())
X.cd ".."      print("pwd", X.pwd())

local D=X.subdirs "."
for j,k in ipairs(D) do print("==",j,k) end

X.mkdir "neuesdir"

print "mkdir neuesdir: walkdir .:"
local A=X.walkdir "."
for k,v in ipairs(A) do
    local s=string.format("%s %s == %s", v.type, v.name, v.abspath)
    print("==", k, s)
end

X.rmdir "neuesdir"

print "remove neuesdir: walkdir .:"
local A=X.walkdir "."
for k,v in ipairs(A) do
    local s=string.format("%s %s == %s", v.type, v.name, v.abspath)
    print("==", k, s)
end

local f,err=X.touch "nixda.txt"
if not f then
    -- io.output "nixda.txt" :write "nixda"
    -- io.close()
    print("Cannot touch nixda.txt:", err)
end

print "=========="
for k,v in ipairs(A) do
    local s=string.format("%s %3d  user group %8d %s   %s   %s", X.permissions(v.abspath), X.numlinks(v.abspath), X.filesize(v.abspath), X.type(v.abspath), v.type, v.name)
    print(s)
end

print "=========="
print("Makefile, absolute:", X.absolute "Makefile")
