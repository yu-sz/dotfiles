# Nix 環境変数 (NIX_SSL_CERT_FILE, NIX_PROFILES 等) を設定
# GLOBAL_RCS=off で /etc/zshrc がスキップされるため、ここで明示的に source する
# NOTE: PATH は下の path=() で再定義するため、nix-daemon.sh による PATH 追加は実質無効
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
	source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

typeset -gU PATH path
typeset -gU FPATH fpath

path=(
	"$XDG_CONFIG_HOME/zsh/bin"(N-/)
	"$HOME/.local/bin"(N-/)
	"$HOME/.cargo/bin"(N-/)
	"/etc/profiles/per-user/$USER/bin"(N-/)
	"/run/current-system/sw/bin"(N-/)
	"${GHOSTTY_BIN_DIR}"(N-/)
	"/opt/homebrew/bin"(N-/)
	"/opt/homebrew/sbin"(N-/)
	"$XDG_DATA_HOME/mise/shims"
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
