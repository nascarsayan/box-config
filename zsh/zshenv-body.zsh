# Appended to home-manager's .zshenv (programs.zsh.envExtra).
#
# Must be .zshenv, not .zshrc: it has to run before /etc/zshrc, which on managed
# hosts sources /etc/profile.d/*.sh and spawns children.
#
# Why: some EDA/simulator toolchains put several network-mounted dirs on
# LD_LIBRARY_PATH. glibc then walks each, times ~10 hwcaps/tls variants, times every
# library, per child -- ~1000 cold network stats per shell startup. eda_on restores
# the original, which you want before running those tools.
typeset -ga EDA_LD_PREFIXES
(( ${#EDA_LD_PREFIXES} )) || EDA_LD_PREFIXES=(/tools/)

_box_strip_ld() {
  local -a parts kept
  local p keep
  parts=("${(@s/:/)LD_LIBRARY_PATH}")
  kept=()
  for p in $parts; do
    keep=1
    for pre in $EDA_LD_PREFIXES; do
      [[ $p == ${pre}* ]] && { keep=0; break }
    done
    (( keep )) && kept+=($p)
  done
  export LD_LIBRARY_PATH="${(j/:/)kept}"
}

if [[ -o interactive && -n "${LD_LIBRARY_PATH:-}" ]]; then
  export __ORIG_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
  _box_strip_ld
fi

eda_on()  { [[ -n "${__ORIG_LD_LIBRARY_PATH:-}" ]] && export LD_LIBRARY_PATH="$__ORIG_LD_LIBRARY_PATH"; }
eda_off() { _box_strip_ld; }

# path is a nix profile plus the inherited host PATH, which duplicates entries
# freely. -U keeps the first occurrence of each and drops the rest.
typeset -gU path
