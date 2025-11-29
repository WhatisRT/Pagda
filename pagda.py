#!/usr/bin/env python3
import os
import argparse
from pathlib import Path
import re
import subprocess

default_config = {"useUntracked": "ask"}

def has_nix():
    return subprocess.call(["which", "nix"], stdout=open(os.devnull, "w"), stderr=subprocess.STDOUT) == 0

def has_uncommitted_files():
    return subprocess.check_output(["git", "ls-files", "--others"]) != ""

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

def get_configuration():
    config = default_config

    global_config_path = ".pagda"
    if not os.path.exists(global_config_path):
        os.makedirs(global_config_path, exist_ok=True)

    project_config_path = Path(".").parent / "pagda.conf"
    if project_config_path.is_file():
        config.update(parse_config(project_config_path))

    return config

def get_project_root():
    candidate = Path("./pagda.nix")
    root_dir = os.path.abspath(os.curdir)

    while True:
        if candidate.is_file():
            return root_dir
        elif candidate == Path("/"):
            raise Exception("Unable to find project root.")
        else:
            root_dir, candidate = os.path.split(root_dir)

def onInit(args):
    config = get_configuration()

    if not has_nix():
        print("Nix not found. Please install Nix before proceeding.")
        return

    template_dir = Path(__file__).parents[0] / "template"
    os.makedirs(args.project_root, exist_ok=True)

    copy_transform(os.path.join(template_dir, "flake.nix"),
                   os.path.join(args.project_root, "flake.nix"),
                   lambda x: x)

    copy_transform(os.path.join(template_dir, "pagda.nix"),
                   os.path.join(args.project_root, "pagda.nix"),
                   lambda x: x)
        # pagda_content = re.sub(r"agdaPackages", f'agdaPackages = {{ import nixpkgs }};', pagda_content)

    copy_transform(os.path.join(template_dir, "simple.agda-lib"),
                   os.path.join(args.project_root, f"{args.project_name}.agda-lib"),
                   lambda x: x)

def onDebug(args):
    project_root = get_project_root()
    print("Project root:", project_root)
    config = get_configuration()
    print("Config:", config)

def get_use_untracked(config):
    use_untracked = config["useUntracked"]

    if use_untracked == "true":
        return True
    elif use_untracked == "false":
        return False
    else:
        reply = input("Are you using untracked files for this build? [y/n]: ")
        return reply.lower() in ["y", "yes"]

def onBuild(args):
    project_root = get_project_root()
    config = get_configuration()

    prefix = ""

    if has_uncommitted_files():
        use_untracked = get_use_untracked(config)

        if use_untracked:
            prefix = "path:"

    nix_cmd = f"nix build {prefix}.#{args.derivation}"

    subprocess.run(nix_cmd, shell=True, check=True)

def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command")

    init_parser = subparsers.add_parser("init")
    init_parser.add_argument("project_name", help="Project name")
    init_parser.add_argument("project_root", help="Project root directory")

    build_parser = subparsers.add_parser("build")
    build_parser.add_argument("derivation", nargs="?", default="default", help="Derivation name (defaults to 'default')")

    build_parser = subparsers.add_parser("debug")

    args = parser.parse_args()

    if args.command == "init":
        onInit(args)

    elif args.command == "debug":
        onDebug(args)

    elif args.command == "build":
        onBuild(args)

if __name__ == "__main__":
    main()
