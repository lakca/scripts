#!/usr/bin/env bash

fast_chr() {
    local __octal
    local __char
    printf -v __octal '%03o' $1
    printf -v __char \\$__octal
    REPLY=$__char
}

function unichr {
    local c=$1    # Ordinal of char
    local l=0    # Byte ctr
    local o=63    # Ceiling
    local p=128    # Accum. bits
    local s=''    # Output string

    (( c < 0x80 )) && { fast_chr "$c"; echo -n "$REPLY"; return; }

    while (( c > o )); do
        fast_chr $(( t = 0x80 | c & 0x3f ))
        s="$REPLY$s"
        (( c >>= 6, l++, p += o+1, o>>=1 ))
    done

    fast_chr $(( t = p | c ))
    printf "%s\n" $REPLY$s 1>&2
    echo -n "$REPLY$s"
}

function UnicodePointToUtf8() {
    local x="$1"               # ok if '0x2620'
    x=${x/\\u/0x}              # '\u2620' -> '0x2620'
    x=${x/U+/0x}; x=${x/u+/0x} # 'U-2620' -> '0x2620'
    x=$((x)) # from hex to decimal
    local y=$x n=0
    [ $x -ge 0 ] || return 1
    while [ $y -gt 0 ]; do y=$((y>>1)); n=$((n+1)); done
    if [ $n -le 7 ]; then       # 7
        y=$x
    elif [ $n -le 11 ]; then    # 5+6
        y=" $(( ((x>> 6)&0x1F)+0xC0 )) \
            $(( (x&0x3F)+0x80 ))"
    elif [ $n -le 16 ]; then    # 4+6+6
        y=" $(( ((x>>12)&0x0F)+0xE0 )) \
            $(( ((x>> 6)&0x3F)+0x80 )) \
            $(( (x&0x3F)+0x80 ))"
    else                        # 3+6+6+6
        y=" $(( ((x>>18)&0x07)+0xF0 )) \
            $(( ((x>>12)&0x3F)+0x80 )) \
            $(( ((x>> 6)&0x3F)+0x80 )) \
            $(( (x&0x3F)+0x80 ))"
    fi
    printf -v y '\\x%x' $y
    echo $y
}
