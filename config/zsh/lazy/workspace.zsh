workspace() {
	local subcmd="${1:-list}"
	shift 2>/dev/null

	case "$subcmd" in
	list) workspace-session list "$@" ;;
	switch) workspace-session switch "$@" ;;
	new) workspace-session new "$@" ;;
	delete) workspace-session delete "$@" ;;
	rename) workspace-session rename "$@" ;;
	wt) workspace-session wt "$@" ;;
	notify) workspace-notify "$@" ;;
	*) workspace-session list ;;
	esac
}

alias ws='workspace'

workspace-session() {
	local subcmd="${1:-list}"
	shift 2>/dev/null

	case "$subcmd" in
	list)
		while true; do
			local selected
			selected=$(ws-list-sessions | fzf --ansi --reverse \
				--prompt "session> " \
				--header "enter:switch  ctrl-d:delete  ctrl-n:new  ctrl-r:rename  ctrl-g:repos" \
				--expect "ctrl-r" \
				--bind "ctrl-d:execute-silent(
            session=\$(echo {} | sed 's/^● //' | awk '{print \$1}');
            count=\$(tmux list-sessions 2>/dev/null | wc -l);
            [[ \$count -le 1 ]] && exit 0;
            tmux kill-session -t \"\$session\"
          )+reload(ws-list-sessions)" \
				--bind "ctrl-n:become(
            printf 'Session name: ';
            read -r name;
            [[ -n \"\$name\" ]] && tmux new-session -d -s \"\$name\" && tmux switch-client -t \"\$name\"
          )" \
				--bind "ctrl-g:transform:[[ \$FZF_PROMPT == session* ]] &&
            echo 'reload(ghq list)+change-header(enter:create  ctrl-g:sessions)+change-prompt(repo> )' ||
            echo 'reload(ws-list-sessions)+change-header(enter:switch  ctrl-d:delete  ctrl-n:new  ctrl-r:rename  ctrl-g:repos)+change-prompt(session> )'" \
				--bind "enter:transform:[[ \$FZF_PROMPT == repo* ]] &&
            echo 'become(ws-connect-repo {})' ||
            echo 'accept'")

			local key line
			key=$(echo "$selected" | head -1)
			line=$(echo "$selected" | tail -1)

			if [[ "$key" == "ctrl-r" && -n "$line" ]]; then
				local session
				session=$(echo "$line" | sed 's/^● //' | awk '{print $1}')
				printf 'Rename "%s" to: ' "$session"
				read -r name
				if [[ -n "$name" ]]; then
					tmux rename-session -t "$session" "$name"
					workspace-notify rename "$session" "$name"
				fi
				continue
			fi

			[[ -z "$line" ]] && return
			local session_name
			session_name=$(echo "$line" | sed 's/^● //' | awk '{print $1}')
			workspace-session switch "$session_name"
			break
		done
		;;
	switch)
		if [[ -n "$1" ]]; then
			if ! tmux has-session -t "$1" 2>/dev/null; then
				echo "Session not found: $1" >&2
				return 1
			fi
			if [[ -n "$TMUX" ]]; then
				tmux switch-client -t "$1"
			else
				tmux attach-session -t "$1"
			fi
		else
			local selected
			selected=$(ws-list-sessions | fzf --ansi --reverse --header "Select session")
			[[ -z "$selected" ]] && return
			local name
			name=$(echo "$selected" | sed 's/^● //' | awk '{print $1}')
			if [[ -n "$TMUX" ]]; then
				tmux switch-client -t "$name"
			else
				tmux attach-session -t "$name"
			fi
		fi
		;;
	new)
		if [[ "$1" == "--bare" ]]; then
			local name="${2:?Session name required}"
			tmux new-session -d -s "$name"
			if [[ -n "$TMUX" ]]; then
				tmux switch-client -t "$name"
			else
				tmux attach-session -t "$name"
			fi
		elif [[ -n "$1" ]]; then
			local dir
			dir="$(ghq root)/$1"
			[[ ! -d "$dir" ]] && dir="$(ghq root)/$(ghq list | grep -E "/$1$" | head -1)"
			[[ ! -d "$dir" ]] && echo "Repository not found: $1" && return 1
			ws-connect-repo --name "$(basename "$dir")" --dir "$dir"
		else
			local repo
			repo=$(ghq list | fzf --reverse --header "Select repository")
			[[ -z "$repo" ]] && return
			local dir="$(ghq root)/$repo"
			ws-connect-repo --name "$(basename "$repo")" --dir "$dir"
		fi
		;;
	delete)
		local session="${1}"
		if [[ -z "$session" ]]; then
			session=$(tmux list-sessions -F "#{session_name}" | fzf --reverse --header "Delete session")
		fi
		[[ -z "$session" ]] && return
		local count
		count=$(tmux list-sessions 2>/dev/null | wc -l)
		if [[ $count -le 1 ]]; then
			echo "Cannot delete the last session"
			return 1
		fi
		read -q "?Delete session '$session'? [y/N] " || return
		echo
		tmux kill-session -t "$session"
		local state_dir="${TMPDIR%/}/ws-state"
		rm -f "$state_dir"/*_"$session" "$state_dir/notifications-$session"
		;;
	rename)
		local old="${1}" new="${2}"
		[[ -z "$old" || -z "$new" ]] && echo "Usage: workspace rename <old> <new>" && return 1
		tmux rename-session -t "$old" "$new"
		workspace-notify rename "$old" "$new"
		;;
	wt)
		local selected dir name
		selected=$(git worktree list 2>/dev/null | grep -v "$(pwd)" | fzf --reverse --header "Select worktree")
		[[ -z "$selected" ]] && return
		dir=$(echo "$selected" | awk '{print $1}')
		name=$(basename "$dir")
		ws-connect-repo --name "$name" --dir "$dir"
		;;
	esac
}

_workspace() {
	local -a commands
	commands=(
		'list:Session list (interactive)'
		'switch:Switch session'
		'new:Create new session'
		'delete:Delete session'
		'rename:Rename session'
		'wt:Create session from git worktree'
		'notify:Notification management'
	)
	_describe -t commands 'workspace commands' commands
}
compdef _workspace workspace
compdef _workspace ws
