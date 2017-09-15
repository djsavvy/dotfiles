#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# added by Miniconda3 4.3.14 installer
export PATH="/home/savvy/go/bin:/usr/lib/ccache/bin/:/home/savvy/miniconda3/bin:$PATH"
alias config='/usr/bin/git --git-dir=/home/savvy/.cfg/ --work-tree=/home/savvy'
