
XFILES   := main
CPPFLAGS := -I/usr/include/lua5.4
CXXFLAGS := --std=c++20 -Wall -Werror
.PHONY: clean dir

all: dir luafils.so
clean:
	@rm -rf b/* luafils.so
dir:
	@mkdir -p b

# ============================================================

luafils.so: b/main.o
	g++ -shared -fpic -o $@ $^

b/%.o: src/%.cpp
	g++ -c -Wall -Werror -fpic -o $@ $< $(CPPFLAGS) $(CXXFLAGS)
