
local X=require "luafils"

print "luafils:"
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

if not X.touch "nixda.txt" then
    io.output "nixda.txt" :write "nixda"
    io.close()
end

X.touch "nixda.txt"
