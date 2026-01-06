date_to_epoch() {
  python3 - <<EOF
from datetime import datetime
print(int(datetime.strptime("$1", "%Y-%m-%d").timestamp()))
EOF
}

#!/usr/bin/env bash
set -euo pipefail

ANCHOR_SUNDAY="2026-01-04"

COMMITS_ON_ONE=50
COMMITS_ON_ZERO=0

ROWS=()
while IFS= read -r line; do
  ROWS+=("$line")
done < pattern.txt
HEIGHT=${#ROWS[@]}
WIDTH=${#ROWS[0]}

if [[ "$HEIGHT" -ne 7 ]]; then
  echo "pattern.txt must have exactly 7 rows"; exit 1
fi

TZ="Europe/Budapest"
TODAY=$(TZ=$TZ date +%F)

days_since=$(( ( $(date_to_epoch "$TODAY") - $(date_to_epoch "$ANCHOR_SUNDAY") ) / 86400 ))
if (( days_since < 0 )); then
  echo "Today is before anchor"; exit 0
fi

col=$(( days_since / 7 ))
row=$(( days_since % 7 )) 

if (( col >= WIDTH )); then
  echo "Past the bitmap width ($WIDTH)."; exit 0
fi

ch="${ROWS[$row]:$col:1}"
if [[ "$ch" != "0" && "$ch" != "1" ]]; then
  echo "Invalid char '$ch' at row=$row col=$col"; exit 1
fi

n=$COMMITS_ON_ZERO
if [[ "$ch" == "1" ]]; then n=$COMMITS_ON_ONE; fi

echo "TODAY=$TODAY row=$row col=$col bit=$ch commits=$n"

for i in $(seq 1 "$n"); do
  git commit --allow-empty -m "pixel($TODAY) $ch #$i"
done

if [[ "$n" -gt 0 ]]; then
  git push origin HEAD
fi
