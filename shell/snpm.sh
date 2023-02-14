npm search "$@" --json |
  $(dirname $0)/prelude.sh -c jsonf -acf 'name,version,links.npm,links.repository' |
  tabulate -1
