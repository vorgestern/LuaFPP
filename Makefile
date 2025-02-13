
XFILES   := main
CPPFLAGS := -I/usr/include/lua5.4 -I LuaAide/include
CXXFLAGS := --std=c++20 -Wall -Werror
.PHONY: clean dir

all: dir luafpp.so LuaAide/libLuaAide.a ulutest/ulutest.so test
clean:
	@rm -rf b/* luafpp.so
	@make -C LuaAide clean
	@make -C ulutest clean
dir:
	@mkdir -p b
test: luafpp.so ulutest/ulutest.so
	rm -rf hier/var/*
	lua unittest.lua

# ============================================================

LuaAide/libLuaAide.a:
	make -j -C LuaAide all

ulutest/ulutest.so:
	make -j -C ulutest/

# ============================================================

luafpp.so: b/main.o LuaAide/libLuaAide.a
	g++ -shared -fpic -o $@ $^

b/%.o: src/%.cpp LuaAide/include/LuaAide.h
	g++ -c -Wall -Werror -fpic -o $@ $< $(CPPFLAGS) $(CXXFLAGS)
