Random tests generation
=======================

The test files in this directory, if present, are randomly generated.

To generate some fresh random tests, run `./genTests.sh`, which will generate just as many tests as needed so that the total number of tests in ../* is 42.

The tests are netlists that are guaranteed to have (by default) 50 inputs, 50 outputs, at least 500 intermediary variables which will *all* contribute to at least one output variable, and will run for 2000 cycles on randomly chosen inputs.

The expected output file is generated using Nathanaël Courant's circuit simulator, which was developped independantly of mine and thus is very unlikely to have the same bugs as mine. Thus, *an error doesn't mean that my compiler is wrong*, but that one of our compilers is wrong (or maybe both).
