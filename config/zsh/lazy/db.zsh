db() {
	local catalog=~/.config/db-catalog/connections.toml
	local name="${1:?usage: db <name> [tool]}"
	local tool="${2:-}"
	local conn driver url

	# yq は欠損キーで null/exit 0 を返すため -e が必須
	conn=$(yq -e -o json -p toml ".connections.\"$name\"" "$catalog" 2>/dev/null) || {
		echo "db: connection '$name' not found in $catalog" >&2
		return 1
	}
	driver=$(jq -r .driver <<<"$conn")
	url=$(jq -r '.url // empty' <<<"$conn")

	case "$driver" in
	postgres)
		if [[ -z "$url" ]]; then
			local user pass host port db
			user=$(jq -r .user <<<"$conn")
			pass=$(jq -r .password <<<"$conn")
			host=$(jq -r .host <<<"$conn")
			port=$(jq -r '.port // 5432' <<<"$conn")
			db=$(jq -r .database <<<"$conn")
			url="postgres://${user}:${pass}@${host}:${port}/${db}"
		fi
		case "${tool:-pgcli}" in
		pgcli) pgcli "$url" ;;
		hq | harlequin) harlequin -a postgres "$url" ;;
		*)
			echo "db: unknown tool '$tool'" >&2
			return 1
			;;
		esac
		;;
	duckdb)
		harlequin -a duckdb "$(jq -r .path <<<"$conn" | sed "s|^~|$HOME|")"
		;;
	sqlite)
		harlequin -a sqlite "$(jq -r .path <<<"$conn" | sed "s|^~|$HOME|")"
		;;
	bigquery)
		harlequin -a bigquery --project "$(jq -r .project <<<"$conn")"
		;;
	clickhouse)
		command -v clickhouse-client >/dev/null || {
			echo "db: clickhouse-client not installed (Phase 4 未着手)" >&2
			return 1
		}
		clickhouse-client --host="$(jq -r .host <<<"$conn")"
		;;
	snowflake)
		echo "snowflake: write Phase 4 overlay or configure snowsql" >&2
		return 1
		;;
	*)
		echo "db: unknown driver '$driver'" >&2
		return 1
		;;
	esac
}

_db_complete() {
	local catalog=~/.config/db-catalog/connections.toml
	[[ -r "$catalog" ]] || return
	local -a names
	names=("${(@f)$(yq -p toml '.connections | keys | .[]' "$catalog" 2>/dev/null)}")
	compadd -- "${names[@]}"
}
compdef _db_complete db
