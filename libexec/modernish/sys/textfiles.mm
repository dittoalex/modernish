#! /module/for/moderni/sh

# Functions for working with text files.
# TODO: analogous binary.mm functions that allow escaped binary data
# in format suitable for interpretation by 'printf'.
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# readf <varname> [ <file> ... ]: concatenate the text file(s) and/or
# standard input into the variable until EOF is reached. A <file> of '-'
# represents standard input. In the absence of <file> arguments, standard
# input is read.
# Unlike with command substitution, only the last linefeed is stripped.
# Text files with no final linefeed (which is invalid) are treated as if they
# have one final linefeed character which is then stripped.
# Text files are always supposed to end in a linefeed, so simply
#	print "$var" > file
#	(which is the same as: printf '%s\n' "$var" > file)
# will correctly write the file back to disk.
readf() {
	ge "$#" 1 || die "readf: incorrect number of arguments (was $#, must be at least 1)" || return
	case "$1" in
	( '' | [0123456789]* | *[!${ASCIIALNUM}_]* )
		die "readf: invalid variable name: $1" || return ;;
	esac
	eval "$1=''"
	_Msh_readf_C="
		while IFS='' read -r _Msh_readf_L; do
			$1=\"\${$1:+\${$1}\${CCn}}\${_Msh_readf_L}\"
		done
		empty \"\${_Msh_readf_L}\" || $1=\"\${$1:+\${$1}\${CCn}}\${_Msh_readf_L}\"
	"
	if gt "$#" 1; then
		shift
		while gt "$#" 0; do
			if identic "$1" '-'; then
				eval "${_Msh_readf_C}"
			else
				not isdir -L "$1" || die "readf: $1: Is a directory" || return
				eval "${_Msh_readf_C}" < "$1" || die "readf: failed to read file \"$1\"" || return
			fi
			shift
		done
	else
		eval "${_Msh_readf_C}"
	fi
	unset -v _Msh_readf_C _Msh_readf_L
}


# kitten is cat without launching any external process.
# Much slower than cat for big files, but much faster for tiny ones.
# Limitation: Text files only. Incompatible with binary files.
# Use cases:
# -	Allows showing here-documents with less overhead.
# -	Faster reading / conkittenenating / copying of small text files.
# Usage: just like cat. '-' is supported. No options are supported.
kitten() {
	if gt "$#" 0; then
		_Msh_kittenE=0
		for _Msh_kittenA do
			case ${_Msh_kittenA} in
			( - )	kitten ;;
			( * )	if not isreg -L "${_Msh_kittenA}" && not isfifo -L "${_Msh_kittenA}"; then
					print "kitten: ${_Msh_kittenA}: Is a directory or device" 1>&2
					_Msh_kittenE=1
					continue
				fi
				kitten < "${_Msh_kittenA}" ;;
			esac || _Msh_kittenE=1
		done
		eval "unset -v _Msh_kittenA _Msh_kittenE; return ${_Msh_kittenE}"
	fi
	while IFS='' read -r _Msh_kittenL; do
		print "${_Msh_kittenL}"
	done
	# also output any possible last line without final newline
	not empty "${_Msh_kittenL}" && echo -n "${_Msh_kittenL}"
	unset -v _Msh_kittenL
}

# nettik is GNU 'tac' without launching any external process.
# Output each file in reverse order, last line first. See kitten().
# This gets slow for files greater than a couple of kB, but then
# again, 'tac' is not available on non-GNU systems so this can
# still be useful.
nettik() {
	if gt "$#" 0; then
		_Msh_nettikE=0
		for _Msh_nettikA do
			case ${_Msh_nettikA} in
			( - )	nettik ;;
			( * )	if not isreg -L "${_Msh_nettikA}" && not isfifo -L "${_Msh_nettikA}"; then
					print "nettik: ${_Msh_nettikA}: Is a directory or device" 1>&2
					_Msh_nettikE=1
					continue
				fi
				nettik < "${_Msh_nettikA}" ;;
			esac || _Msh_nettikE=1
		done
		eval "unset -v _Msh_nettikA _Msh_nettikE; return ${_Msh_nettikE}"
	fi
	_Msh_nettikF=''
	while IFS='' read -r _Msh_nettikL; do
		_Msh_nettikF=${_Msh_nettikL}${CCn}${_Msh_nettikF}
	done
	# (if there is a last line w/o final newline, prepend it without separating newline;
	# this is the behaviour of GNU 'tac')
	echo -n "${_Msh_nettikL}${_Msh_nettikF}"
	unset -v _Msh_nettikL _Msh_nettikF
}
