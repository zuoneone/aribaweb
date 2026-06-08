
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <ctype.h>
#include "utils.h"
#include "porting.h"

const char *programPath;
const char *programDir;
const char *programName;

void error(const char *format, ...)
{
    // Format an error message, print it to stderr, and die.

    va_list ap;
    va_start(ap, format);
    char message[200];
    vsnprintf(message, sizeof(message), format, ap);
    va_end(ap);

    fprintf(stderr, "%s: %s\n", programName, message);
    exit(1);
}

void *xmalloc(int size)
{
    // Allocate memory like malloc but error out if the allocation failed.

    void *result = malloc(size);
    if (result == NULL)
        error("memory exhausted");
    return result;
}

void *xrealloc(void *ptr, int size)
{
    // Allocate memory like realloc but error out if the allocation failed.

    void *result = realloc(ptr, size);
    if (result == NULL)
        error("memory exhausted");
    return result;
}

char *xstrdup(const char *string)
{
    // Allocate memory like strdup but error out if the allocation failed.

    char *result = strdup(string);
    if (result == NULL)
        error("memory exhausted");
    return result;
}

void setenv(const char *name, const char *value)
{
    // Cons together name and value into name=value and putenv the result.

    int length = strlen(name) + 1 + strlen(value) + 1;
    char *pair = (char *) xmalloc(length);
    sprintf(pair, "%s=%s", name, value);
    putenv(pair);
}

bool isDirectory(const char *path)
{
    // Returns true if <path> exists and is a directory.

    struct stat info;
    if (stat(path, &info) != 0)
        return false;
    return (info.st_mode & S_IFMT) == S_IFDIR;
}

bool isFile(const char *path)
{
    // Returns true if <path> exists and is a regular file.

    struct stat info;
    if (stat(path, &info) != 0)
        return false;
    return (info.st_mode & S_IFMT) == S_IFREG;
}

char *makePath(const char *format, const char *arg1, const char *arg2)
{
    // Create a path in printf-like fashion and allocate storage for it and
    // return it.  On Win32 the path is converted to use \'s instead of /'s.

    char path[PATH_MAX + 1];
    snprintf(path, sizeof(path), format, arg1, arg2);
    path[PATH_MAX] = 0;

#ifdef _WIN32
    sedString(path, '/', '\\');
#endif

    return xstrdup(path);
}

bool getBoolEnv(const char *name, const char *dfault)
{
    // Returns the true/false value of environment variable named <name>,
    // substituting the value <dfault> if the variable is not set.

    const char *value = getenv(name);
    if (value == NULL)
        value = dfault;
    return strcmp(value, "true") == 0;
}

bool isDirectoryInPath(const char *dir, const char *path)
{
    // Returns true if <dir> is already contained in the PATH.  Note that
    // we do a direct strcmp comparison, no aliasing is accounted for.
    // If <dir> is in the PATH but with, say, a trailing /, or uses a
    // different casing, then this won't detect that.  But what we're 
    // really doing here is preventing OURSELF from adding the same dir
    // more than once, and since we always generate the dirs to add to
    // the PATH in the same way, with the same casing, we accomplish that.

    int dirlen = strlen(dir);

    while (true) {
        const char *end = strchr(path, *PATH_SEP);
        if (end == NULL)
            end = path + strlen(path);
        if (end - path == dirlen && strncmp(dir, path, dirlen) == 0)
            return true;
        if (*end == 0)
            return false;
        path = end + 1;
    }
}

void prependToPathMaybe(const char *dir)
{
    // Prepends <dir> to PATH if that directory is not already part of PATH.

    const char *path = getenv("PATH");

    if (path == NULL) {
        setenv("PATH", dir);
    }
    else if (isDirectoryInPath(dir, path)) {
        // wrapper called from within wrapper?
    }
    else {
        int length = strlen(path) + 1 + strlen(dir) + 1;
        char *newPath = (char *) xmalloc(length);
        sprintf(newPath, "%s%s%s", dir, PATH_SEP, path);
        setenv("PATH", newPath);
    }
}

const char *getPlatformDir()
{
    // Return the platform specific bits directory for the host platform.

#ifdef _WIN32
    return "x86";   // wip fixme should be Win32

#elif defined(sun)
    return "SunOS";

#elif defined(_AIX)
    return "AIX";

#elif defined(__hpux)
    return "HP-UX";

#else
    error("unknown platform (runtime error)");
#endif
}

void setProgramPaths(const char *argv0)
{
    // Return the simple name that this program was invoked by, excluding
    // leading path and executable suffix (e.g. .exe) if any.

#ifdef _WIN32
    // On Win32, argv[0] as passed to main is not an absolute path if the
    // exectuable was located via PATH lookup.  GetModuleFileName is the
    // only way I know of to get this information reliably.

    char pathBuffer[PATH_MAX + 1];
    GetModuleFileName(NULL, pathBuffer, sizeof(pathBuffer));
    argv0 = pathBuffer;
#endif

    programPath = xstrdup(argv0);
    programDir = xstrdup(argv0);
    programName = popPath((char *)programDir);

    if (programName == NULL) {
	programName = programDir;
	programDir = ".";
    }

#ifdef _WIN32
    char *extension = strrchr(programName, '.');

    if (extension != NULL)
        *extension = 0;
#endif

    // fprintf(stderr, "rpdebug: programPath is [%s]\n", programPath);
    // fprintf(stderr, "rpdebug: programDir  is [%s]\n", programDir);
    // fprintf(stderr, "rpdebug: programName is [%s]\n", programName);
}

bool isEmptyString(const char *string)
{
    // Returns true if <string> is NULL or contains only whitespace chars.

    if (string == NULL)
        return true;

    while (*string != 0) {
        if (!isspace(*string))
            return false;
        string++;
    }

    return true;
}

void sedString(char *string, char from, char to)
{
    // Changes each occurrence of <from> in <string> to <to>.

    for (char *s = string; *s != 0; s++)
        if (*s == from)
            *s = to;
}

char *popPath(char *path)
{
    // Modifies <path> to take off last component, returning pointer to
    // component just removed (or NULL if there wasn't one found).

    char *last = (char *) basename(path);

    if (last == path)
        return NULL;

    last[-1] = 0;
    return last;
}

const char *basename(const char *path)
{
    // Returns a pointer into <path> to the last component in the path, or
    // <path> if there is no / or \ in <path>.

    const char *slash = strrchr(path, '/');

#ifdef _WIN32
    if (slash == NULL)
        slash = strrchr(path, '\\');
#endif

    if (slash == NULL)
        return path;
    else
        return slash + 1;
}

void expandVariables(char *buffer, int length, int size)
{
    // Expands environment variables of the form ${variable} in <buffer>.
    // Substitutes "undefined" if the varible isn't currently set.

    for (char *walker = buffer; true; ) {
        char *start = strstr(walker, "${");
        if (start == NULL) break;
        char *brace = strchr(start, '}');
        if (brace == NULL) break;
        char *past = brace + 1;

        *brace = 0;
        const char *value = getenv(start + 2);
        if (value == NULL) value = "undefined";
        int valuelen = strlen(value);

        int remainderlen = buffer + length - past;
        memmove(start + valuelen, past, remainderlen);
        memcpy(start, value, valuelen);
        start[valuelen + remainderlen] = 0;
        length += start + valuelen - past;
        walker = start + valuelen;
    }
}
