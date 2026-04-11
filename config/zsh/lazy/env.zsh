### node.js ###
[[ -d "$XDG_STATE_HOME/node" ]] || mkdir -p "$XDG_STATE_HOME/node"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/history"

### PostgreSQL ###
[[ -d "$XDG_STATE_HOME/psql" ]] || mkdir -p "$XDG_STATE_HOME/psql"
export PSQL_HISTORY="$XDG_STATE_HOME/psql/history"
