### Mark and recall
#
# Jan Petykiewicz 2017-01-26
#
# Functions:
#   mark : Mark a path for later recall.
#          If no directory is given as an argument, marks the current working directory.
#   mlist : List marked directories.
#           Entries are unique and sorted most-to-least recent by mark time.
#   recall: Return to a previously-marked directory.
#           Pass a number to specify an entry in mlist; default is 1 (most recently marked).
#   bamf: Return to a marked directory using a fuzzy search, e.g.
#          ```bamf proj``` may match /home/username/projects/
# 
#   Use of bamf requires python3 and fuzzywuzzy.
#

if [ -z $XDG_DATA_DIR ]; then
  dir=$HOME/.local/share
else
  dir=$XDG_DATA_DIR
fi
mkdir -p $dir
MARK_RECALL_FILE=$dir/.mark_recall
touch $MARK_RECALL_FILE

MARK_RECALL_MEMORY=100


mark() {
  # If no arg given, add current dir
  if [ "$#" -lt 1 ]; then
    dir="$PWD"
  else
      dir="$(cd "$1" && pwd)"
  fi

  # cat inside echo to avoid overwriting before we read
  new_list="$dir
$(cat $MARK_RECALL_FILE)"

  # Remove duplicates, keep a limited number, drop empty lines, and write to file
  echo "$new_list" \
      | awk '!a[$0]++' - \
      | head -n $MARK_RECALL_MEMORY \
      | sed '/^[[:space:]]*$/d' \
      > $MARK_RECALL_FILE
}


recall() {
  if [ "$#" -lt 1 ]; then
    cd $(head -n 1 $MARK_RECALL_FILE)
  else
      cd $(sed "${1}q;d" $MARK_RECALL_FILE)
  fi
}


mlist() {
  cat -n $MARK_RECALL_FILE
}


bamf() {
  if [ "$#" -lt 1 ]; then
    recall
  else
    dir=$(python3 -W ignore -c "
import sys
from fuzzywuzzy import process, fuzz
with open('$MARK_RECALL_FILE') as f:
    path_list = f.readlines()
print(process.extractOne(' '.join(sys.argv[1:]), path_list,
                         scorer=fuzz.token_sort_ratio)[0][:-1])
" "$@")
    cd $dir
  fi
}

