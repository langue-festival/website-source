# Langue [![Build Status](https://travis-ci.org/langue-festival/langue-festival.github.io.svg?branch=master)](https://travis-ci.org/langue-festival/langue-festival.github.io)

This is the source code of the *Langue* poetry festival official website.

## Build

The compilation involves a Makefile (tested with *GNU make*) and requires [yarn](https://yarnpkg.com).
Once you have these tools you can build the project as follows:

1. clone the project using `git clone` or download as [zip](https://github.com/langue-festival/langue-festival.github.io/archive/master.zip)

2. point your console at the project path (e.g.: `cd langue-festival.github.io`)

3. run `make`

This process should produce an `index.html` in the current directory with all resources (except images) inlined.

### Linux

On Linux you probably just need to install [yarn](https://yarnpkg.com/en/docs/install#linux-tab).

### Windows

Download and install [Make for Windows](http://gnuwin32.sourceforge.net/downlinks/make.php).

Start `cmd.exe` as administrator and install [chocolatey](https://chocolatey.org/install), then run `choco install yarn`. Restart cmd if needed.

Now you can point your console to the project path (e.g.: `cd Desktop\langue-festival.github.io`) and launch make: `"C:\Program Files (x86)\GnuWin32\bin\make.exe"`
