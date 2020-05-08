# computus-in-sed

The sed script for performing the calculation of the date of Eastern Orthodox Easter.

Usage example:
```bash
echo 2020 | ./computus.sed
```

For testing for the years from 1994 upto 2034 execute `./dictionary-test.sh` or
to test an arbitrary range of years (using perl-module [Dates::Easter](dates-easter)) run
`./range-test.sh <from_year> <to_year>` (beware that both methods take a very long time due to
the use of unary radix in current version of my script).

For more details see the actual implementation in `computus.sed` and/or my [blog-post][computus-in-sed].

TODO: In principle, it is possible and not so hard to implement other
algorithms for computus (e.g. for Catholic Easter).

References:
- Jean Meeus, Astronomical Algorithms, 1991
- http://en.wikipedia.org/wiki/computus
- http://ru.wikipedia.org/wiki/пасхалия
- [Пасхалия в sed // блог-пост][computus-in-sed]

[computus-in-sed]: http://circiter.tk/computus-in-sed
[dates-easter]: http://search.cpan.org/dist/Date-Easter
