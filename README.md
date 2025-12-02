# Pagda, the package manager for Agda

Pagda is a package manager built on top of [agda.nix](https://github.com/input-output-hk/agda.nix). This means it inherits the nice features of nix, such as:
- Reproducable builds
- Caching
- Parallel builds
- etc.

To see the list of supported commands, run `pagda help`.

Note: currently, the only way to run Pagda is by cloning this repository. It'll be packaged at some later point.

## Configuration options

There are three ways to set options for Pagda: a global configuration file, a configuration file local to the project and command line options. The syntax for command line options is `--<name> <value>` and the syntax for configuration files is `name=value;`, each on a separate line.

| Name             | Possible values  | Default | Description                                             |
|------------------|------------------|---------|---------------------------------------------------------|
| useUntracked     | true, false, ask | ask     | What to do with files that are untracked by git         |
| useWarnUntracked | true, false      | true    | Print a warning if certain files are not tracked by git |
