### node.js ###
[[ -d "$XDG_STATE_HOME/node" ]] || mkdir -p "$XDG_STATE_HOME/node"
if [[ -f "$XDG_STATE_HOME/node_history" && ! -f "$XDG_STATE_HOME/node/history" ]]; then
	mv "$XDG_STATE_HOME/node_history" "$XDG_STATE_HOME/node/history"
fi
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/history"

### PostgreSQL ###
[[ -d "$XDG_STATE_HOME/psql" ]] || mkdir -p "$XDG_STATE_HOME/psql"
if [[ -f "$XDG_STATE_HOME/psql_history" && ! -f "$XDG_STATE_HOME/psql/history" ]]; then
	mv "$XDG_STATE_HOME/psql_history" "$XDG_STATE_HOME/psql/history"
fi
export PSQL_HISTORY="$XDG_STATE_HOME/psql/history"
