#!/usr/bin/env python3
import os
import argparse
from pathlib import Path
import re
import subprocess

default_config = {"useUntracked": "ask", "warnUntracked": "true"}

def has_nix():
    return subprocess.call(["which", "nix"], stdout=open(os.devnull, "w"), stderr=subprocess.STDOUT) == 0

def get_untracked():
    return subprocess.check_output(["git", "ls-files", "--others"])

def has_uncommitted_files():
    return get_untracked() != ""

def warn_untracked():
    untracked = get_untracked().decode("utf-8").splitlines()
    warn = [s for s in untracked if Path(s).name in ["flake.nix", "flake.lock", "pagda.nix"]]
    if warn != []:
        print("The following files which are recommended to be part of your repository are untracked:")
        print("  ", ', '.join(warn))

def copy_transform(template, target, transform):
    with open(template, "r") as f:
        content = f.read()
    with open(target, "w") as f:
        f.write(transform(content))

def parse_config(path):
    with open(path, "r") as f:
        config = {}
        for line in f:
            m = re.match(r"(\w+)=\s*(.*?)\s*;", line)
            if m:
                key, value = m.groups()
                config[key] = value
    return config

def get_project_root():
    candidate = Path.cwd()

    while True:
        if (candidate / "pagda.nix").is_file():
            return candidate
        elif candidate == Path("/"):
            raise Exception("Unable to find project root.")
        else:
            candidate = candidate.parents[0]

def get_configuration(args):
    config = default_config
    root = get_project_root()

    global_config = Path("~/.config/pagda.conf")
    if global_config.is_file():
        config.update(parse_config(global_config))

    project_config = root / "pagda.conf"
    if project_config.is_file():
        config.update(parse_config(project_config))

    args_config = { "useUntracked": args.useUntracked, "warnUntracked": args.warnUntracked }
    config.update((k,v) for k,v in args_config.items() if v is not None)

    return config

def onInit(args, config):
    template_dir = Path(__file__).parents[0] / "template"
    os.makedirs(args.project_root, exist_ok=True)
    subst = lambda content: re.sub("example", args.project_name, content)
    id = lambda x: x

    copy_transform(os.path.join(template_dir, "flake.nix"),
                   os.path.join(args.project_root, "flake.nix"),
                   id)

    copy_transform(os.path.join(template_dir, "pagda.nix"),
                   os.path.join(args.project_root, "pagda.nix"),
                   subst)

    copy_transform(os.path.join(template_dir, "example.agda-lib"),
                   os.path.join(args.project_root, f"{args.project_name}.agda-lib"),
                   subst)

    copy_transform(os.path.join(template_dir, "Test.agda"),
                   os.path.join(args.project_root, "Test.agda"),
                   id)

def onDebug(args, config):
    print("Args:", args)
    project_root = get_project_root()
    print("Project root:", project_root)
    print("Config:", config)

def get_use_untracked(config):
    use_untracked = config["useUntracked"]

    if use_untracked == "true":
        return True
    elif use_untracked == "false":
        return False
    else:
        reply = input("Do you want to use untracked files for this build? [y/n]: ")
        return reply.lower() in ["y", "yes"]

def build_derivation(config, args):
    prefix = ""

    if has_uncommitted_files():
        use_untracked = get_use_untracked(config)

        if use_untracked:
            prefix = "path:"

    return f"{prefix}.#{args.derivation}"

def run_nix(cmd, args, config):
    subprocess.run(f"nix --experimental-features 'nix-command flakes' {cmd} {build_derivation(config, args)}", shell=True, check=True)

def parser():

    parser = argparse.ArgumentParser()
    parser.suggest_on_error = True
    parser.add_argument("--useUntracked", choices=["true", "false", "ask"], help="What to do with files that are untracked by git")
    parser.add_argument("--warnUntracked", choices=["true", "false"], help="Print a warning if certain files are not tracked by git")
    subparsers = parser.add_subparsers(dest="command")

    init_parser = subparsers.add_parser("init")
    init_parser.add_argument("project_name", help="Project name")
    init_parser.add_argument("project_root", help="Project root directory")

    build_parser = subparsers.add_parser("build")
    build_parser.add_argument("derivation", nargs="?", default="default", help="Derivation name (defaults to 'default')")

    shell_parser = subparsers.add_parser("shell")
    shell_parser.add_argument("derivation", nargs="?", default="default", help="Derivation name (defaults to 'default')")

    subparsers.add_parser("debug")
    subparsers.add_parser("help")

    return parser

def main():
    try:
        p = parser()
        args = p.parse_args()

        if args.command == "help":
            p.print_help()
            return

        if args.command == "init":
            onInit(args, config)
            return

        if args.command == "debug":
            onDebug(args, config)
            return

        if not has_nix():
            print("Nix not found. Please install Nix before proceeding.")
            return

        config = get_configuration(args)

        if config["warnUntracked"] == "true":
            warn_untracked()

        if args.command == "build":
            run_nix("build", args, config)

        elif args.command == "shell":
            run_nix("develop", args, config)

    except KeyboardInterrupt:
        print("Interrupted")

if __name__ == "__main__":
    main()
