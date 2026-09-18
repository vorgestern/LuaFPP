
XFILES   := main copy_options
CPPFLAGS := -I/usr/include/lua5.4 -I LuaAide/include
CXXFLAGS := --std=c++20
# CXXFLAGS += -Wall -Werror
.PHONY: clean dir staticlib

all: dir staticlib luafpp.so test
clean:
	@rm -rf b/* luafpp.so
	@make -C LuaAide clean

dir:
	@mkdir -p b
test: staticlib luafpp.so
	lua unittest.lua

# ============================================================

staticlib:
	make -j -C LuaAide all

LuaAide/libLuaAide.a:
	make -j -C LuaAide all

ulutest/ulutest.so:
	make -j -C ulutest/

# ============================================================

luafpp.so: $(XFILES:%=b/%.o) LuaAide/libLuaAide.a
	g++ -shared -fpic -o $@ $^

b/%.o: src/%.cpp LuaAide/include/LuaAide.h
	g++ -c -fpic -o $@ $< $(CPPFLAGS) $(CXXFLAGS)
