#!/bin/sed -Enf

# Calculates the date of Easter (more exactly,
# Eastern Orthodox Easter).

# Usage: echo <year> | ./computus.sed
# E.g., echo 2020 | ./computus.sed

# (c) Written by Circiter (mailto:xcirciter@gmail.com)
# Can be found at https://github.com/Circiter/computus-in-sed
# License: MIT.

# Bug: too slow (due to use of the unary notation).
# TODO: maybe implement binary arithmetics (to speed up).

# Reference: Jean Meeus, Astronomical Algorithms, 1991.
# Pseudocode:
# a=Year%4
# b=Year%7
# c=Year%19
# d=(19*c+15)%30
# e=(2*a+4*b-d+34)%7
# Month=floor((d+e+114)/31)
# Day=((d+e+114)%31)+14
# MonthSpell=Month==3?"March":"April"

# Convert decimal to unary.
:decrement
    :digit s/0(_*)$/_\1/; tdigit
    s/^/9876543210,/
    :decrement_digit
        s/(.)(.)(,.*)\1(_*)$/\1\3\2\4/
        tdigit_processed
        s/.,/,/
        :digit_processed
        /..,/ bdecrement_digit
    s/^.*,//
    s/_/9/g
    s/^0(.)/\1/
    x; s/^1*$/&1/; x
    /^0$/! bdecrement

s/^.*$//

# [Reverse] polish notation script (all source numbers are in base 2).
s/$/ get_year 100 mod set_a/
s/$/ get_year 111 mod set_b/
s/$/ get_year 10011 mod set_c/
s/$/ 10011 get_c mul 1111 plus 11110 mod set_d/
s/$/ 10 get_a mul 100 get_b mul plus 100010 plus get_d minus 111 mod set_e/

# 1101 is the correction for [1900; 2099] years.
s/$/ get_d get_e plus 1110010 plus 1101 plus set_t/

s/$/ get_t 11111 div/ # Month.
s/$/ get_t 11111 mod 1 plus/ # Day.

s/$/ \$\n@year=/
G; s/\n//g; s/$/;/

# Simple stack-based postfix calculator.
:next_token
    :skip_white s/^ //; tskip_white

    /^set/ {
        # Pop and assign.
        s/^set_([^ ]*) (.*\$.*)\n([^\n]*)(@.*)\1=[^;]*;/set_\1 \2\4\1=\3;/; tassigned
        s/^set_([^ ]*) (.*\$.*)\n([^\n]*)(@.*)$/set_\1 \2\4\1=\3;/ # Define new variable.
        :assigned
    }

    /^get/ {
        s/^get_([^ ]*) (.*\$.*)(@.*)\1=([^;]*);/get_\1 \2\n\4\3\1=\4;/ # Push.
    }

    /^plus/ {
        :plus_iterations
            s/\n(1*)(\n11*@)/\n1\1\2/ # Increment.
            s/\n1(1*@)/\n\1/ # Decrement.
            /1@/ bplus_iterations
        s/\n@/@/
    }

    /^minus/ {
        :minus_iterations
            s/\n1(1*)(\n11*@)/\n\1\2/ # Decrement.
            s/\n1(1*@)/\n\1/ # Decrement.
            /1@/ bminus_iterations
        s/\n@/@/
    }

    # a=pop, b=pop, c=0; while(a) {c+=b; a--}
    /^mul/ {
        s/@/\n@/ # Push zero.
        :mul_iterations
            s/\n(1*)\n(1*)@/\n\1\n\2\1@/ # c+=b.
            s/\n1(1*\n1*\n1*@)/\n\1/ # a--.
            /1\n1*\n1*@/ bmul_iterations
        s/\n1*\n(1*)@/\1@/
    }

    # swap; a=pop, b=pop, c=0; while(a>b) {a-=b; c++}
    /^div/ {
        s/\n(1*)\n(1*)@/\n\2\n\1@/ # Swap.
        s/@/\n@/ # Push zero.
        :div_iterations
            /\n(1*)\n1*\1\n/! bnot_matched
            s/\n(1*)(\n1*)\1(\n1*@)/\n\1\2\3/ # a-=b.
            s/\n(1*)@/\n1\1@/ # c++.
            bdiv_iterations
        :not_matched
        s/\n1*\n1*(\n1*@)/\1/
    }

    # swap; a=pop, b=pop; while(a>b) a-=b; push(a)
    /^mod/ {
        s/\n(1*)\n(1*)@/\n\2\n\1@/ # Swap.
        :mod_iterations
            /\n(1*)\n1*\1@/! bmod_end
            s/\n(1*)(\n1*)\1@/\n\1\2@/ # a-=b.
            bmod_iterations
        :mod_end
        s/\n1*(\n1*@)/\1/
    }

    /^[01]/ {
        s/@/\n@/
        :dec
            :r s/^([10]*)0(_*) /\1_\2 /; tr
            s/^([10]*)1(_*) /\10\2 /
            :t s/^([01]*)_([01_]*) /\11\2 /; tt
            s/^0([^ ])/\1/
            s/\n(1*)@/\n1\1@/ # Increment the top of the stack.
            /^0 /! bdec
    }

    s/^[^ ]* // # Remove current token.
    /^\$/! bnext_token

s/^.*\$\n(.*)@.*$/\1/
# Pattern space: <Month>\n<Day>

# May day fixup.
# TODO: Change the source rpn-script instead.
/^11111\n/ s/\n1*$/&1/
/^1111\n/ {
    /\n1111111111111111111111111111111$/ {
        s/\n1111111111111111111111111111111$/\n1/;
        s/^1111/11111/
    }
}

s/^111\n/March,/; s/^1111\n/April,/; s/^11111\n/May,/;
s/,/, /

# Convert the day of the month to base 10.
# TODO: consider to spell the number.
x; s/^.*$/0/; x
:to_decimal
    x
    :replace s/9(_*)$/_\1/; treplace
    s/^(_*)$/0\1/
    s/^/0123456789@/
    :increment
        s/(.)(.)(@.*)\1(_*)$/\1\3\2\4/
        tok; s/.@/@/; :ok
        /..@/ bincrement
    s/^.*@//
    s/_/0/g
    x
    s/1$//
    /1$/ bto_decimal

G; s/\n//; p
