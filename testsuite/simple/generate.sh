#!/bin/bash

pwd=`dirname "$0"`
gccxml=`which gccxml`
$gccxml "$pwd/simple.h" -fxml="$pwd/simple.xml"
$pwd/../../dcgen --outdir="$pwd" "$pwd/simple.xml"

cd "$pwd"
make
dsss build
