npm search "$@" --json |
  /Users/longpeng/Documents/GitHub/scripts/shell/prelude.sh -c jsonf -acf 'name,version,links.npm,links.repository' |
  tabulate -1
