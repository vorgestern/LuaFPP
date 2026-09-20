
#include <filesystem>
#include <LuaAide.h>
#include <iostream>
#include <cstdint>

using namespace std;
using namespace LuaAide;

using co=std::filesystem::copy_options;

namespace {

const auto mtname="mtcopy_options";
const void*mtpointer=nullptr; // identify metatable via lua_topointer()

static int pushenum(LuaStack&Q, co value)
{
    co*opt=reinterpret_cast<co*>(lua_newuserdatauv(Q, sizeof(co), 0)); // [userdata]
    *opt=value;
    auto newvalue=Q.index(-1);
    Q<<LuaValue(LUA_REGISTRYINDEX)<<LuaField(mtname); // [userdata, registry, registry.mtcopy_options]
    lua_setmetatable(Q, stackindex(newvalue));        // [userdata, registry]
    Q.drop(1);                                        // [userdata]
    return 1;
}

bool isenum(lua_State*L, int index)
{
    LuaStack Q(L);
    if (!Q.hasat(LuaType::TUSERDATA, index)) return false;
    if (!lua_getmetatable(L, index)) return false;
    const void*p=lua_topointer(L, -1);
    Q.drop(1);
    return p==mtpointer;
}

int mynumeric(lua_State*L)
{
    LuaStack Q(L);
    Q.argcheck(1, isenum, "copy_options");
    const auto value=*reinterpret_cast<co*>(lua_touserdata(L, -1));
    return Q<<(int)value, 1;
}

int mybitor(lua_State*L)
{
    LuaStack Q(L);
    Q.argcheck(1, isenum, "copy_options");
    Q.argcheck(2, isenum, "copy_options");
    const auto a=*reinterpret_cast<co*>(lua_touserdata(L, -1));
    const auto b=*reinterpret_cast<co*>(lua_touserdata(L, -2));
    Q.drop(2);
    return pushenum(Q, a|b);
}

int mybitand(lua_State*L)
{
    LuaStack Q(L);
    Q.argcheck(1, isenum, "copy_options");
    Q.argcheck(2, isenum, "copy_options");
    const auto a=*reinterpret_cast<co*>(lua_touserdata(L, -1));
    const auto b=*reinterpret_cast<co*>(lua_touserdata(L, -2));
    Q.drop(2);
    return pushenum(Q, a&b);
}

int myeq(lua_State*L)
{
    LuaStack Q(L);
    Q.argcheck(1, isenum, "copy_options");
    Q.argcheck(2, isenum, "copy_options");
    const auto a=*reinterpret_cast<co*>(lua_touserdata(L, -1));
    const auto b=*reinterpret_cast<co*>(lua_touserdata(L, -2));
    Q.drop(2);
    Q<<(a==b);
    return 1;
}

int mytostring(lua_State*L)
{
    LuaStack Q(L);
    Q.argcheck(1, isenum, "copy_options");
    const auto value=*reinterpret_cast<co*>(lua_touserdata(L, -1));
    switch (value)
    {
        case co::none: return Q<<"none", 1;
        case co::skip_existing: return Q<<"skip_existing", 1;
        case co::overwrite_existing: return Q<<"overwrite_existing", 1;
        case co::update_existing: return Q<<"update_existing", 1;
        case co::recursive: return Q<<"recursive", 1;
        case co::copy_symlinks: return Q<<"copy_symlinks", 1;
        case co::skip_symlinks: return Q<<"skip_symlinks", 1;
        case co::directories_only: return Q<<"directories_only", 1;
        case co::create_symlinks: return Q<<"create_symlinks", 1;
        case co::create_hard_links: return Q<<"create_hard_links", 1;
        default: return Q<<"<unknown>", 1;
    }
}

} // anon

int pushenum_copyoptions(lua_State*L)
{
    LuaStack Q=L;
    auto M=Q.index(-1);

    // Create metatable.
    Q<<newtable
        <<"copy_options">>LuaMetaMethod::name
        <<mytostring>>LuaMetaMethod::tostring // [M, metatable]
        <<mybitor>>LuaMetaMethod::bor
        <<mybitand>>LuaMetaMethod::band
        <<myeq>>LuaMetaMethod::eq
        <<mynumeric>>LuaField("numeric")
    ;
    mtpointer=lua_topointer(L, -1);
    Q.dup(); Q>>LuaMetaMethod::index;          // [M, metatable]
    auto mt=Q.index(-1);

    Q<<LuaValue(LUA_REGISTRYINDEX)<<mt>>LuaField(mtname)<<luadrop;

    Q<<LuaTable();                              // [M, metatable, E]
        pushenum(Q, co::none);                  Q>>LuaField("none");
        pushenum(Q, co::skip_existing);         Q>>LuaField("skip_existing");
        pushenum(Q, co::overwrite_existing);    Q>>LuaField("overwrite_existing");
        pushenum(Q, co::update_existing);       Q>>LuaField("update_existing");
        pushenum(Q, co::recursive);             Q>>LuaField("recursive");
        pushenum(Q, co::copy_symlinks);         Q>>LuaField("copy_symlinks");
        pushenum(Q, co::skip_symlinks);         Q>>LuaField("skip_symlinks");
        pushenum(Q, co::directories_only);      Q>>LuaField("directories_only");
        pushenum(Q, co::create_symlinks);       Q>>LuaField("create_symlinks");
        pushenum(Q, co::create_hard_links);     Q>>LuaField("create_hard_links");

    Q<<luaswap<<luadrop;

    return 1;
}
