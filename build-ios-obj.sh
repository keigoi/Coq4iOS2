#!/usr/bin/env bash
set -v
set -e

if [ ! -e coq-src/README.md ]; then
    git submodule update --init
fi

# make sure we don't use ios toolchain
unset OCAMLFIND_TOOLCHAIN

cd coq-src

if [ ! -e bin/coqdep_boot ]; then
  ./configure -local -with-doc no -coqide no -natdynlink no
  make -j8 bin/coqdep_boot
  
  rm -f clib/minisys.*
  rm -f clib/segmenttree.*
  rm -f clib/unicode.*
  rm -f clib/unicodetable.*
  git checkout clib
  rm -f config/Makefile
fi

export OCAMLFIND_TOOLCHAIN=ios

if [ ! -e config/Makefile ]; then
  ./configure -local -with-doc no -coqide no -natdynlink no
fi

VERBOSE=1 make -j8 -f Makefile.build coqios.o
