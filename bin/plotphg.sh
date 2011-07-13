#! /usr/bin/env bash

#
# Author: Petr Skoda <skoda@sunstel.asu.cas.cz>
#
sed -i '/end/d' phg.ps
convert phg.ps plotphg.png
