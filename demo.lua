
local X=require "luafils"

print "luafils:"
for k,v in pairs(X) do print("==", k, v) end

print("pwd", X.pwd())

X.cd "LuaAide" print("pwd", X.pwd())
X.cd ".."      print("pwd", X.pwd())
