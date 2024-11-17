
#include <lua.hpp>
#include <LuaAide.h>

#include <filesystem>

using namespace std;
using fspath=filesystem::path;

namespace {
extern "C" int pwd(lua_State*L)
{
    LuaStack Q(L);
    auto X=filesystem::current_path().string();
    Q<<X.c_str();
    return 1;
}

extern "C" int cd(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)==1)
    {
        char pad[100];
        if (Q.hasstringat(-1))
        {
            const fspath neu(Q.tostring(-1));
            if (!filesystem::exists(neu))
            {
                const string meld="cd: path does not exist: '"+neu.string()+"'";
                Q<<meld>>luaerror;
            }
            std::error_code ec;
            current_path(neu, ec);
            if (!ec) return 0;
            else
            {
                sprintf(pad, "system error %d for cd('", ec.value());
                const string meld=pad+neu.string()+"')";
                Q<<meld>>luaerror;
            }
        }
        else
        {
            const auto meld=string("cd(path) requires path to be a string, not ")+tostring(Q.typeat(-1)).data()+".";
            Q<<meld>>luaerror;
        }
    }
    else Q<<"cd requires argument (string path)">>luaerror;
    return 0;
}
} // anon

extern "C" int luaopen_luafils(lua_State*L)
{
    LuaStack Q(L);
    Q   <<LuaTable()
        <<"0.1">>LuaField("version")
        <<"https://github.com/vorgestern/LuaFils.git">>LuaField("url")
        <<pwd>>LuaField("pwd")
        <<cd>>LuaField("cd");
    return 1;
}
