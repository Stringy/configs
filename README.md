# Config files. 

Uses a bare repo method to store these and check them out properly (as detailed here: https://www.atlassian.com/git/tutorials/dotfiles)

For new systems:

```bash
$ alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
$ echo ".cfg" >> .gitignore
$ git clone --bare <git-repo-url> $HOME/.cfg
$ config checkout
$ config config --local status.showUntrackedFiles no
```

If upon calling `config checkout` you end up with errors, back up the reported files, or remove them.

Then add files or modifications as necessary:

```
$ config add .zshrc
$ config commit -m 'Message'
$ config push
```
