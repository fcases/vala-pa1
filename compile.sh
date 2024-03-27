#!/bin/bash
mkdir build
cd build
meson ..
meson compile
mv pa1_v ../out/bin
