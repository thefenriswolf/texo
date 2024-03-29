#!/bin/bash

##############################
######## CONFIG BEGIN ########
##############################

# Project Name
PROJ="default"

# Pick a compiler (default: clang)
CC="default"

# Pick a linker (ld | lld)
LD="default"

# List source files here
SRC="default"

# Header directory
HEADERS="headers/*.h"

# Pick a C standard (c89 | c99 | c11 | c17 | c18 | c2x)
CSTD="-std=c18"

# Default warning flags
STDCFLAGS="-Wall -Wextra -pedantic"

# Optimization (-Oz | -Os | -O0 | -O1 | -O2 | -O3 | -Ofast)
OPTFLAGS="-O3"

# Debug flags
DEBUG="-g3"

# Extra warnings
EXTRAFLAGS="-Wshadow -Wdouble-promotion -Wconversion -Wpadded"

# Linker flags. Popular options (-lm | -lncurses)
LDFLAGS=""

# static analyzer to use (clang-analyzer | infer | none)
ANALYZER="clang-analyzer"

############################
######## CONFIG END ########
############################


# global variables
INFER="./tools/infer-linux64-v1.1.0/bin/infer"

red='\e[31m'
green='\e[32m'
blue='\e[34m'
bold='\e[1m'
clear='\e[0m'

benchTemplate="
#include "your_SRC_here.h"
#include <assert.h>
#include <stdio.h>
#include <time.h>

// benchmark template function, rename to bench<func>
// fill in how often it should run and call the function to benchmark
static void benchTemplate(size_t runs) {
  time_t begin, end;
  begin = time(NULL);
  while (runs > 0) {
    // function call here
    runs--;
  }
  end = time(NULL);
  printf(""<func> ran for: %.17g\n"", difftime(end, begin));
}

static void testTemplate() { assert(expectedReturn, func()); }

int main(void) {
  testTemplate();
  benchTemplate(200000000);
  return 0;
}"

#TODO: this is broken right now, fix
mkfile="
TARGET = $PROJ
SRCS  = $SRC
HEADS = $HEADERS
OBJS = $(SRCS:.c=.o)
DEPS = 
INCLUDES =
CC = $CC
LD = $LD
INFER_PATH = $INFER
CFLAGS = $CSTD $STDCFLAGS $OPTFLAGS $DEBUG $EXTRAFLAGS
LDFLAGS = $LDFLAGS

all: $(TARGET)

$(TARGET): $(OBJS) $(HEADS)
\t$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

run: all
\t@./$(TARGET)

.PHONY: fetch clean

tidy: $(SRCS) $(HEADS)
\tclang-tidy $(SRCS) $(HEADS)

analyze: $(SRCS)
\techo \"not implemented yet\"
\t$(INFER_PATH) run --reactive --continue -- $(CC) $(LDFLAGS) -fuse-ld=$(LD) $(SRCS) -o static-analysis/inf.out

fetch:
\tgit reset --hard
\tgit pull --rebase

clean:
\trm -rfv $(OBJS) $(TARGET) *~ infer-out tools/testbench
"

envClang="
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake
    pkgs.clangStdenv
    pkgs.clang_13
    pkgs.clang-tools
    pkgs.clang-analyzer
    pkgs.lldb
    pkgs.llvmPackages_13.bintools
# pkgs.lld_13
    pkgs.man
    pkgs.man-pages
    pkgs.bashInteractive
  ];
}"

envGCC="
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake
    pkgs.gccStdenv
    pkgs.gcc
    pkgs.clang-tools
    pkgs.gdb
    pkgs.man
    pkgs.man-pages
    pkgs.bashInteractive
  ];
}"

function texo_help() {
    clear
    #TODO: beautify
    echo -e $blue"

████████╗███████╗██╗  ██╗ ██████╗
╚══██╔══╝██╔════╝╚██╗██╔╝██╔═══██╗
   ██║   █████╗   ╚███╔╝ ██║   ██║
   ██║   ██╔══╝   ██╔██╗ ██║   ██║
   ██║   ███████╗██╔╝ ██╗╚██████╔╝
   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝
                                  "$clear
    echo -e $bold"Usage:$clear texo [command]\n"
    echo -e $bold"  Available commands:\n"$clear
    echo -e "  init | i\t\t\tinit project"
    echo -e "  shell | sh\t\t\tload shell env"
    echo -e "  fetch | f | update | u\tfetch latest changes"
    echo -e "  build | c | com | compile\tbuild project"
    echo -e "  clean\t\t\t\tcleanup"
    echo -e "  tidy | t\\t\t\trun clang-tidy"
    echo -e "  analyze | lint | a | l\trun static analyzer"
    echo -e "  benchmark | ttd | bench\trun testbench"
    echo -e "  dump | gen | genmake\t\tdump config as makefile"
}

function texo_config_check(){
    local def="default"
    if [[ $PROJ = $def || $CC = $def || $LD = $def || $SRC = $def ]]; then
        echo -ne $red"ERROR: please visit the config section before invoking texo\n"$clear
        exit
    fi
}

function texo_init(){
    echo -ne $green"WORKING: creating folders\n"$clear
    mkdir -p static-analysis tools headers
    #TODO: make this user configurable
    echo -ne $green"WORKING: write shell.nix\n"$clear
    if [[ $CC = 'gcc' ]]; then
        echo "$envGCC" > shell.nix
    elif [[ $CC = 'clang' ]]; then
        echo "$envClang" > shell.nix
    else
        echo -ne $red"ERROR: no compiler configured\n"$clear
    fi
    echo -ne $green"WORKING: creating testbench.c\n"$clear
    echo "$benchTemplate" > tools/testbench.c
        local analyzer_infer="infer"
    local analyzer_clang="clang-analyzer"
    if [[ $ANALYZER = $analyzer_infer ]]; then
        echo -ne $green"WORKING: downloading and installing infer\n"$clear
        curl -o tools/infer-1.1.0.tar.xz -L https://github.com/facebook/infer/releases/download/v1.1.0/infer-linux64-v1.1.0.tar.xz
        tar -xf tools/infer-1.1.0.tar.xz -C tools/
        rm tools/infer-1.1.0.tar.xz
    elif [[ $ANALYZER = $analyzer_clang ]]; then
        echo -ne $blue"INFO: using clang static analyzer\n"$clear
    else
        echo -ne $red"ERROR: no static analyzer configured\n"$clear
    fi
}

function texo_shell(){
    #TODO: maybe use --pure
    echo -ne $green"WORKING: entering nix-shell\n"$clear
    nix-shell shell.nix
}

function texo_fetch(){
    set -xe
    git reset --hard
    git pull --rebase
}

function texo_compile(){
    set -xe
    $CC -fuse-ld=$LD $CSTD $STDFLAGS $OPTFLAGS $DEBUG $EXTRAFLAGS $LDFLAGS -o $PROJ $SRC
}

function texo_clean(){
    set -xe
    rm -rfv *.o *.out $PROJ *~ infer-out tools/testbench
}

function texo_tidy(){
    set -xe
    clang-tidy $SRC $HEADERS
}

function texo_analyze(){
    local analyzer_infer="infer"
    local analyzer_clang="clang-analyzer"
    set -xe
    if [[ $ANALYZER = $analyzer_infer ]]; then
        $INFER run --reactive --continue -- $CC $LDFLAGS -fuse-ld=$LD $SRC -o static-analysis/inf.out
    elif [[ $ANALYZER = $analyzer_clang ]]; then
        #TODO: check clang-analyzer if this really works
        scan-build -k -v --force-analyze-debug-code -o static-analysis/ $CC $SRC
    elif [[ $ANALYZER = "none" ]]; then
        echo -ne $red"ERROR: no static analyzer configured\n"$clear
    else
        echo -ne $red"ERROR: not a valid option: "$clear
        echo -e $ANALYZER
        echo -e "\n"
    fi
}

function texo_testbench(){
    set -xe
    $CC -fuse-ld=$LD $CSTD $STDFLAGS $DEBUG $EXTRAFLAGS $LDFLAGS -o tools/testbench tools/testbench.c ${SRC//main.c}
    ./tools/testbench
}

function texo_dump(){
    echo "not implemented yet"
    #echo -e "$mkfile" > Makefile
}

case $1 in
    init | i)
        texo_config_check
        texo_init
        ;;
    shell | sh)
        texo_config_check
        texo_shell
        ;;
    fetch | f | update | u)
        texo_config_check
        texo_fetch
        ;;
    com | compile | c | build)
        texo_config_check
        texo_compile
        ;;
    clean)
        texo_config_check
        texo_clean
        ;;
    tidy | t)
        texo_config_check
        texo_tidy
        ;;
    analyze | lint | a | l)
        texo_config_check
        texo_analyze
        ;;
    testbench | benchmark | ttd | bench)
        texo_config_check
        texo_testbench
        ;;
    dump | gen | genmake)
        #texo_config_check
        texo_dump
        ;;
    *)
        clear
        texo_help
        ;;
esac
