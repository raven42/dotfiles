#
# 00-core/20-aliases.sh - Generic aliases with zero FABOS/Broadcom content. Safe for anyone using this
# public dotfiles repo.
#

function _dita_to_html() {
	local filename=$1

	docker run --rm --volume "$(pwd):/src" --volume "$HOME/dita_html_output:/out" --user $(id -u):$(id -g) ghcr.io/dita-ot/dita-ot:4.2 -i $filename -o /out -f html5 -v
}

# Core aliases
alias dirs='dirs -v'
alias githome='git --git-dir $HOME/.cfg --work-tree $HOME'
alias ls="ls -F -T 0 --color=auto"	# Add class indicator, spaces instead of tabs
alias rebash='source ~/.bashrc'
alias scp="scp -oStrictHostKeyChecking=no"
alias ssh="ssh -e  -oStrictHostKeyChecking=no"
alias telnet="telnet -e ^B"
alias vi="vim"

# Misc Commands
alias pandoc='docker run --rm --volume "$(pwd):/data" --user $(id -u):$(id -g) pandoc/latex --data-dir .'
alias grep='grep --color=auto'

# CTAGS commands
alias ctags-bibtex="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=bibtex --bibtex-kinds=abBciIjmMnpPstu"
alias ctags-c="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=c --c-kinds=hdpgetsumvf"
alias ctags-cpp="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=c++ --c++-kinds=hdpgetncsufmv"
alias ctags-perl="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=perl --perl-kinds=pcfls"
alias ctags-java="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=java --java-kinds=pfgeicm"
alias ctags-js="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=javascript --javascript-kinds=vCcgpmf"
alias ctags-go="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=go --go-kinds=picsmtfv"
alias ctags-python="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=python --python-kinds=icfmv"
alias ctags-cheat="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=cheatsheet --cheatsheet-kinds=hsu"
alias ctags-vim="ctags --extras=+F -f - --format=2 --excmd=pattern --fields=nksSafet --sort=no --append=no -V --language-force=vim --vim-kinds=acfmvnC"

# VNC Server Configs
alias vnc1024x768="vncserver -localhost no -geometry 1010x700"
alias vnc1055x995="vncserver -localhost no -geometry 1058x995"
alias vnc1152x864="vncserver -localhost no -geometry 1134x828"
alias vnc1280x1024="vncserver -localhost no -geometry 1176x995"
alias vnc1280x800="vncserver -localhost no -geometry 1276x750"
alias vnc1440x900="vncserver -localhost no -geometry 1422x822"
alias vnc1600x1080="vncserver -localhost no -geometry 1590x1000"
alias vnc1600x1200="vncserver -localhost no -geometry 1590x1120"
alias vnc1920x1080="vncserver -localhost no -geometry 1908x1000"
alias vnc1920x1200="vncserver -localhost no -geometry 1908x1140"
alias vnc2560x1440="vncserver -localhost no -geometry 2553x1360"
alias vnc3840x1600="vncserver -localhost no -geometry 3825x1520"
alias vnc3085x1600="vncserver -localhost no -geometry 3085x1520"
alias vnc3225x1600="vncserver -localhost no -geometry 3225x1520"
alias vnc5760x1080="vncserver -localhost no -geometry 5750x1040"
alias vncWide='vnc3225x1600'
alias vncWideOld='vnc3085x1600'
alias vncNormal='vnc1600x1200'

# General aliases
alias chrome="google-chrome"
alias pycodestyle="pycodestyle --max-line-length 120"
alias rsync="rsync -a --info=progress2 --stats"
