module Templates where

flakeNix :: String
flakeNix = unlines
  [ "# Warning: only edit this file if you know what you're doing!"
  , "# In this case, consider using `agda.nix` directly."
  , "{"
  , "  description = \"Pagda nix template\";"
  , ""
  , "  inputs = {"
  , "    nixpkgs.url = \"github:NixOS/nixpkgs\";"
  , ""
  , "    flake-utils.url = \"github:numtide/flake-utils\";"
  , ""
  , "    agda-nix = {"
  , "      url = \"github:input-output-hk/agda.nix\";"
  , "      inputs.nixpkgs.follows = \"nixpkgs\";"
  , "    };"
  , ""
  , "    pagda = {"
  , "      url = \"./pagda.nix\";"
  , "      flake = false;"
  , "    };"
  , "  };"
  , ""
  , "  outputs ="
  , "    inputs@{"
  , "      self,"
  , "        nixpkgs,"
  , "        flake-utils,"
  , "        ..."
  , "    }:"
  , "    let"
  , "      inherit (nixpkgs) lib;"
  , "    in"
  , "      flake-utils.lib.eachDefaultSystem ("
  , "        system:"
  , "        let"
  , "          pkgs = import nixpkgs {"
  , "            inherit system;"
  , "            overlays = ["
  , "              inputs.agda-nix.overlays.default"
  , "            ];"
  , "          };"
  , ""
  , "          pagda = import inputs.pagda { agdaPackages = pkgs.agdaPackages; };"
  , "        in"
  , "          {"
  , "            packages = pagda // {"
  , "              agda = pkgs.agdaPackages.agda.withPackages"
  , "                (builtins.filter (p: p ? isAgdaDerivation) pagda.default.buildInputs);"
  , "            };"
  , "          }"
  , "      );"
  , "}"
  ]

pagdaNix :: String
pagdaNix = unlines
  [ "{ agdaPackages }: with agdaPackages; rec {"
  , ""
  , "  example = mkDerivation {"
  , "    pname = \"example\";"
  , "    version = \"0.1\";"
  , "    src = ./.;"
  , "    meta = { };"
  , "    libraryFile = \"example.agda-lib\";"
  , "    buildInputs = ["
  , "      standard-library"
  , "      standard-library-classes"
  , "      standard-library-meta"
  , "    ];"
  , "  };"
  , ""
  , "  default = example;"
  , "}"
  ]

agdaLib :: String
agdaLib = unlines
  [ "name: example"
  , "depend: standard-library"
  , "        standard-library-classes"
  , "        standard-library-meta"
  , "include: ."
  ]

testAgda :: String
testAgda = unlines
  [ "module Test where"
  , ""
  , "open import Data.Product"
  , "open import Data.List"
  , "open import Tactic.Defaults"
  , "open import Tactic.Derive.DecEq"
  , ""
  , "data Test : Set where"
  , "  t1 t2 t3 : Test"
  , ""
  , "unquoteDecl DecEq-Test = derive-DecEq ((quote Test , DecEq-Test) ∷ [])"
  ]

substitute :: String -> String -> String -> String
substitute old new s = go s
  where
    go [] = []
    go s' = case matchAt s' of
      True -> new ++ go (drop (length old) s')
      False -> case s' of
        (c:cs) -> c : go cs
    matchAt [] = False
    matchAt s' = length old <= length s' && take (length old) s' == old
