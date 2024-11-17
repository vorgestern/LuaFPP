
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

extern "C" int subdirs(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)==1)
    {
        if (Q.hasstringat(-1))
        {
            const fspath start(Q.tostring(-1));
            if (!filesystem::exists(start))
            {
                const string meld="subdirs: path does not exist: '"+start.string()+"'";
                Q<<meld>>luaerror;
            }
                    vector<string>subdirs;
                    for (auto const&entry: filesystem::directory_iterator{start})
                        if (entry.is_directory())
                        {
                            const auto s=entry.path().stem();
                            subdirs.push_back(s);
                        }
                    sort(subdirs.begin(), subdirs.end(), less<string>());
                    Q<<subdirs;
                    return 1;
        }
        else
        {
            const auto meld=string("subdirs(path) requires path to be a string, not ")+tostring(Q.typeat(-1)).data()+".";
            return Q<<meld>>luaerror;
        }
    }
    else return Q<<"cd requires argument (string path)">>luaerror;
}

struct fsentry { char Type; std::string name, abspath; };
bool operator <(const fsentry&a, const fsentry&b)
{
    if (a.Type<b.Type) return true; else if (a.Type>b.Type) return false;
    if (a.name<b.name) return true; else if (a.name>b.name) return true;
    return a.abspath<b.abspath;
}

extern "C" int walkdir(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"walkdir requires argument (string path)">>luaerror;
    vector<fsentry>A {};
    unsigned num_ignored=0;
    const fspath root {Q.tostring(1)};
    const bool ignore_dot=true;
    for (const auto&entry: filesystem::directory_iterator(root))
    {
        const auto filename=entry.path().filename().string();
        if (ignore_dot && filename.starts_with(".")){ ++num_ignored; continue; }
        if (entry.is_directory()) A.emplace_back('D', filename, entry.path());
        else if (entry.is_regular_file()) A.emplace_back('F', filename, entry.path());
        else A.emplace_back('?', filename, entry.path());
    }
    sort(A.begin(), A.end(), less<fsentry>());

    Q<<LuaTable(0,0);
    const auto T1=Q.index(-1);
    unsigned e=0;
    for (const auto&entry: A)
    {
        Q<<LuaTable(0,2)<<string(1, entry.Type)>>LuaField("type")
                        <<entry.name>>LuaField("name")
                        <<entry.abspath>>LuaField("abspath")
                        >>LuaElement(stackindex(T1), ++e);
    }
    return 1;
}

extern "C" int mymkdir(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"mkdir requires argument (string path)">>luaerror;
    const fspath neu=Q.tostring(1);
    error_code ec;
    if (!filesystem::create_directories(neu, ec) && ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for cd('", ec.value());
        const string meld=pad+neu.string()+"')";
        return Q<<meld>>luaerror;
    }
    else return 0;
}

} // anon

extern "C" int luaopen_luafils(lua_State*L)
{
    LuaStack Q(L);
    Q   <<LuaTable()
        <<"0.1">>LuaField("version")
        <<"https://github.com/vorgestern/LuaFils.git">>LuaField("url")
        <<pwd>>LuaField("pwd")
        <<cd>>LuaField("cd")
        <<subdirs>>LuaField("subdirs")
        <<walkdir>>LuaField("walkdir")
        <<mymkdir>>LuaField("mkdir");
    return 1;
}

// lua lfs 1.8.0       LuaFils
// =============       =======
// attributes
// chdir               cd
// currentdir          pwd
// dir                 (walkdir)
// link
// lock
// mkdir               mkdir
// rmdir
// symlinkattributes
// setmode
// touch
// unlock
// lock_dir

// lfs attributes
// ==============
// dev
// ino    (U)
// mode
// nlink
// uid    (U, W==0)
// gid    (U, W==0)
// rdev   (U, W==dev)
// access
// modification
// change
// size
// blocks  (U)
// blksize (U)

// LuaFils walkdir Konzept
// =======================
// .DF
// s t
