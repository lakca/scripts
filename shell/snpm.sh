npm search "$@" --json |
  $(dirname $0)/prelude.sh -c jsonf -ac -f 'name|green,version|red,links.repository|dim,description|dim' | tabulate -s '\t' -1
