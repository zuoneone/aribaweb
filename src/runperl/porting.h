#ifndef _PORTING_H
#define _PORTING_H

#ifdef _WIN32
    // Thes first two have to come before _POSIX_ is defined otherwise they
    // don't export some of their external function definitions. Defining POSIX
    // causes PATH_MAX and unix-like compatibility stuff to be defined.

#   include <direct.h>
#   include <process.h>
#   define _POSIX_ 1
#   include <limits.h>
#   define WIN32_LEAN_AND_MEAN
#   include <windows.h>
#   define snprintf _snprintf
#   define vsnprintf _vsnprintf
#   define BIN_SUFFIX ".exe"
#   define PATH_SEP ";"
#   define SITE_PERL "site/lib"
#else
#   include <limits.h>
#   include <unistd.h>
#   define BIN_SUFFIX ""
#   define PATH_SEP ":"
#   define SITE_PERL "lib/site_perl"
#endif

#endif
