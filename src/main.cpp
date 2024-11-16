
#include <lua.hpp>
#include <LuaAide.h>

extern "C" int luaopen_luafils(lua_State*L)
{
    LuaStack Q(L);
    Q   <<LuaTable()
        <<"0.1">>LuaField("version")
        <<"https://github.com/vorgestern/LuaFils.git">>LuaField("url");
    return 1;
}
