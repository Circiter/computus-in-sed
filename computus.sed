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
# t=d+e+114+13 # FIXME.
# Month=floor(t/31)
# Day=(t%31)+1

# Reverse Polish notation script.
s/$/ set_year get_year 4 mod set_a/
s/$/ get_year 7 mod set_b/
s/$/ get_year 19 mod set_c/
s/$/ 19 get_c mul 15 plus 30 mod set_d/
s/$/ 2 get_a mul 4 get_b mul plus 34 plus get_d minus 7 mod set_e/

# 13 is the correction for the [1900; 2099] years.
s/$/ get_d get_e plus 114 plus 13 plus set_t/

s/$/ get_t 31 div set_month/ # Month.
s/$/ get_t 31 mod 1 plus set_day/ # Day.

# May day correction.
s/$/ get_month 5 eq if get_day 1 plus set_day then/
s/$/ get_month 4 eq if get_day 31 eq if/
s/$/ 5 set_month 1 set_day then then/

s/$/ get_month get_day \$@/

# Simple stack-based postfix calculator.
:replace_if s/ if / < /; treplace_if
:replace_then s/ then / > /; treplace_then
:next_token
    :skip_white s/^ //; tskip_white

    /^eq/ {
        :compare
            # Decrement both numbers.
            s/\n1(1*@)/\n\1/
            s/\n1(1*)(\n1*@)/\n\1\2/
            /\n1+\n1+@/ bcompare
        s/@/\n0@/
        /\n\n\n0@/ s/0@/1@/ # If equal.
        s/\n1*\n1*(\n.@)/\1/ # Leave only the result.
    }

    /^</ {
        # If the top of the stack contains zero
        # then skip the entire [ ... ] block.
        /\n0@/ {
            s/^<[^>]*>//
            s/\n0@/@/
            bnext_token
        }
        s/^<([^>]*)>/\1/
        s/\n[^\n]*@/@/
    }

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

    /^[0-9]/ {
        s/@/\n@/
        :to_unary
            :digit s/^([^ ]*)0(_*) /\1_\2 /; tdigit
            s/^/9876543210,/
            :decrement
                s/^([^ ]*)(.)(.)(,[^ ]*)\2(_*) /\1\2\4\3\5 /
                tdigit_processed
                s/^([^ ]*).,/\1,/
                :digit_processed
                /^[^ ]*..,/ bdecrement
            s/^.*,//
            :restore_nine s/^([^ ]*)_([^ ]*) /\19\2 /; trestore_nine
            s/^0([^ ])/\1/
            s/\n(1*)@/\n1\1@/ # Increment the top of the stack.
            /^0 /! bto_unary
    }

    s/^[^ ]* // # Remove current token.
    /^\$/! bnext_token

s/^.*\$\n(.*)@.*$/\1/
# Pattern space: <Month>\n<Day>

s/^111\n/March,/; s/^1111\n/April,/; s/^11111\n/May,/;
s/,/, /

# Convert the day of the month to base 10.
x; s/^.*$/0/; x
:to_decimal
    x
    :replace s/9(_*)$/_\1/; treplace
    s/^(_*)$/0\1/; s/^/0123456789@/
    :increment
        s/(.)(.)(@.*)\1(_*)$/\1\3\2\4/
        tok; s/.@/@/; :ok
        /..@/ bincrement
    s/^.*@//; s/_/0/g
    x
    s/1$//
    /1$/ bto_decimal

G; s/\n//; p
