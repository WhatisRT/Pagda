# Basic documentation backend via `agda --html`
{ pkgs }:

agdaLib:

agdaLib.overrideAttrs (old: {
  pname = "${old.pname or "agda-library"}-docs";
  buildPhase = ''
    runHook preBuild
    find . \( -name '*.agda' -o -name '*.lagda' -o -name '*.lagda.md' \
              -o -name '*.lagda.rst' -o -name '*.lagda.tex' -o -name '*.lagda.org' \) -print0 \
      | while IFS= read -r -d "" f; do
          agda --html --html-dir="$out" --html-highlight=auto --highlight-occurrences "$f"
        done
    runHook postBuild
  '';
  installPhase = "true";
})
