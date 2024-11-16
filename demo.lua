
local X=require "luafils"

print "luafils:"
for k,v in pairs(X) do print("==", k, v) end

print("pwd="..X.pwd())
