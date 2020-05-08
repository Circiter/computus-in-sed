#!/bin/sh

if [ "x$2" = x ]; then
    echo 'usage:' $0 "<from_year> <to_year>"
    exit
fi

passed=0
failed=0
from=$1
to=$2

if [ $to -le $from ]; then
    echo "invalid range"
    exit
fi

total=$(($to-$from+1))
for i in `seq $from $to`; do
    expected=`./computus.pl $i`
    echo -n .
    result=`echo $i | ./computus.sed`
    if [ "x$expected" = "x$result" ]; then
        passed=$(($passed+1))
    else
        failed=$(($failed+1))
    fi
done

echo -e "\n$total tests performed, $passed tests passed, $failed tests failed."
