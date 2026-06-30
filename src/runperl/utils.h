
#ifndef _UTILS_H
#define _UTILS_H

extern const char *programPath;
extern const char *programDir;
extern const char *programName;

void error(const char *format, ...);
    // Format an error message and die.

void *xmalloc(int size);
    // Like malloc but calls error() the allocation failed.

void *xrealloc(void *ptr, int size);
    // Like realloc but calls error() the allocation failed.

char *xstrdup(const char *string);
    // Like strdup but calls error() the allocation failed.

void setenv(const char *name, const char *value);
    // Calls putenv("<name>=<value>").

bool getBoolEnv(const char *name, const char *dfault);
    // Fetches envvar <name> and returns true if it is strcmp("true").

bool isDirectory(const char *path);
    // Returns true if <path> exists and is a directory.

bool isFile(const char *path);
    // Returns true if <path> exists and is a regular file.

char *makePath(const char *format, const char *arg1, const char *arg2 = 0);
    // Cons'es together a path in printf-like fashion.

bool isDirectoryInPath(const char *dir, const char *path);
    // Returns true if <dir> is already contained in <path>.

void prependToPathMaybe(const char *dir);
    // Prepends <dir> to the PATH if it is not already in the PATH.

const char *getPlatformDir();
    // Returns SunOS, HP-UX, AIX, or Win32.

void setProgramPaths(const char *argv0);
    // Extracts the name of the program invoked from argv[0] and stores it.

bool isEmptyString(const char *string);
    // Returns true if <string> is NULL or contains only whitespace.

void sedString(char *string, char from, char to);
    // Changes each occurrence of <from> in <string> to <to>.

char *popPath(char *path);
    // Modifieds <path> to take off last component, returning pointer to
    // component just removed (or NULL if there wasn't one found).

const char *basename(const char *path);
    // Returns a pointer into <path> to the last component in the path, or
    // <path> if there is no / or \ in <path>.

void expandVariables(char *buffer, int length, int size);
    // Expands environment variables of the form ${variable} in <buffer>.
    // Substitutes "undefined" if the varible isn't currently set.

#endif
