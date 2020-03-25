# computus-in-sed

The sed script for performing the calculation of the date of Eastern Orthodox Easter.

Usage example:
```bash
echo 2020 | ./computus.sed
```

For testing for the years from 1994 upto 2034 execute `./test.sh`.

For more details see the actual implementation in `computus.sed`.

TODO: In principle, it is possible and not so hard to implement other
algorithms for computus (e.g. for Catholic Easter).

References:
- Jean Meeus, Astronomical Algorithms, 1991
- http://en.wikipedia.org/wiki/computus
- http://ru.wikipedia.org/wiki/пасхалия
