# 使い方: jq -n --arg keep <dotted,comma> --slurpfile existing <file> -f merge.jq <sources...>
# 注意: 引数は必ず値束縛（$a; $b）にする。フィルタ束縛（a; b）は reduce 文脈で
# 評価コンテキストがずれ、ネスト配列のマージで左辺の要素が消える（実測で確認済み）
def deepmerge($a; $b):
  if ($a | type) == "object" and ($b | type) == "object" then
    reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = deepmerge($a[$k]; $b[$k]))
  elif ($a | type) == "array" and ($b | type) == "array" then $a + ($b - $a)
  else $b end;
(reduce inputs as $s ({}; deepmerge(.; $s))) as $merged
| reduce ($keep | split(",") | map(select(length > 0) | split(".")) | .[]) as $p
    ($merged;
     ($existing[0] | try getpath($p) catch null) as $v
     | if $v != null then setpath($p; $v) else . end)
