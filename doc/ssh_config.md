# GITHUB SSH Keys
If you with to install your own github ssh keys for another account (for example on a work VDI), you can generate a different set of private keys for a different email and install that public key on github.

Generate new RSA key for different email account:
```
ssh-keygen -t rsa -C "<other-email>@<domain>"
Generating public/private rsa key pair.
Enter file in which to save the key (/home/<user>/.ssh/id_rsa): /home/<user>/.ssh/id_rsa.<other-email>
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/<user>/.ssh/id_rsa.<other-email>.
Your public key has been saved in /home/<user>/.ssh/id_rsa.<other-email>.pub.
The key fingerprint is:
xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx <other-email>@<domain>
...
```
> :warning: Don't overwrite your existing `id_rsa` file for your normal user account.

Update .ssh/config to add new host info. If the file doesn't exist, create it and set permissions using `chmod 600 ~/.ssh/config`.
> **NOTE:** This may also cause other SSH/SCP issues with other hosts. So to work around this, add strict identify file usage for all hosts.
```
Host github.com
  Hostname github.com
  User <github-username>
  IdentityFile ~/.ssh/id_rsa.<other-email>

Host *
  IdentitiesOnly yes
```

Add your `.ssh/id_rsa.<other-email>.pub` public key to your github account in the `Settings` / `SSH and GPG keys` page.

Test your SSH connection to github.
```
ssh -T github.com
```

If you want to use these SSH credentials for an existing repository, you may need to update your `<repository>/.git/config` file to the following. If using this dotfiles repository, the git config will be at `${HOME}/.cfg/config`. You will also need to make sure the username and email is correct for this repository:
```
[remote "origin"]
	url = git@github.com:<user-name>/<repository>
[user]
	name = <user-name>
	email = <other-email>@<domain>
```

