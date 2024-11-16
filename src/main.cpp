
#include <lua.hpp>

extern "C" int luaopen_luafils(lua_State*L)
{
    lua_newtable(L);
    lua_pushstring(L, "version");
    lua_pushstring(L, "0.1");
    lua_settable(L, -3);
    return 1;
}
