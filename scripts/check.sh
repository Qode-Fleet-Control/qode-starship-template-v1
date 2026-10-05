#!/bin/sh
# The job: check that starship.toml is valid and renders a prompt — directly with
# `starship prompt`, and through `starship init bash` in an interactive bash.
# Exits 0 when every check passes.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
export STARSHIP_CONFIG="$here/starship.toml"
export STARSHIP_LOG=warn TERM="${TERM:-xterm-256color}"
PATH="$here/.bin:$PATH"   # a local (non-docker) install lands in ./.bin

fail=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }
# drop colour escapes and bash's \001/\002 non-printing markers
strip() { sed 's/\x1b\[[0-9;]*m//g' | tr -d '\001\002'; }

command -v starship >/dev/null || { echo "FAIL starship not on PATH"; exit 1; }
echo "$(starship --version | head -1), config $STARSHIP_CONFIG"

err=$(mktemp); demo=$(mktemp -d)
out=$(cd "$demo" && starship prompt --status=0 2>"$err" | strip)
[ -s "$err" ] && { bad "starship warned about the config:"; sed 's/^/  | /' "$err"; } || ok "config loads without warnings"
case "$out" in "qode "*">"*) ok "prompt renders: $out" ;; *) bad "unexpected prompt: '$out'" ;; esac

out=$(cd "$demo" && starship prompt --status=1 2>/dev/null | strip)
case "$out" in *"x1 >"*) ok "failed command shows the status: $out" ;; *) bad "status not shown: '$out'" ;; esac

out=$(cd "$demo" && starship prompt --status=0 --cmd-duration=5000 2>/dev/null | strip)
case "$out" in *"took 5s"*) ok "slow command shows its duration: $out" ;; *) bad "duration not shown: '$out'" ;; esac

# Through a real shell: starship init bash sets PS1 / PROMPT_COMMAND for an interactive bash.
ps1=$(cd "$demo" && bash --norc --noprofile -i -c 'eval "$(starship init bash)"; starship_precmd 2>/dev/null; printf %s "${PS1@P}"' 2>/dev/null | strip)
case "$ps1" in "qode "*">"*) ok "interactive bash prompt: $ps1" ;; *) bad "bash prompt not from starship: '$ps1'" ;; esac

rm -rf "$err" "$demo"
[ $fail -eq 0 ] && echo PASS || echo FAILED
exit $fail
