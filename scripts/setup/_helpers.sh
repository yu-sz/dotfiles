#!/usr/bin/env bash
[[ -n "${_HELPERS_LOADED:-}" ]] && return
_HELPERS_LOADED=1

info()  { printf "\033[34m[INFO]\033[0m %s\n" "$1"; }
warn()  { printf "\033[33m[WARN]\033[0m %s\n" "$1"; }
error() { printf "\033[31m[ERROR]\033[0m %s\n" "$1" >&2; }
