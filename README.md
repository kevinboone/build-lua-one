# build-lua-one

Version 0.1

## What is this?

`build-lua-one.sh` is a simple shell script that constructs a two-file
build of Lua, reading to be used in a C/C++ application that embeds
Lua.. These files are `lua-one.o`, which contains the entire
Lua implementation, and `lua-one.h`, which code that uses Lua
should include. You can choose, at build time, which Lua libraries
to include in the build. If only essential features are included, the
compiled size is reduced by about 40%. 

The purpose of this approach to using Lua is to avoid the twin evils of
either

1. Having a system-wide installation of Lua, that is easy to link but can't be customized for a particular project, or
2. Incorporating the whole Lua build system into your project.

I got the idea for building Lua this way from MuJS, which builds a
single object file and header as its main build method. However, I don't
think it's a particularly revolutionary idea, and I can't claim any
particular credit.

## How to use

1. Download and unpack the required source bundle for Lua
2. Copy `build-lua-one.sh` to the Lua source directory
3. Check the script to ensure that the necessary libraries are to be included -- examine the `INCLUDE_XXX` definitions at the top of the file
4. Check that the script references the correct C or C++ compiler, with the desired command-line switches
5. Tweak `luaconf.h` if necessary -- you might want to change Lua's data type sizes, for example
6. Run the script. By default it will create the directory `build'` with the
files `lua-one.o` and `lua-one.h` in
7. Copy these files to your application's build tree

You should be able to build just by doing something like:

    $ gcc -o my_app lua-one.o my_object1.o... [-lm]

although, of course, you'd do this using a Makefile or similar in
practice. Those parts of your application that use Lua will have

    # include "lua-one.h"

There is no need to try to include specific Lua headers, as they won't
exist, and all the parts of Lua that are meaningful to an application 
are (should be) in `lua-one.h`.

## Things to watch for

An application should initialize Lua like this:

    lua_State *L = luaL_newstate();
    luaL_openlibs (L);

There's no point trying to load specific libraries -- if they've been
compiled in, `openlibs` will initialize them, If they haven't, trying
to initialize them will fail. The whole point of this script is to
build a Lua with only the necessary modules compiled in.

If you don't define

    INCLUDE_MATH=1

then none of the Lua math library will be built, and some parts of
Lua that have floating-point operations deeply embedded will be
stubbed out. If you don't need to use `math.sin()` etc, then leaving
out the math library avoids the need to link with `-lm` and improves
start-up time a little. However, Lua uses floating-point math calls
for things other than the math library, like converting numbers from
one format to another. If you plan to use floating-point numbers at
all in your application, excluding the math library should be done
with care.

If your main application will be using C++, and you're compiling
using `g++`, then use `g++` in `build-lua-one.sh` as well. This
will save an awful lot of awkwardness later.


