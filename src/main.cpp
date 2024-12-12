
#include <lua.hpp>
#include <LuaAide.h>
#include <filesystem>

using namespace std;
using fspath=filesystem::path;

namespace {

                string permstring(const fspath&was)
                {
                    const auto st=filesystem::status(was);
                    // const auto t=st.type(); // file_status::type
                    const auto p=st.permissions(); // file_status::permissions
                    const filesystem::perms P[9]={
                        filesystem::perms::owner_read,
                        filesystem::perms::owner_write,
                        filesystem::perms::owner_exec,
                        filesystem::perms::group_read,
                        filesystem::perms::group_write,
                        filesystem::perms::group_exec,
                        filesystem::perms::others_read,
                        filesystem::perms::others_write,
                        filesystem::perms::others_exec
                    };
                    const char pp[]="rwxrwxrwx";
                    const auto none=filesystem::perms::none;
                    char pad[]="---------";
                    for (auto j=0; j<9; ++j) pad[j]=(p&P[j])!=none?pp[j]:'-';
                    return pad;
                }

                string typestring(filesystem::file_status s)
                {
                    char pad[]="........";
                    if (filesystem::is_regular_file(s))     pad[0]='F'; // regular file
                    if (filesystem::is_directory(s))        pad[1]='D'; // directory
                    if (filesystem::is_block_file(s))       pad[2]='B'; // block device
                    if (filesystem::is_character_file(s))   pad[3]='C'; // character device
                    if (filesystem::is_fifo(s))             pad[4]='P'; // named IPC pipe
                    if (filesystem::is_socket(s))           pad[5]='S'; // named IPC socket
                    if (filesystem::is_symlink(s))          pad[6]='L'; // symlink
                    if (!filesystem::exists(s))             pad[7]='X'; // does not exist
                    return pad;
                }

                [[maybe_unused]] string typestring(const fspath&was)
                {
                    return typestring(filesystem::status(was)); // .type()
                }

extern "C" int permissions(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"permissions requires argument (string path)">>luaerror;
    const fspath was=Q.tostring(1);
    return Q<<permstring(was), 1;
}

extern "C" int type(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"type requires argument (string path)">>luaerror;
    const fspath was=Q.tostring(1);
    return Q<<typestring(was), 1;
}

extern "C" int numlinks(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"numlinks requires argument (string path)">>luaerror;
    const fspath was=Q.tostring(1);
    error_code ec;
    const auto nlink=hard_link_count(was, ec);
    if (ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof pad, "system error %d for numlinks('", ec.value());
        const string meld=pad+was.string()+"')";
        return Q<<luanil<<meld, 2;
    }
    else return Q<<(int)nlink, 1;
}

extern "C" int filesize(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"filesize requires argument (string path)">>luaerror;
    const fspath was=Q.tostring(1);
    if (is_directory(was)) return Q<<0, 1;
    error_code ec;
    const auto numbytes=file_size(was, ec);
    if (ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof pad, "system error %d for filesize('", ec.value());
        const string meld=pad+was.string()+"')";
        return Q<<luanil<<meld, 2;
    }
    else return Q<<(int)numbytes, 1;
}

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
                return Q<<luanil<<meld, 2;
            }
            error_code ec;
            current_path(neu, ec);
            if (!ec) return Q<<true, 1;
            else
            {
                snprintf(pad, sizeof pad, "system error %d for cd('", ec.value());
                const string meld=pad+neu.string()+"')";
                return Q<<luanil<<meld, 2;
            }
        }
        else
        {
            const auto meld=string("cd(path) requires path to be a string, not ")+tostring(Q.typeat(-1)).data()+".";
            return Q<<luanil<<meld, 2;
        }
    }
    else return Q<<luanil<<"cd requires argument (string path)", 2;
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
                            subdirs.push_back(s.string());
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
        if (entry.is_directory()) A.emplace_back('D', filename, entry.path().string());
        else if (entry.is_regular_file()) A.emplace_back('F', filename, entry.path().string());
        else A.emplace_back('?', filename, entry.path().string());
    }
    sort(A.begin(), A.end(), less<fsentry>());

    Q<<LuaTable({0,0});
    const auto T1=Q.index(-1);
    unsigned e=0;
    for (const auto&entry: A)
    {
        Q<<LuaTable({0,2})<<string(1, entry.Type)>>LuaField("type")
                        <<entry.name>>LuaField("name")
                        <<entry.abspath>>LuaField("abspath")
                        >>LuaElement({stackindex(T1), ++e});
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
        snprintf(pad, sizeof(pad), "system error %d for mkdir('", ec.value());
        const string meld=pad+neu.string()+"')";
        return Q<<luanil<<meld, 2;
    }
    else return Q<<true, 1;
}

extern "C" int myrmdir(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"rmdir requires argument (string path)">>luaerror;
    const fspath toremove=Q.tostring(1);
    error_code ec;
    if (auto f=filesystem::is_directory(toremove, ec); !f || ec.value()!=0)
    {
        if (!f) return Q<<luanil<<string("rmdir('"+toremove.string()+"'): not a directory."), 2;
        else
        {
            char pad[100];
            snprintf(pad, sizeof(pad), "system error %d for rmdir/is_directory('", ec.value());
            const string meld=pad+toremove.string()+"').";
            return Q<<luanil<<meld, 2;
        }
    }
    if (!filesystem::remove(toremove, ec) && ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for rmdir('", ec.value());
        const string meld=pad+toremove.string()+"')";
        return Q<<luanil<<meld, 2;
    }
    else return Q<<true, 1;
}

extern "C" int mytouch(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"touch requires argument (string path)">>luaerror;
    const fspath totouch=Q.tostring(1);
    error_code ec;
    if (auto f=filesystem::is_regular_file(totouch, ec); !f || ec.value()!=0)
    {
        if (!f) return Q<<luanil<<string("touch('"+totouch.string()+"'): not a file or not a regular file."), 2;
        else
        {
            char pad[100];
            snprintf(pad, sizeof(pad), "system error %d for is_regular_file('", ec.value());
            const string meld=pad+totouch.string()+"').";
            return Q<<luanil<<meld, 2;
        }
    }
    if (filesystem::last_write_time(totouch, chrono::file_clock::now(), ec); ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for touch('", ec.value());
        const string meld=pad+totouch.string()+"').";
        return Q<<luanil<<meld, 2;
    }
    return Q<<true,1;
}

int myabsolute(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"absolute requires argument (string path)">>luaerror;
    const fspath toconvert=Q.tostring(1);
    error_code ec;
    const auto neu=filesystem::absolute(toconvert, ec);
    if (ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for filesystem::absolute('", ec.value());
        const string meld=pad+toconvert.string()+"').";
        return Q<<luanil<<meld, 2;
    }
    return Q<<neu.string(),1;
}

int mycanonical(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"canonical requires argument (string path)">>luaerror;
    const fspath toconvert=Q.tostring(1);
    error_code ec;
    const auto neu=filesystem::canonical(toconvert, ec);
    if (ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for filesystem::canonical('", ec.value());
        const string meld=pad+toconvert.string()+"').";
        return Q<<luanil<<meld, 2;
    }
    return Q<<neu.string(),1;
}

int myweakly_canonical(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"canonical requires argument (string path)">>luaerror;
    const fspath toconvert=Q.tostring(1);
    error_code ec;
    const auto neu=filesystem::weakly_canonical(toconvert, ec);
    if (ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for filesystem::weakly_canonical('", ec.value());
        const string meld=pad+toconvert.string()+"').";
        return Q<<luanil<<meld, 2;
    }
    return Q<<neu.string(),1;
}

int myrelative(lua_State*L)
{
    LuaStack Q(L);
    if (height(Q)<1) return Q<<"relative requires argument (string path)">>luaerror;
    const fspath toconvert=Q.tostring(1);
    error_code ec;
    const auto neu=filesystem::relative(toconvert, ec);
    if (ec.value()!=0)
    {
        char pad[100];
        snprintf(pad, sizeof(pad), "system error %d for filesystem::relative('", ec.value());
        const string meld=pad+toconvert.string()+"').";
        return Q<<luanil<<meld, 2;
    }
    return Q<<neu.string(),1;
}

} // anon

#ifndef LUAFPP_EXPORTS
#define LUAFPP_EXPORTS
#endif

extern "C" LUAFPP_EXPORTS int luaopen_luafpp(lua_State*L)
{
    LuaStack Q(L);
    Q   <<LuaTable()
        <<"0.1">>LuaField("version")
        <<"https://github.com/vorgestern/LuaFPP.git">>LuaField("url")
        <<permissions>>LuaField("permissions")
        <<type>>LuaField("type")
        <<numlinks>>LuaField("numlinks")
        <<filesize>>LuaField("filesize")
        <<pwd>>LuaField("pwd")
        <<cd>>LuaField("cd")
        <<subdirs>>LuaField("subdirs")
        <<walkdir>>LuaField("walkdir")
        <<mymkdir>>LuaField("mkdir")
        <<myrmdir>>LuaField("rmdir")
        <<mytouch>>LuaField("touch")
        <<mycanonical>>LuaField("canonical")
        <<myweakly_canonical>>LuaField("weakly_canonical")
        <<myrelative>>LuaField("relative")
        <<myabsolute>>LuaField("absolute");
    return 1;
}
