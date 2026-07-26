# Linux: nix installer のフックは /etc/zshrc にあり GLOBAL_RCS=off で読まれないため補う
# macOS: nix-darwin が /etc/zshenv で設定済み。重ねると NIX_PROFILES が縮む
if [[ -z "${__NIX_DARWIN_SET_ENVIRONMENT_DONE:-}" && -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
	source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

typeset -gU PATH path
typeset -gU FPATH fpath

path=(
	"$HOME/.local/bin"(N-/)
	"$HOME/.cargo/bin"(N-/)
	# mise 管理ツールを nix profile(tenv 等)・homebrew より優先する。
	# 効くのは非対話シェルのみ（対話シェルは .zshrc の mise activate が先頭へ置く）。
	# 未管理ツールは shim が PATH 上の次へフォールスルーするため副作用なし。
	"$XDG_DATA_HOME/mise/shims"(N-/)
	"/etc/profiles/per-user/$USER/bin"(N-/)
	"/run/current-system/sw/bin"(N-/)
	"${GHOSTTY_BIN_DIR}"(N-/)
	"/opt/homebrew/bin"(N-/)
	"/opt/homebrew/sbin"(N-/)
	"/usr/local/bin"(N-/)
	"/usr/local/sbin"(N-/)
	"/usr/bin"(N-/)
	"/usr/sbin"(N-/)
	"/bin"(N-/)
	"/sbin"(N-/)
	"$path[@]"
)

fpath=(
	"$XDG_DATA_HOME/zsh/completions"(N-/)
	"$fpath[@]"
)
