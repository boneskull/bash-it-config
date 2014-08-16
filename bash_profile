#!/usr/bin/env bash

function install_bash_it {
	[[ ! -e $HOME/.bash_it ]] && {
		/usr/bin/env git clone https://github.com/boneskull/bash-it.git $HOME/.bash_it
		$HOME/.bash_it/install.sh		
	}
}

source $HOME/.exports
source $HOME/.aliases

# Don't check mail when opening terminal.
unset MAILCHECK

# Load Bash It
source $BASH_IT/bash_it.sh
