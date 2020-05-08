#!/bin/sh

passed=0
failed=0
from=1994
to=2034
total=$(($to-$from+1))
for i in `seq $from $to`; do
    expected=`grep $i test-easter-dates.txt | sed -Ee 's/^.* +([^ ]*) +([^ ]*)$/\1, \2/'`
    echo -n .
    result=`echo $i | ./computus.sed`
    if [ "x$expected" = "x$result" ]; then
        passed=$(($passed+1))
    else
        failed=$(($failed+1))
    fi
done

echo -e "\n$total tests performed, $passed tests passed, $failed tests failed."
