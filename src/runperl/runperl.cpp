/*
    This program sets up for running a perl script from an Abacus distribution
    based on the platform runtime.  It supercedes runperl.bat, which was a
    continual source of problems because of string and command-line length
    restrictions imposed by the batch processor.

    Although this program is portable and can be compiled and used on Unix,
    it is intended for use on Win32 only.  The "wrapper" for a perl/java
    entry point must exist in the bin directory of the image, and it would
    be impossible to have variants for different platforms in that directory
    at the same time.  Since on Win32 the executable suffix is .exe there is
    no collision, and since it is unique to that platform it all works.

    The additional arguments that are specific to each wrapper (for example,
    for a perl wrapper, what perl script to invoke, or for a java wrapper,
    what class to invoke) is stored in a file name <wrapper>.aux, which this
    program reads.  The .aux files are produced by the build system in the
    same way it used to produce <wrapper>.bat.  The only other difference now
    is that the build system also copies runperl.exe to <wrapper>.exe as well.

    On Win32, I've elected to link this binary with /ML, meaning that the
    executable will have the C library linked in and have no external DLL
    dependencies (vs /MD which would create a dependency on msvcrt.dll).
    The only downside is that each <wrapper>.exe is 48k versus 16k with /MD.
    Since there are on the order of a 100 wrappers, the overhead for /ML is
    100 * 32k, so only a few mbs extra, not enough to worry about.

    This program is very tiny and short lived, and doesn't attempt to free
    the (limited amount of) memory it allocates.  Mostly this means that
    strings cons'd together (via makePath) float away into space.  To fix
    it requires use of a string and/or path object.  PLEASE don't attempt
    to use STL string objects for this, this code must be small and tight,
    neither of which is an attribute of the STL.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include "utils.h"
#include "array.h"
#include "porting.h"

char version[] = "$Id: //abacus/platform/runtime/source/runperl.cpp#11 $";

static Array loadAuxillaryArgs(const char *path)
{
    // Loads the auxillary args for the wrapper exe identified by <path>,
    // if any.  This file contains additional arguments to be passed to the
    // perl executable, and usually contains the target .pl file and any
    // builtin options (all of these are specified in wrappers.csv).

    Array args;
    FILE *fp = fopen(path, "r");

    if (fp != NULL) {
        char buffer[10000];
        int nRead = fread(buffer, 1, sizeof(buffer) - 1, fp);
        buffer[nRead] = 0;
        fclose(fp);

        // Expand environment variable references in the buffer.
        expandVariables(buffer, nRead, sizeof(buffer));

        char *arg = strtok(buffer, " \t\n\r");
        while (arg != NULL) {
            args.addItem(xstrdup(arg));
            arg = strtok(NULL, " \t\n\r");
        }
    }

    // This only works because the Array object does not have a copy ctor
    // and does not attempt to manage the storage for the array.  This is
    // not something that I'd do for anything but a simple app like this.

    return args;
}

static const char *getHomeDirectory(Array &auxArgs)
{
    // Returns the root ("home") directory of the product installation.

    const char *home;

    if (auxArgs.length() == 0) {
        // If we're running as plain runperl, ABACUS_HOME will probably not
        // be defined.  In this case we use the ABACUS_BUILD_ROOT as the home.
        // This makes certain build time usages of runperl work correctly.

        home = getenv("ABACUS_HOME");

        if (isEmptyString(home))
            home = getenv("ABACUS_BUILD_ROOT");
    }
    else {
        // Otherwise we are running in production mode and called via a
        // wrapper.exe, the home directory is some number of levels up
        // (usually 1 if this was a production wrapper in $image/bin, or
        // 2 if this was a test wrapper in $image/internal/bin). The build
        // system generates the depth of the wrapper within the image as
        // the first token in the .aux file.  We blindly obey that.

        char path[PATH_MAX + 1];
        strncpy(path, programDir, sizeof(path));
        path[PATH_MAX] = 0;

        int nLevelsToPop = atoi(auxArgs.deleteItem(0));

        while (nLevelsToPop-- > 0)
            popPath(path);

        home = xstrdup(path);
    }

    if (isEmptyString(home))
        error("ABACUS_HOME is not set as it ought to be (runtime error)");

    if (!isDirectory(home))
        error("ABACUS_HOME is %s which does not exist (runtime error)", home);

    setenv("ABACUS_HOME", home);

    return home;
}

static void traceWrapperCall(const char *wrapper)
{
    // Records invocation of a wrapper and the current PATH length and value
    // into a file named wrappers.txt in the root of the image.

    const char *path = getenv("PATH");
    FILE *fp = fopen("wrappers.txt", "a+");

    if (path != NULL && fp != NULL) {
        fprintf(fp, "Wrapper %s invoked, PATH is length %d and contains:\n",
            wrapper, strlen(path));

        while (true) {
            const char *end = strchr(path, *PATH_SEP);
            if (end == NULL)
                end = path + strlen(path);
            fprintf(fp, "  %.*s\n", end - path, path);
            if (*end == 0)
                break;
            path = end + 1;
        }

        fclose(fp);
    }
}

static void splitStringIntoArgs(const char *string, Array& array)
{
    // push(@array, Text::ParseWords::shellwords($string))

    while (true) {
        while (isspace(*string))
            string++;

        if (*string == 0)
            break;

        char terminator = ' ';

        if (*string == '"' || *string == '\'')
            terminator = *string++;

        const char *start = string;

        while (*string != 0) {
            if (*string == terminator)
                break;
            if (terminator == ' ' && isspace(*string))
                break;
            string++;
        }

        int length = string - start;
        char *copy = (char *) xmalloc(length + 1);
        memcpy(copy, start, length);
        copy[length] = 0;
        array.addItem(copy);

        if (*string != 0)
            string++;
    }
}

int main(int argc, char **argv)
{
    setProgramPaths(argv[0]);

    // Supportability: print runperl version number given -rpversion

    if (argc > 1 && strcmp(argv[1], "-rpversion") == 0) {
        printf("%s: version %s\n", programName, version);
        exit(0);
    }

    // Set ABACUS_INVOCATION_DIR to the directory from which this program was
    // invoked (i.e. pwd) so the target program can locate files relative to
    // this directory if it needs to.

    char currentDir[PATH_MAX + 1];
    getcwd(currentDir, sizeof(currentDir));
    setenv("ABACUS_INVOCATION_DIR", currentDir);

    // Load up auxillary args to be passed to perl for an individual wrapper.
    // These are specified in a file of the same name as the wrapper but with
    // an extension of .aux instead.

    char *auxPath = makePath("%s/%s.aux", programDir, programName);
    Array auxArgs = loadAuxillaryArgs(auxPath);

    // Figure out where our "home" directory is.  If we were invoked as a
    // wrapper, home is one or two levels up from dirname(argv[0]). Otherwise
    // if we were invoked as runperl home is $ABACUS_BUILD_ROOT.

    const char *abacusHome = getHomeDirectory(auxArgs);

    // Figure out where Perl is for this platform and do some sanity checks.

    const char *perlRoot = getenv("ABACUS_PERL_ROOT");
    const char *platform = getPlatformDir();

    if (isEmptyString(perlRoot))
        perlRoot = makePath("%s/3rdParty/perl5/%s", abacusHome, platform);

    if (!isDirectory(perlRoot))
        error("can't find Perl installation at %s", perlRoot);

    char *perlBinary = makePath("%s/bin/perl" BIN_SUFFIX, perlRoot);

    if (!isFile(perlBinary))
        error("can't find Perl executable at %s", perlBinary);

#ifdef _WIN32
    // We put Perl's bin directory on the end of the PATH because in pre-5.6
    // versions the glob() function calls an external program called perlglob
    // that resides in the perl/bin directory.  This can and should go away
    // once we move to perl-5.6 or later.

    prependToPathMaybe(makePath("%s/bin", perlRoot));
#endif

    // Put the $home/bin and $home/bin/<platform> directories onto the PATH.

    prependToPathMaybe(makePath("%s/bin/%s", abacusHome, platform));
    prependToPathMaybe(makePath("%s/bin", abacusHome));

    // Also put the directory in which this program was located on the PATH.
    // The primary motivation here is so that internal/bin is on the PATH for
    // internal wrappers.  Note that in the case of a production wrapper, or
    // if runperl was called explicitly, <programDir> is <abacusHome/bin>, so
    // prependToPathMaybe will not do anything because that directory was put
    // on the PATH above.

    prependToPathMaybe(programDir);

    // If we were invoked as a wrapper we want to chdir to the $home directory.
    // We also support writing a trace file with all the wrapper invocations.

    if (auxArgs.length() > 0) {
        if (chdir(abacusHome) != 0)
            error("chdir(%s) failed (runtime error)", abacusHome);

        if (getBoolEnv("ABACUS_WRAPPER_TRACE", "false"))
            traceWrapperCall(programName);
    }

    // First determine any non-constant flags to add to the perl command.  We
    // support ABACUS_PERL_FLAGS which is the same as runperl shell script.  We
    // treat this as blank delimited for now.  We also support ABACUS_PERL_DEBUG
    // which if set to the name of this program (ie a wrapper name) will invoke
    // that wrapper with debug (normally this is used to debug the perl script
    // underlying a perl wrapper).

    Array perlFlags;

    const char *flagString = getenv("ABACUS_PERL_FLAGS");
    if (flagString != NULL)
        splitStringIntoArgs(flagString, perlFlags);

    const char *debugTarget = getenv("ABACUS_PERL_DEBUG");
    if (debugTarget != NULL && strcmp(debugTarget, programName) == 0)
        perlFlags.addItem("-d");

    // Now build up the argv to invoke Perl.  We add -I's to Perl's lib and
    // site lib directories, as well as -I's to the $home/lib/perl and
    // $home/internal/lib/perl (we really only need to do the latter if
    // this is an internal build, but it doesn't hurt to have a -I to a
    // nonexistent directory, so we just always specify it).  After the -I's
    // we add the auxillary arguments (one of which will be the perl script
    // to run), followed by an arguments passed to the wrapper itself,
    // followed by the required terminating NULL.

    Array execArgs;
    execArgs.addItem(perlBinary);
    execArgs.addItem("-w");
    execArgs.addItem("-S");  // backward compatibility with old runperl.bat
    execArgs.addItems(perlFlags);
    execArgs.addItem("-I");
    execArgs.addItem(makePath("%s/lib", perlRoot));
    execArgs.addItem("-I");
    execArgs.addItem(makePath("%s/%s", perlRoot, SITE_PERL));
    execArgs.addItem("-I");
    execArgs.addItem(makePath("%s/internal/lib/perl", abacusHome));
    execArgs.addItem("-I");
    execArgs.addItem(makePath("%s/lib/perl", abacusHome));

    for (int i = 0; i < auxArgs.length(); i++)
        execArgs.addItem(auxArgs[i]);

    for (int j = 1; j < argc; j++)
        execArgs.addItem(argv[j]);

    execArgs.addItem(NULL);

    if (getBoolEnv("ABACUS_RUNPERL_DEBUG", "false")) {
        for (int k = 0; k < execArgs.length() - 1; k++)
            fprintf(stderr, "runperl: argv[%d] = [%s]\n", k, execArgs[k]);
    }

#ifdef _WIN32
    // Calling execv does not work right on Win32, the exit status of the
    // exec'd program does not seem to be returned.  The help for spawnv is
    // conspicuously silent about the return value if P_OVERLAY is used.
    // We need the exit status to be correct, so we pay the extra process
    // overhead and use spawn instead.

    // Oh, and another Microstupid thing: spawnv isn't really a "v" function,
    // it doesn't handle args with spaces in them correctly.  So we have to
    // quote any arg with spaces in it.  That's the whole POINT of using "v"
    // functions, you shouldn't have to deal with quoting...GGGGRRRRRRRR.

    for (int k = 1; k < execArgs.length() - 1; k++) {
        const char *arg = execArgs[k];

        if (*arg == 0 || strchr(arg, ' ') != NULL)
            execArgs.setItem(k, makePath("\"%s\"", arg));
    }

    int rc = spawnv(_P_WAIT, perlBinary, (char * const *) execArgs.getItems());
#else
    // Lastly we are ready to overlay this process with perl. If it succeeds,
    // it does not return.  If it does return, something has gone very wrong.

    execv(perlBinary, (char * const *) execArgs.getItems());
    error("exec to perl (%s) failed (rc %d)", perlBinary, errno);
    int rc = errno;
#endif

    return rc;
}
