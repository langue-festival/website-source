# Langue Website Source [![Build Status](https://travis-ci.org/langue-festival/website-source.svg?branch=master)](https://travis-ci.org/langue-festival/website-source)

Source code of the [Langue](https://langue-festival.github.io) poetry festival official website.

This experiment consists of a single page application written in [Elm](http://elm-lang.org) which loads contents from [Markdown](https://daringfireball.net/projects/markdown) formatted files.

## Build

The compilation involves a Makefile (tested on *Debian* 9 with *GNU* make), requires [yarn](https://yarnpkg.com) and [node](https://nodejs.org).
Once you have these tools you can build the project as follows:

1. clone the project using `git clone` or download as [zip](https://github.com/langue-festival/website-source/archive/master.zip)

2. point your console at the project path (e.g.: `cd website-source`)

3. run `make`

This process should create a directory named `deploy` containing `index.html` and all resources needed.

## Development environment

Running `make dev` will start a web server, just point your browser to [http://localhost:8000](http://localhost:8000).
