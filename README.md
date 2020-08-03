# .dotfiles
Linux .dotfiles, scripts, and configurations

This setup uses a bare repository to track linux .dotfiles and configuration files.

To setup on a new system:  
`alias githome='/usr/bin/git' --git-dir=$HOME/.cfg --work-tree=$HOME'`  
`echo ".cfg" >> .gitignore`  
`git clone --bare <git-repo-url> $HOME/.cfg`  

> Note: You may need to remove any existing conflicting files (such as .bashrc) if there is any default file on the system. Either remove or backup these files.

Setup git to not show untracked files in the status output  
`githome config --local status.showUntrackedFiles no`  

Once cloned, it may be necessary to initialize / update any submodules for any git repositories that are embedded in the environment.  
`
githome clone <url-to-repo-with-submodules>  
githome submodule init  
githome submodule update  
`  

To update submodules if they are updated:  
`githome submodule update`  

For more reading, see the following:  
> <https://www.atlassian.com/git/tutorials/dotfiles>  
> <https://www.atlassian.com/git/tutorials/git-submodule>  

Credit:
> <darth.gerbil@gmail.com>
