#!/bin/bash
#
#   Copyright information
#
#       Copyright (C) 2016 Julius Salonen <julius.salonen@cs.tamk.fi>
#
#   License
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License as
#       published by the Free Software Foundation; either version 3 of
#       the License, or (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful, but
#       WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#       General Public License for more details.
#
#       You should have received a copy of the GNU Lesser General Public
#       License along with this program. If not, see
#       <http://www.gnu.org/licenses/>.
#
#   This is the main file of program.sh. Follow instructions in INSTALL
#   to install properly, or man pages for more information.

TMPDIR=${TMPDIR:-/tmp}
PID=$$
BASENAME="$TMPDIR/$PID"

Verbose ()
{
    if [ "$VERBOSE" ]; then
        echo "$*" # "$@" or "@*"
    fi
}

Help ()
{

    echo "Backup Reporting Utility program.sh Copyright (C) 2016 Julius Salonen"
    echo "OPTIONS: --help, --verbose, --tmpdir DIR"
    echo "Example of use: program.sh --tmpdir ~/tmp ./bakfolder"

    exit
}

Filesize ()
{
    local line size

    while read line
    do
        set -- $line
        size=$5

        case "$line" in
            *\~)
                size_tilde=$((size_tilde + size))
                ;;
            *\#)
                size_hash=$((size_hash + size))
                ;;
            *.bak)
                size_bak=$((size_bak + size))
                ;;
            *.bup)
                size_bup=$((size_bup + size))
                ;;
            *.rej)
                size_rej=$((size_rej + size))
                ;;
        esac
    done < "$BASENAME.files-list.lst"

}

Search ()

{

    find "$1" -name "$2"

}

Main ()
{

    local directory
    local tmpdir

    # Parse arguments:

    if [ ! $1 ]; then
        echo "ERR: No arguments given. Use --help for options." >&2
        exit 1
    fi

    for arg in "$@"
    do
        case "$arg" in
            -h | --help)
                Help
                shift
                ;;
            --verbose)
                VERBOSE="VERBOSE"
                shift
                ;;
            --tmpdir)
                if [ "$2" ]; then
                    tmpdir="$2"
                    shift
                fi

                if [ ! -d "$tmpdir" ]; then
                    echo "ERR: Invalid directory for --tmpdir!" >&2
                    exit 1
                fi

                TMPDIR="$tmpdir"
                BASENAME="$TMPDIR/$PID"

                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                shift
                ;;
            *)
                if [ -d "$1" ]; then
                    directory="$1"
                fi

                shift
                ;;
        esac
    done

    if [ ! -d "$directory" ]; then
        echo "ERR: Directory not a directory or not specified." >&2
        exit 1
    fi

    if [ ! -w "$TMPDIR" ]; then
        echo "ERR: $TMPDIR not writable to! Try using --tmpdir?" >&2
        exit 1
    fi

    Verbose "Arguments successfully parsed. Verbose mode active."
    Verbose "TMPDIR is $TMPDIR and working folder is $directory"

    ls --block-size 1 -l -R "$directory" > "$BASENAME.files-list.lst"

    size_tilde=0
    size_hash=0
    size_bak=0
    size_bup=0
    size_rej=0

    Verbose "Running filesize checker for summary report."

    Filesize "$BASENAME.files-list.lst"

    Verbose "Totaling file size."

    size_total=$(($size_tilde+$size_hash+$size_bak+$size_bup+$size_rej))

    Verbose "Searching and sorting the files for files-sorted.lst"

    Search "$directory" "*~"     >  "$BASENAME.files-sorted.lst"
    Search "$directory" "*#"     >> "$BASENAME.files-sorted.lst"
    Search "$directory" "*.bak"  >> "$BASENAME.files-sorted.lst"
    Search "$directory" "*.bup"  >> "$BASENAME.files-sorted.lst"
    Search "$directory" "*.rej"  >> "$BASENAME.files-sorted.lst"

    Verbose "Generating file summary report:"

    cat > "$BASENAME.files-summary.lst" <<EOF

    type    total count
    ----    -----------
    *~      $size_tilde bytes
    *#      $size_hash bytes
    *.bak   $size_bak bytes
    *.bup   $size_bup bytes
    *.rej   $size_rej bytes
            -----------
            $size_total bytes

EOF
    
    cat "$BASENAME.files-summary.lst"
    exit
}

Main "$@"

#EOF
