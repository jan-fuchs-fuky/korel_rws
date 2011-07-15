#!/bin/bash

find -name '*.py' -exec cat {} \; |egrep '(import)|(from)' |grep -v '^#' |sort |uniq
