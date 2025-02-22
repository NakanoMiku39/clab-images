# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

#Synopsys
export DVE_HOME=/opt/eda/Synopsys/vcs/Q-2020.03-SP2-7
export VCS_HOME=/opt/eda/Synopsys/vcs/Q-2020.03-SP2-7
export LD_LIBRARY_PATH=/opt/eda/Synopsys/verdi/R-2020.12-SP1/share/PLI/VCS/LINUX64
export VERDI_HOME=/opt/eda/Synopsys/verdi/R-2020.12-SP1
export SCL_HOME=/opt/eda/Synopsys/scl/2021.03
export DC_HOME=/opt/eda/Synopsys/syn/R-2020.09-SP4
export PATH=$PATH:/opt/eda/Synopsys/syn/R-2020.09-SP4/bin
#export SYNOPSYS=/opt/eda/Synopsys/syn/O-2018.06-SP1

## PT
export PT_HOME=/opt/eda/Synopsys/prime/R-2020.09-SP4
export PATH=$PATH:/opt/eda/Synopsys/prime/R-2020.09-SP4/bin
alias pt="primetime"

## Spyglass
export SPYGLASS_HOME=/opt/eda/Synopsys/spyglass/Q-2020.03-SP2-3/SPYGLASS_HOME
export PATH=$PATH:$SPYGLASS_HOME/bin
export SPYGLASS_DC_PATH=/opt/eda/Synopsys/syn/R-2020.09-SP4

## Formality
export PATH=$PATH:/opt/eda/Synopsys/fm/R-2020.09/bin
export FM_HOME=/opt/eda/Synopsys/fm/R-2020.09
alias fm="formality"

## Hspice
export PATH="/opt/eda/Synopsys/hspice/S-2021.09/hspice/bin:"$PATH

## Waveview
export PATH="/opt/eda/Synopsys/wv/S-2021.09/bin:"$PATH


#dve
#PATH=$PATH:$VCS_HOME/gui/dve/bin
#alias dve="dve -full64"

#VERDI
PATH=$PATH:$VERDI_HOME/bin
#alias verdi="verdi -full64"

#VCS
PATH=$PATH:$VCS_HOME/bin
alias vcs="vcs -full64"

#DC
alias dc="dc_shell"
alias dv="design_vision"

#scl
PATH=$PATH:$SCL_HOME/linux64/bin
export VCS_ARCH_OVERRIDE=linux

#LICENCE
export SNPSLMD_LICENSE_FILE=27000@localhost.localdomain
alias lmg="/opt/eda/Synopsys/scl/2021.03/linux64/bin/lmgrd -c /opt/eda/Synopsys/scl/2021.03/admin/license/Synopsys.dat"

export LM_LICENSE_FILE=/opt/eda/Synopsys/scl/2021.03/admin/license/Synopsys.dat