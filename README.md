# dotfiles

Personal dotfiles managed with Git.

## Initialization

Download the bootstrap script on a new machine, then run it from a terminal:

```bash
curl -fsSLo /tmp/dotfiles-init.sh \
  https://raw.githubusercontent.com/okylean/dotfiles/main/init.sh
sh /tmp/dotfiles-init.sh
```

The script installs Chezmoi into `~/.local/bin` when necessary, clones this
repository into `~/.dotfiles`, and applies the configuration. Running the
script from an existing local checkout uses that checkout as the Chezmoi
source directory.

The script does not use `--force`. Chezmoi can therefore stop or prompt when
an existing file conflicts with the managed version.

The current public configuration does not include work identity, age, or
keymanager setup. Existing local Git LFS, credential-helper, and work
configuration should be reviewed before applying the template.

## Reference

- [signalridge/dotfiles](https://github.com/signalridge/dotfiles)
- [theniceboy/.config](https://github.com/theniceboy/.config)
- [ANRlm/dotfiles](https://github.com/ANRlm/dotfiles)
- [for13to1/dotfiles](https://github.com/for13to1/dotfiles)
- [insv23/dotfiles](https://github.com/insv23/dotfiles)
- [wsgggws/dotfiles](https://github.com/wsgggws/dotfiles)
- [lewislulu/terminal-setup](https://github.com/lewislulu/terminal-setup)
- [zeinsshiri1984/ApexDotfiles](https://github.com/zeinsshiri1984/ApexDotfiles)
