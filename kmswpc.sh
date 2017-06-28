#!/usr/bin/env bash

VERSION="0.1706.2800"

# License
[ "${1}" = "--license" -o "${1}" = "-L" ] && echo "
=======================================================================
LICENSE INFORMATION:

Copyright 2017 Tharrrk

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
========================================================================
" && exit

# Version
[ "${1}" = "--version" -o "${1}" = "-V" ] && echo "Version: ${VERSION}" && exit

# Display help
[ $# -ne 1 -o "${1}" = "--help" -o "${1}" = "-h" ] && echo "Usage: ${0##*/} {OPTION|<imagefile>}

Splits the <imagefile> according to current displays sizes and positions.
OPTION may be
   -V or --version   to show version number
   -L or --license   to show license information
   -h or --help      to show this help
" && exit

# Exit on error
set -e

# Check for tools
[ ${BASH_VERSINFO[0]} -lt 4 ] && { echo "ERROR: bash version 4 or higher is required." >&2; exit 2; }
xrandr --help &>/dev/null || { echo "ERROR: Missing xrandr. Install xserver utils." >&2; exit 2; }
tail --version &>/dev/null || { echo "ERROR: Missing tail. Install coreutils." >&2; exit 2; }
convert -version &>/dev/null || { echo "ERROR: Missing convert. Install imagemagick." >&2; exit 2; }

# Check input file
[ -r "${1}" ] && convert "${1}" info: &>/dev/null || { echo "ERROR: Supplied argument '${1}' was not found or is in unknown image format."; exit 3; }

declare -a NAME WIDTH HEIGHT OFFSETX OFFSETY
declare MINX=65535 MINY=65535 MAXX=0 MAXY=0

while read ID N1 RES N; do

  W=$(( ${RES%%/*} ))

  H="${RES#*x}"
  H=$(( ${H%%/*} ))

  X="${RES#*+}"
  Y=$(( ${X#*+} ))
  X=$(( ${X%%+*} ))

  ID=$(( ${ID%:} ))

# echo "Screen ${ID} '${N}' ${W}x${H} at ${X},${Y}"

  NAME[${ID}]="${N//[^A-Za-z0-9-]/_}"
  WIDTH[${ID}]="${W}"
  HEIGHT[${ID}]="${H}"
  OFFSETX[${ID}]="${X}"
  OFFSETY[${ID}]="${Y}"

  [ ${MINX} -gt ${X} ] && MINX=${X}
  [ ${MINY} -gt ${Y} ] && MINY=${Y}
  [ ${MAXX} -lt $(( X+W )) ] && MAXX=$(( X+W ))
  [ ${MAXY} -lt $(( Y+H )) ] && MAXY=$(( Y+H ))

done <<<"$(xrandr --listactivemonitors|tail -n +2)"

for I in ${!NAME[@]}; do
  convert "${1}" -filter Cubic -resize $((MAXX-MINX))x$((MAXY-MINY))\! -crop ${WIDTH[$I]}x${HEIGHT[$I]}+${OFFSETX[$I]}+${OFFSETY[$I]} +repage "${1%.*}_${I}_${NAME[$I]}.${1##*.}"
done
