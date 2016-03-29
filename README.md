# Kaolcria

This is an [elixir](http://elixir-lang.org/) application. You will need [elixir up and running](http://elixir-lang.org/install.html) on your machine in order to install it and play with it.

## Installation

`git clone` this repository. Then

  1. install and compile the dependencies as follows:

    ```bash
    cd your-local-copy-of-repo
    mix deps.get
    mix deps.compile
    ```

  1. run the tests

    ```bash
    mix test
    ```

    The tests should complete without errors.

  1. build the application

    ```bash
    mix escript.build
    ```

  1. view the help to see what command line arguments are available

    ```bash
    ./aircloak --help
    ```

## Please note

Boolean command line args are turned off by prefixing them with `no-`. Example:

    ```bash
    ./aircloak --no-anonymize
    ```

