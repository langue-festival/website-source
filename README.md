# Langue [![Build Status](https://travis-ci.org/langue-festival/langue-festival.github.io.svg?branch=master)](https://travis-ci.org/langue-festival/langue-festival.github.io)

Source code of the *Langue* poetry festival official website.

This experiment consists of a single page application written in [Elm](http://elm-lang.org) which loads contents from [Markdown](https://daringfireball.net/projects/markdown) formatted files.

## Build

The compilation involves a Makefile (tested on *Debian* 9 with *GNU* make) and requires [yarn](https://yarnpkg.com).
Once you have these tools you can build the project as follows:

1. clone the project using `git clone` or download as [zip](https://github.com/langue-festival/langue-festival.github.io/archive/master.zip)

2. point your console at the project path (e.g.: `cd langue-festival.github.io`)

3. run `make`

This process should produce an `index.html` in the current directory with all resources (except for images and fonts) inlined.

## Development environment

Running `make dev` will download, setup and compile all that is needed to run this website locally. Once is finished you can point your browser to `main.html`.
