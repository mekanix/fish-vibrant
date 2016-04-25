[![Slack Room][slack-badge]][slack-link]

# Vibrant

> Pretty, minimal and fast [fish](http://fishshell.com) prompt, inspired by [Pure](https://github.com/vkovtash/pure)

![ISC-licensed](https://img.shields.io/github/license/derhuerst/vibrant.svg)

[![the Vibrant prompt in action](https://asciinema.org/a/38749.png)](https://asciinema.org/a/38749)


## Install

With [fisherman]:

```shell
fisher derhuerst/vibrant
```


## Features

* Shows git branch and whether it's dirty (`*`).
* Indicates when you have unpushed (`⇡`) or unpulled (`⇣`) git commits.
* Prompt character turns red if the last command didn't exit with 0.
* Username and host only displayed when in an SSH or sudo session.
* Shows the current path in the title.

[slack-link]: https://fisherman-wharf.herokuapp.com
[slack-badge]: https://fisherman-wharf.herokuapp.com/badge.svg
[fisherman]: https://github.com/fisherman/fisherman
