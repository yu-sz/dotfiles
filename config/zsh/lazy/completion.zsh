### setup ###
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# direnv による XDG_DATA_DIRS の変更を検知し、fpath と zcompdump を同期する
# cd でdevShellに出入りするたびに発火し、変更がなければ即 return
_comp_sync_xdg() {
	[[ "$_comp_sync_old_xdg" == "$XDG_DATA_DIRS" ]] && return
	_comp_sync_old_xdg="$XDG_DATA_DIRS"
	for dir in ${(s.:.)XDG_DATA_DIRS}; do
		local p="$dir/zsh/site-functions"
		[[ -d "$p" ]] && ((!${fpath[(I)$p]})) && fpath+=("$p")
	done
	local fpath_hash=$(echo "${(j.:.)fpath}" | cksum | cut -d' ' -f1)
	compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$fpath_hash"
}
precmd_functions+=(_comp_sync_xdg)

autoload -U +X bashcompinit && bashcompinit
if command -v terraform &>/dev/null; then
	complete -o nospace -C "$(command -v terraform)" terraform
fi

zmodload -i zsh/complist
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# 補完候補をソースの返却順で表示（fzf-tab で絞り込めるのでアルファベット順は不要）
zstyle ':completion:*' sort false
