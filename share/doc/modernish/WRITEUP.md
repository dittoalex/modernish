# modernish: a shell modernizer library #

modernish is an ambitious, as-yet experimental, cross-platform POSIX shell
feature detection and language extension library. It aims to extend the
shell language with extensive feature testing and language enhancements,
using the power of aliases and functions to extend the shell language
itself.

On the one hand, programs using the library should run on any
POSIX-compliant shell. On the other hand, modernish does not shy away from
taking advantage of shell-specific features where available and
advantageous.

The name is a pun on Modernizr, the JavaScript feature testing library,
-sh, the common suffix for UNIX shell names, and -ish, still not quite
a modern programming language but perhaps a little closer.

The library builds on pure POSIX 2013 Edition (including full C-style
shell arithmetics with assignment, comparison and conditional
expressions), but uses non-standard extensions where available and
advantageous for performance reasons.

Most of the functionality is based on an internal namespace `_Msh_*` for
variables and functions, which should be considered sacrosanct and
untouchable by programs using the library. Of course this is not
enforceable, but names starting with `_Msh_` should be uncommon enough
that no unintentional conflict is likely to occur.

It's suitable for use in shell scripts (either `#!/usr/bin/env
modernish` or `. modernish`) and interactive shells (`. modernish` in
shell profile or from the command line).

Some simple example programs are in `share/doc/modernish/testsuite`.


## Shell feature testing ##

The initialization routine includes a battery of shell bug, quirk and
feature tests, each of which is given an ID which is stored in `MSH_CAP`
(capabilities) if found. These are easy to query using the `thisshellhas`
function, e.g. `if thisshellhas LOCAL, then` ... That same function also
tests if 'thisshellhas' a particular reserved word or builtin command.

Feature testing is used by library functions to conveniently work around bugs or
take advantage of special features not all shells have. For instance,
`ematch` will use `[[` *var* `=~` *regex* `]]` if available and fall back to
`grep -E` otherwise. But the use of feature testing is not restricted to
modernish itself; any script using the library can do this in the same way.

The `thisshellhas` function is an essential component of feature testing in
modernish. There is no standard way of testing for the presence of a shell
built-in or reserved word, so different shells need different methods; the
library tests for this and loads the correct version of this function.

See Appendix A below for a list of capabilities and bugs currently tested for.


## Control character constants ##

POSIX does not provide for C-style escapes (such as `$'\n'` to represent a
newline character), leaving the shell without a convenient way to refer to control
characters. Modernish provides control character constants (read-only
variables) `$CC01` .. `$CC1F` as well as `$CCe`, `$CCa`, `$CCb`, `$CCf`,
`$CCn`, `$CCr`, `$CCt`, `$CCv` (corresponding with printf backslash codes).
This makes it easy to insert control characters in double-quoted strings.

More convenience constants:

* `$CONTROLCHARS`: All the control characters.
* `$WHITESPACE`: All whitespace characters.
* `$ASCIIALNUM`: All the ASCII alphanumeric characters.
* `$SHELLSAFECHARS`: Safelist for shell-quoting.


## Legible result testing ##

Two aliases that seem to make the shell language look slightly friendlier:

    alias not='! '                  # more legible synonym for '!'
    alias so='[ "$?" -eq 0 ]'       # test preceding command's success with
                                    # 'if so;' or 'if not so;'


## Enhanced exit and emergency halt ##

`die`: reliably halt program execution, even from subshells, optionally
printing an error message.

`exit`: extended usage: `exit` [ `-u` ] [ *<status>* [ *<message>* ] ]
If the -u option is given, the function showusage() is called, which has
a simple default but can be redefined by the script.


## Feature testing ##

`thisshellhas`: test if a keyword is a shell built-in function or reserved
word, or modernish capability/bug ID. 


## Working with variables ##

`isvarname`: Test if argument is valid portable variable (or shell
function) name.

`isset`: check if a variable is set.

`unexport`: the opposite of `export`. Unexport a variable while preserving
its value, or (while working under `set -a`) don't export it at all.


## Quoting strings for subsequent parsing by the shell ##

`shellquote`: fast and reliable shell-quoting function that uses an
optimized algorithm. This is essential for the safe use of `eval` or
any other contexts where the shell must parse untrusted input.

`shellquoteparams`: shell-quote the current shell's positional parameters
in-place.

`storeparams`: store the positional parameters, or a sub-range of them,
in a variable, in a shellquoted form suitable for restoration using
`eval "set -- $varname"`. For instance: `storeparams -f2 -t6 VAR`
quotes and stores `$2` to `$6` in `VAR`.


## Variable, shell option and trap stacks ##

`push` & `pop`: every variable and shell option gets its own stack. For
variables, both the value and the set/unset state is (re)stored. Other
stack functions: `stackempty` (test if a stack is empty); `stacksize`
(output number of items on a stack); `printstack` (output the stack's
content); `clearstack` (clear a stack).

`pushtrap` and `poptrap`: traps are now also stack-based, so that each
program component or library module can set its own trap commands
without interfering with others.

`pushparams` and `popparams`: push and pop the complete set of positional
parameters.


## Hardening: emergency halt on error ##

`harden`: modernish's replacement for `set -e` (which is not supported and
will break the library). `harden` installs a function that hardens a
particular command by testing its exit status against values indicating
error or system failure.  Upon failure, the function installed by
`harden` calls `die`, so it will reliably halt program execution, even
if the failure occurred within a subshell (for instance, in a pipe
construct or command substitution).

Examples:

    harden grep 'gt 1'          # grep fails on exit status > 1
    harden gzip 'eq 1 || ge 3'  # 1 and >2 are errors, but 2 isn't
    harden as tar /usr/local/bin/gnutar
				# be sure to use one 'tar' version


## Outputting strings ##

`print`: prints each argument on a separate line (unlike `echo` which
prints all arguments on one line). There is no processing of options or
escape codes. Note: this is completely different from ksh/zsh `print`.
(On shells with printf built in, `print` is simply an alias for `printf
'%s\n'`.)

`echo`: a modernish version of `echo`, so at least all modernish programs
can safely expect the same behaviour. This version does not interpret
any control characters and supports only one option, `-n`, which, like
BSD `echo`, suppresses the newline. However, unlike BSD `echo`, if `-n`
is the only argument, it is not interpreted as an option and the string
`-n` is printed instead. This makes it safe to output arbitrary data
using this version of `echo` as long as it is given as a single argument
(using quoting if needed).


## Enhanced dot scripts ##

`source`: bash/zsh-style `source` command now available to all POSIX
shells, complete with optional positional parameters given as extra
arguments (which is not supported by POSIX `.`).


## Simple shell arithmetic commands ##

`let`: implementation of `let` as in ksh, bash and zsh, now available to
all POSIX shells.

`inc`, `dec`, `mult`, `div`, `mod`: simple integer arithmetic shortcuts. The first
argument is a variable name. The optional second argument is an
arithmetic expression, but a sane default value is assumed (1 for inc
and dec, 2 for mult and div, 256 for mod). For instance, `inc X` is
equivalent to `X=$((X+1))` and `mult X Y-2` is equivalent to `X=$((X*(Y-2)))`.


## Testing numbers, strings and files ##

Complete replacement for `test`/`[` in the form of speed-optimized shell
functions, so modernish scripts never need to use that `[` botch again.
Instead of inherently ambiguous `[` syntax (or the nearly-as-confusing
`[[` one), these familiar shell syntax to get more functionality, including:

### Integer number arithmetic tests ###

These have the same name as their `test`/`[` option equivalents. Unlike
with `test`, the arguments are shell integer arith expressions, which can be
anything from simple numbers to complex expressions. As with `$(( ))`,
variable names are expanded to their values even without the `$`.

    Function:         Returns succcessfully if:
    eq <expr> <expr>  the two expressions evaluate to the same number
    ne <expr> <expr>  the two expressions evaluate to different numbers
    lt <expr> <expr>  the 1st expr evaluates to a smaller number than the 2nd
    le <expr> <expr>  the 1st expr eval's to smaller than or equal to the 2nd
    gt <expr> <expr>  the 1st expr evaluates to a greater number than the 2nd
    ge <expr> <expr>  the 1st expr eval's to greater than or equal to the 2nd

    isint <string>    test if a given argument is an integer number,
                      ignoring leading and trailing spaces and tabs.

### String tests ###
    empty:        test if string is empty
    identic:      test if 2 strings are identical
    sortsbefore:  test if string 1 sorts before string 2
    sortsafter:   test if string 1 sorts after string 2
    contains:     test if string 1 contains string 2
    startswith:   test if string 1 starts with string 2
    endswith:     test if string 1 ends with string 2
    match:        test if string matches a glob pattern
    ematch:       test if string matches an extended regex

### File tests ###
    exists:       test if file exists
    exists -L:    test if file exists and is not an invalid symlink
    isnonempty:   test is file exists, is not an invalid symlink, and is
                  not empty (also works for dirs with read permission)
    canread:      test if we have read permission for a file
    canwrite:     test if we have write permission for a file
    canexec:      test if we have execute permission for a file
    issetuid:     test if file has user ID bit set
    issetgid:     test if file has group ID bit set
    issym:        test if file is symlink
    isreg:        test if file is a regular file
    isreg -L:     test if file is regular or a symlink pointing to a regular
    isdir:        test if file is a directory
    isdir -L:     test if file is dir or symlink pointing to dir
    isfifo, isfifo -L, issocket, issocket -L, isblockspecial,
                  isblockspecial -L, ischarspecial, ischarspecial -L:
                  same pattern, you figure it out :)
    isonterminal: test if file descriptor is associated with a terminal


## Modules ##

`use`: use a modernish module. It implements a simple Perl-like module
system with names such as 'safe', 'var/setlocal' and 'loop/select'.
These correspond to files 'safe.mm', 'var/setlocal.mm', etc. which are
dot scripts defining functionality. Any extra arguments to the `use`
command are passed on to the dot script unmodified, so modules can
implement option parsing to influence their initialization.

### use safe ###
Does `IFS=''; set -f -u -C`, that is: field splitting and globbing are
disabled, variables must be defined before use, and 

Essentially, this is a whole new way of shell programming,
eliminating most variable quoting headaches, protects against typos
in variable names wreaking havoc, and protects files from being
accidentally overwritten by output redirection.

Of course, you don't get field splitting and globbing. But modernish
provides various ways of enabling one or both only for the commands
that need them, `setlocal`...`endlocal` blocks chief among them
(see `use var/setlocal` below).

On interactive shells (or if `use safe -i` is given), also loads
convenience functions `fsplit` and `glob` to control and inspect the
state of field splitting and globbing in a more user friendly way.

*It is highly recommended that new modernish scripts start out with `use safe`.*
But this mode is not enabled by default because it will totally break
compatibility with shell code written for default shell settings.

### use var/array ###
Associative arrays using the `array` function. (Not finished yet.)

### use var/setlocal ###
Defines a new `setlocal`...`endlocal` shell code block construct with
arbitrary local variables, local field splitting and globbing settings,
and arbitrary local shell options. Internally, these blocks are shell
functions that are executed immediately upon defining them, then discarded.

zsh programmers may recognise this as pretty much the equivalent of
anonymous functions. In fact, on zsh, `setlocal` blocks take advantage of
that functionality.

### use var/string ###
String manipulation functions.

`trim`: strip whitespace (or other characters) from the beginning and end of
a variable's value.

`replacein`: Replace first, `-l`ast or `-a`ll occurrences of a string by
# another string in a variable.

`append` and `prepend`: Append or prepend zero or more strings to a
variable, separated by a string of zero or more characters, avoiding the
hairy problem of dangling separators. Optionally shell-quote each string
before appending or prepending.

### use sys/baseutils ###
Some very common external commands ought to be standardised, but aren't. For
instance, the `which` and `readlink` commands have incompatible options on
various Linux and BSD variants and may be absent on other Unix-like systems.
This module provides a complete re-implementation of such basic utilities
written as modernish shell functions. Scripts that use the modernish version
of these utilities can expect to be fully cross-platform.

`readlink`: Read the target of a symbolic link. Robustly handles weird
filenames such as those containing newline characters. Stores result in the
$REPLY variable and optionally writes it on standard output. Optionally
canonicalises each path, following all symlinks encountered (for this mode,
all but the last component must exist). Optionally shell-quote each item of
output for later parsing by the shell, separating multiple items with spaces
instead of newlines.

`which`: Outputs either the first path of each given command, or all
available paths, according to the system $PATH.  Stores result in the $REPLY
variable and optionally writes it on standard output. Optionally shell-quote
each item of output for later parsing by the shell, separating multiple
items with spaces instead of newlines.

### use sys/dirutils ###
Functions for working with directories. So far I have:

`traverse`: Recursively walk through a directory, executing a command for
each file and subdirectory found -- usually a handler function in your
program. This is a fully cross-platform, robust replacement for 'find'. It
has minimal functionality of its own, but since the command name can be a
shell function, any functionality of 'find' and anything else can be
programmed in the shell language. (The `install.sh` script that comes
with modernish provides a good example of its use.)

`countfiles`: Count the files in a directory using nothing but shell
functionality, so without external commands. (It's amazing how many pitfalls
this has, so a library function is needed to do it robustly.)

### use sys/textfiles ###
Functions for working with textfiles. So far I have:

`readf`: read a complete text file into a variable, stripping only the last
linefeed character.

`kitten` and `nettik`: `cat` and `tac` without launching any external process,
so it's faster for small text files.

### use opts/long ###
Adds a `--long` option to the getopts built-in for parsing GNU-style long
options. (Does not currently work in *ash* derivatives because `getopts`
has a function-local state in those shells. The only way out is to
re-implement `getopts` completely in shell code instead of building on
the built-in. This is on the TODO list.)

### use loop/cfor ###
A C-style for loop akin to `for (( ))` in bash/ksh/zsh, but unfortunately
not with the same syntax. For example, to count from 1 to 10:

    cfor 'i=1' 'i<=10' 'i+=1'; do
        echo "$i"
    done

(Note that '++i' and 'i++' can only be used on shells with ARITHPP,
but 'i+=1' or 'i=i+1' can be used on all POSIX-compliant shells.)

### use loop/sfor ###
A C-style for loop with arbitrary shell commands instead of arithmetic
expressions. For example, to count from 1 to 10 with traditional shell
commands:

    sfor 'i=1' '[ "$i" -le 10 ]' 'i=$((i+1))'; do
        print "$i"
    done

or, with modernish commands:

    sfor 'i=1' 'le i 10' 'inc i'; do
        print "$i"
    done

### use loop/with ###

The shell lacks a very simple and basic loop construct, so this module
provides for an old-fashioned MS BASIC-style `for` loop, renamed a `with`
loop because we can't overload the reserved shell keyword `for`. Integer
arithmetic only. Usage:

    with <varname>=<value> to <limit> [ step <increment> ]; do
       # some commands
    done

To count from 1 to 10:

    with i=1 to 10; do
        print "$i"
    done

The value for `step` defaults to 1 if *limit* is equal to or greater
than *value*, and to -1 if *limit* is less than *value*. The latter is
a slight enhancement over the original BASIC `for` construct. So
counting backwards is as simple as `with i=10 to 1; do` (etc).        

### use loop/select ###
A complete and nearly accurate reimplementation of the `select` loop from
ksh, zsh and bash for POSIX shells lacking it. Modernish scripts running
on any POSIX shell can now easily use interactive menus.

(All the new loop constructs have one bug in common: as they start with
an alias that expands to two commands, you can't pipe a command's output
directly into such a loop. You have to enclose it in `{`...`}` as a
workaround. I have not found a way around this limitation that doesn't
involve giving up the familiar `do`...`done` syntax.)

---

## Appendix A ##

This is a list of shell capabilities and bugs that modernish tests for, so
that both modernish itself and scripts can easily query the results of these
tests. The all-caps IDs below are all usable with the `thisshellhas`
function. This makes it easy for a cross-platform modernish script to write
optimizations taking advantage of certain non-standard shell features,
falling back to a standard method on shells without these features. On the
other hand, if universal compatibility is not a concern for your script, it
is just as easy to require certain features and exit with an error message
if they are not present, or to refuse shells with certain known bugs.

### Capabilities ###

Non-standard shell capabilities currently tested for are:

* `LEPIPEMAIN`: execute last element of a pipe in the main shell, so that
  things like *somecommand* `| read` *somevariable* work. (zsh, AT&T ksh,
  bash 4.2+)
* `RANDOM`: the `$RANDOM` pseudorandom generator.
* `LINENO`: the `$LINENO` variable contains the current shell script line
  number.
* `LOCAL`: function-local variables, either using the `local` keyword, or
  by aliasing `local` to `typeset` (mksh, yash).
* `KSH88FUNC`: define ksh88-style shell functions with the 'function' keyword,
  supporting dynamically scoped local variables with the 'typeset' builtin.
  (mksh, bash, zsh, yash, et al)
* `KSH93FUNC`: the same, but with static scoping for local variables. (ksh93 only)
  See Q28 at the [ksh93 FAQ](http://kornshell.com/doc/faq.html) for an explanation
  of the difference.
* `ARITHPP`: support for the `++` and `--` unary operators in shell arithmetic.
* `ARITHCMD`: standalone arithmetic evaluation using a command like
  `((`*expression*`))`.
* `FLOAT`: Floating point shell arithmetic.
* `CESCQUOT`: Quoting with C-style escapes, like `$'\n'` for newline.
* `ADDASSIGN`: Add a string to a variable using additive assignment,
  e.g. *VAR*`+=`*string*
* `PSREPLACE`: Search and replace strings in variables using special parameter
  substitutions with a syntax vaguely resembling sed.
* `ROFUNC`: Set functions to read-only with `readonly -f`. (bash, yash)

### Quirks ###

Shell quirks currently tested for are:

* `QRK_IFSFINAL`: in field splitting, a final non-whitespace IFS delimiter
  character is counted as an empty field (yash, zsh, pdksh). This is a QRK
  (quirk), not a BUG, because POSIX is ambiguous on this.
* `QRK_32BIT`: mksh: the shell only has 32-bit arithmetics. Since every modern
  system these days supports 64-bit long integers even on 32-bit kernels, we
  can now count this as a quirk.

### Bugs ###

Non-fatal shell bugs currently tested for are:

* `BUG_APPENDC`: When `set -C` (`noclobber`) is active, "appending" to a nonexistent
  file with `>>` throws an error rather than creating the file. (zsh)
* `BUG_ARITHTYPE`: In zsh, arithmetic assignments (using `let`, `$(( ))`,
  etc.) on unset variables assign a numerical/arithmetic type to a variable,
  causing subsequent normal variable assignments to be interpreted as
  arithmetic expressions and fail if they are not valid as such.
* `BUG_BRACQUOT`: shell quoting within bracket patterns has no effect (zsh < 5.3;
  ksh93) This bug means the `-` retains it special meaning of 'character
  range', and an initial `!` (and, on some shells, `^`) retains the meaning of
  negation, even in quoted strings within bracket patterns, including quoted
  variables.
* `BUG_CMDSPCIAL`: zsh; mksh < R50e: 'command' does not turn off the 'special
  built-in' characteristics of special built-ins, such as exit shell on error.
* `BUG_CMDVRESV`: 'command -v' does not find reserved words such as "if".
  (pdksh, mksh). This necessitates a workaround version of thisshellhas().
* `BUG_EMPTYBRE` is a `case` pattern matching bug in zsh < 5.0.8: empty
  bracket expressions eat subsequent shell grammar, producing unexpected
  results. This is particularly bad if you want to pass a bracket
  expression using a variable or parameter, and that variable or parameter
  could be empty. This means the grammar parsing depends on the contents
  of the variable!
* `BUG_FLOATLC`: On ksh93, the floating point is locale-dependent, making
  arithmetic grammar parsing locale-dependent too. So it depends on the user's
  locale whether `$((1.25))`, `$((1,25))` or something else is valid shell
  grammar. Locale-dependent output is one thing, but locale-dependent shell
  grammar is a horrible idea, so we're calling this a bug. As a workaround to
  ensure script portability, modernish' initialization routine sets LC_NUMERIC
  to POSIX on shells with this bug.
* `BUG_FNSUBSH`: Function definitions within subshells (including command
  substitutions) are ignored if a function by the same name exists in the
  main shell, so the wrong function is executed. `unset -f` is also silently
  ignored. ksh93 (all current versions as of June 2015) has this bug.
* `BUG_HASHVAR`: On zsh, `$#var` means the length of `$var` - other shells and
  POSIX require braces, as in `${#var}`. This causes interesting bugs when
  combining `$#`, being the number of positional parameters, with other
  strings. For example, in arithmetics: `$(($#-1))`, instead of the number of
  positional parameters minus one, is interpreted as `${#-}` concatenated with
  `1`. So, for zsh compatibility, always use `${#}` instead of `$#` unless it's
  stand-alone or followed by a space.
* `BUG_IFSISSET`: AT&T ksh93 (recent versions): `${IFS+s}` always yields 's'
  even if IFS is unset. This applies to IFS only.
* `BUG_IFSWHSPE`
* `BUG_MULTIBYTE`: We're in a UTF-8 locale but the shell does not have
  multi-byte/variable-length character support. (Non-UTF-8 variable-length
  locales are not yet supported.)
* `BUG_NOCHCLASS`: POSIX-mandated character `[:`classes`:]` within bracket
  `[`expressions`]` are not supported in glob patterns. (pdksh, mksh, and
  family)
* `BUG_NOUNSETRO`: Cannot freeze variables as readonly in an unset state.
  This bug in zsh \< 5.0.8 makes the `readonly` command set them to the
  empty string instead.
* `BUG_PARONEARG`
* `BUG_PSUBBS1`
* `BUG_PSUBBS2`
* `BUG_READTWHSP`: `read` does not trim trailing IFS whitespace if there
  is more than one field. (dash)
* `BUG_READWHSP`: `read` does not trim initial IFS whitespace. (yash)
* `BUG_TESTERR0`: mksh: `test`/`[` exits successfully (exit status 0) if
  an invalid argument is given to an operator. (mksh R52 fixes this)
* `BUG_TESTERR1A`: AT&T ksh: `test`/`[` exits with a non-error 'false' status
  (1) if an invalid argument is given to an operator.
* `BUG_TESTERR1B`: zsh: `test`/`[` exits with status 1 (false) if there are
  too few or too many arguments, instead of a status > 1 as it should do.
* `BUG_TESTILNUM`: On dash (up to 0.5.8), giving an illegal number to `test -t`
  or `[ -t` causes some kind of corruption so the next `test`/`[` invocation
  fails with an "unexpected operator" error even if it's legit.
* `BUG_TESTPAREN`: Incorrect exit status of `test -n`/`-z` with values `(`,
  `)` or `!` in zsh 5.0.6 and 5.0.7. This can make scripts that process
  arbitrary data (e.g. the shellquote function) take the wrong action unless
  workarounds are implemented or modernish equivalents are used instead.
  Also, spurious error message with both `test -n` and `test -z`.
* `BUG_TESTRMPAR`: zsh: in binary operators with `test`/`[`, if the first
  argument starts with `(` and the last with `)', both the first and the
  last argument are completely removed, leaving only the operator, and the
  result of the operation is incorrectly true because the operator is
  incorrectly parsed as a non-empty string. This applies to any operator.
* `BUG_UNSETFAIL`: the `unset` command sets a non-zero (fail) exit status
  if the variable to unset was either not set (some pdksh versions), or
  never set before (AT&T ksh 1993-12-28). This bug can affect the exit
  status of functions and dot scripts if 'unset' is the last command.
* `BUG_UPP` (Unset Positional Parameters): Cannot access `"$@"` or `"$*"` if
  `set -u` (`-o nounset`) is active and there are no positional parameters.

---

`EOF`