#! /module/for/moderni/sh
# Get a user's login shell using one of several methods, depending on what
# the system supports.
# Usage:
#	loginshell [ <username> ]
# <username> defaults to the current user.
# On success, prints the specified user's login shell to standard output.
# On error, exits with status 2. A system-specific utility may print its own error message.
# If this system has no known way to get the login shell, exits with status 3.

# ...GNU, *BSD, Solaris
unset -f getent finger perl 2>|/dev/null	# zsh defines a broken getent function by default
if command -v getent; then
	# Globbing applies to the result of an unquoted command substitution,
	# and passwd fields often contain a '*', so turn off globbing.
	loginshell() (
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		set -f
		IFS=:
		set -- "${1-$USER}" $(getent passwd "${1-$USER}")
		eq "$#" 8 || return 2
		if same "$2" "$1" && canexec "$8"; then
			print "$8"
		else
			return 2
		fi
	)
# ...Mac OS X
elif canexec /usr/bin/dscl && isdir /System/Library/DirectoryServices; then
	loginshell() (
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		set -f
		IFS="$WHITESPACE"
		set -- $(/usr/bin/dscl . -read "/Users/${1-$USER}" UserShell) || return 2
		eq "$#" 2 || return 2
		if same "$1" 'UserShell:' && canexec "$2"; then
			print "$2"
		else
			return 2
		fi
	)
# ...finger
elif command -v finger; then
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		set -- "$( export LC_ALL=C
			{ finger -m "${1-$USER}" || die "loginshell: 'finger' failed" || return; } \
			| awk 'BEGIN { verified = false; }
			{
				if ( $1 == "Login:" && $2 == "${1-$USER}" )
					verified = true;
				if ( $3 == "Shell:" && verified == true ) {
					print $4;
					exit;
				}
			}' || die "loginshell: 'awk' failed" || return)"
		if not empty "$1" && canexec "$1"; then
			print "$1"
		else
			return 2
		fi
	}
# ...Perl
elif command -v perl; then
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
                set -- "$(perl -e "print +(getpwnam \"${1-$USER}\")[8], \"\\n\"")"
		if not empty "$1" && canexec "$1"; then
			print "$1"
		else
			return 2
		fi
	}
# ...we don't have a way
else
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		return 3
	}
fi >|/dev/null 2>&1