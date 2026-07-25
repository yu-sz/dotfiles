### setup ###
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit

# XDG_DATA_DIRS 由来の site-functions を fpath へ集約（direnv の devShell 分を含む）
_comp_add_xdg_fpath() {
	local dir p
	for dir in ${(s.:.)XDG_DATA_DIRS}; do
		p="$dir/zsh/site-functions"
		[[ -d "$p" ]] && ((!${fpath[(I)$p]})) && fpath+=("$p")
	done
}

# fpath 構成をキーにした dump を使う。存在すれば監査(compaudit)と再構築を省く(-C)。
# fpath が変化したときだけ hash が変わり dump が無くなるので、その時のみフル compinit で再生成する。
_comp_init() {
	local dump="$XDG_CACHE_HOME/zsh/zcompdump-$(echo "${(j.:.)fpath}" | cksum | cut -d' ' -f1)"
	if [[ -s "$dump" ]]; then
		compinit -C -d "$dump"
	else
		compinit -d "$dump"
	fi
}

_comp_add_xdg_fpath
_comp_init
_comp_sync_old_xdg="$XDG_DATA_DIRS"

# direnv による XDG_DATA_DIRS の変更を検知し、fpath と zcompdump を同期する
# cd でdevShellに出入りするたびに発火し、変更がなければ即 return
_comp_sync_xdg() {
	[[ "$_comp_sync_old_xdg" == "$XDG_DATA_DIRS" ]] && return
	_comp_sync_old_xdg="$XDG_DATA_DIRS"
	_comp_add_xdg_fpath
	_comp_init
}
precmd_functions+=(_comp_sync_xdg)

autoload -U +X bashcompinit && bashcompinit
if command -v terraform &>/dev/null; then
	complete -o nospace -C "$(command -v terraform)" terraform
fi

# devShell ごとに増える zcompdump-<hash> を 30 日で掃除
command find "$XDG_CACHE_HOME/zsh" -name 'zcompdump-*' -mtime +30 -delete 2>/dev/null

zmodload -i zsh/complist
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
# 補完候補をソースの返却順で表示（fzf-tab で絞り込めるのでアルファベット順は不要）
zstyle ':completion:*' sort false
