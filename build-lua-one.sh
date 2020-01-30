#!/bin/bash

# build-lua-one.sh is a script that reads a Lua source tree, and
#  builds two files from it -- lua_one.o and lua_one.sh, ready to
#  be dropped into a C/C++ project that uses Lua.

# Define the C compiler
# If the main project uses C++, it will save an awful lot of awkwardness
#  if you build Lua with g++, even though it builds fine with gcc.
CC=gcc

# Define which bits to include. If none of the libraries below is
#  included, the executable size is redued by about 40%
# Include math.xxx() functions
# Note that some floating-point operations are built deeply into the
#  core of Lua, and cannot easily be excluded. Calling these functions
#  (such as when converting number formats) might have odd results.
# It should not be necessary to link -lm if the math library is
#  excluded
#INCLUDE_MATH=1

# Include string.xxx() functions
#INCLUDE_STRING=1

# Include io.xxx() functions
#INCLUDE_IO=1

# Include UTF8 manipulation functions
#INCLUDE_UTF8=1

# Include table manipulation functions
#INCLUDE_TABLE=1

# Include dynamic package searching and loading (large) 
#INCLUDE_PACKAGE=1

# Include db.xxx() functions
#INCLUDE_DB=1

# Include os.xxx() I/O functions
#INCLUDE_OS=1

# Include corouting support
#INCLUDE_COROUTINES=1

# Include lua_dump() and all its dependencies. This function 
#  writes compiledbytecode to a file, where it can be read back later
#INCLUDE_DUMP=1

# Include support for reading compiled bytecode chunks from files. 
# In general, Lua's file loading functions check for compiled bytecode
#  and load it without parsing. If this support is disabled, it will
#  only be possible to load text (and compile it)
#INCLUDE_UNDUMP=1

# The temporary C file to build
ONE="one.c"

# The directory into which to place lua_one.o and lua_one.h
BUILD=build

# Compiler flags for building Lua. 
CFLAGS="-Wall -Os"

# Make sure the build directory exists
mkdir -p $BUILD

# Build one big source file from all the 
#  individual ones. We have to substitute stubs for some of the
#  functions that have been compiled out
echo \#include \"lapi.c\" > $ONE
echo \#include \"lauxlib.c\" >> $ONE
echo \#include \"lbaselib.c\">> $ONE
#liblib.c can be excluded unles LUA_COMPAT_BITLIB is defined
#echo \#include \"lbitlib.c\" >> $ONE
echo \#include \"lcode.c\" >> $ONE
if [ -n "$INCLUDE_COROUTINES" ]; then
  echo \#include \"lcorolib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_coroutine(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"lctype.c\" >> $ONE
if [ -n "$INCLUDE_DB" ]; then
  echo \#include \"ldblib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_debug(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"ldebug.c\" >> $ONE
echo \#include \"ldo.c\" >> $ONE
if [ -n "$INCLUDE_DUMP" ]; then
  echo \#include \"ldump.c\" >> $ONE
else
  echo "int luaU_dump(lua_State *L, const Proto *f, lua_Writer w, void *data, int strip) {return -1;}" >> $ONE
fi
echo \#include \"lfunc.c\" >> $ONE
echo \#include \"lgc.c\" >> $ONE
# linit.c defines luaL_openlibs so we need to keep it, but it's small
echo \#include \"linit.c\" >> $ONE
if [ -n "$INCLUDE_IO" ]; then
  echo \#include \"liolib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_io(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"llex.c\" >> $ONE
if [ -n "$INCLUDE_MATH" ]; then
  echo \#include \"lmathlib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_math(lua_State *L){return 1;}" >> $ONE
  echo "LUA_NUMBER floor (LUA_NUMBER d){return 0;}" >> $ONE
  echo "LUA_NUMBER pow (LUA_NUMBER d,LUA_NUMBER e){return 0;}" >> $ONE
  echo "LUA_NUMBER fmod (LUA_NUMBER d, LUA_NUMBER e){return 0;}" >> $ONE
  echo "LUA_NUMBER frexp (LUA_NUMBER d, int *e){return 0;}" >> $ONE
fi
echo \#include \"lmem.c\" >> $ONE
if [ -n "$INCLUDE_PACKAGE" ]; then
  echo \#include \"loadlib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_package(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"lobject.c\" >> $ONE
echo \#include \"lopcodes.c\" >> $ONE
if [ -n "$INCLUDE_OS" ]; then
  echo \#include \"loslib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_os(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"lparser.c\" >> $ONE
echo \#include \"lstate.c\" >> $ONE
echo \#include \"lstring.c\" >> $ONE
if [ -n "$INCLUDE_STRING" ]; then
  echo \#include \"lstrlib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_string(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"ltable.c\" >> $ONE
if [ -n "$INCLUDE_TABLE" ]; then
  echo \#include \"ltablib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_table(lua_State *L){return 1;}" >> $ONE
fi
# ltests.c only contains code if LUA_DEBUG is defined, in which case
#  it should probably be included
echo \#include \"ltests.c\" >> $ONE
echo \#include \"ltm.c\" >> $ONE
if [ -n "$INCLUDE_UNDUMP" ]; then
  echo \#include \"lundump.c\" >> $ONE
else
  echo "LClosure *luaU_undump(lua_State *L, ZIO *Z, const char *name){return 0;}" >> $ONE
fi
if [ -n "$INCLUDE_UTF8" ]; then
  echo \#include \"lutf8lib.c\" >> $ONE
else
  echo "LUAMOD_API int luaopen_utf8(lua_State *L){return 1;}" >> $ONE
fi
echo \#include \"lvm.c\" >> $ONE
echo \#include \"lzio.c\" >> $ONE

# Compile the big source file to lua_one.o
$CC -c $ONE -o $BUILD/lua_one.o

rm -f $BUILD/lua_one.h

# Make lua-one.h from individual header files. We have to remove
#  references to #include's of other Lua bits -- they should all
#  be in the generated file, anyway
cat luaconf.h lua.h lualib.h lauxlib.h | sed 's/#include ".*//' >> $BUILD/lua_one.h 

