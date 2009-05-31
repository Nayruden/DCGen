#!/bin/bash

pwd=`dirname "$0"`
gccxml=`which gccxml`
$gccxml "$pwd/simple.h" -fxml="$pwd/simple.xml"
$pwd/../../dcgen --outdir="$pwd" --classes="Simple" "$pwd/simple.xml"

cd "$pwd"
# Don't need to call make, dsss.conf has it in prebuild
dsss build
