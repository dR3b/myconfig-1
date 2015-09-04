# myconfig / my dotfiles

## about this Repo
it is updated by the script `_update.pl`, which uses
- the lists of files to copy in `_files`, which are grouped by topics, and
- the hooks in `_hooks_before` and `_hooks_after`.

For every host, except for the default host, is a folder of the form
`HOST:hostname` generated.
Some of them may become submodules.

For every group is a folder `GRP:groupname` generated, which contains the
corresponding config files.
Some of them may become submodules.

The folders `.meta` contain information about the files like permissions and
where they belong.

## Other repos, where i have stolen scripts/ideas:
- https://github.com/junegunn/myvim
- https://github.com/Xfennec/cv

## used software
### Enviroment
- xmonad
- xmobar
- systemd
- zsh with grml-zsh-config

### Applications
- rxvt-unicode
- vim
- ranger
- tmux
- zathura
- mutt with offlineimap
- dwb
- ...

### Multimedia
- mplayer
- mpd (on udoo)

### Image Prozessing
- geeqie
- rawtherapee
- gimp
