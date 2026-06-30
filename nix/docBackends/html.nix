# Basic documentation backend via `agda --html`
{ pkgs }:

agdaLib:

agdaLib.overrideAttrs (old: {
  pname = "${old.pname or "agda-library"}-docs";
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.cmark-gfm ];
  buildPhase = ''
    runHook preBuild
    find . \( -name '*.agda' -o -name '*.lagda' -o -name '*.lagda.md' \
              -o -name '*.lagda.rst' -o -name '*.lagda.tex' -o -name '*.lagda.org' \) -print0 \
      | while IFS= read -r -d "" f; do
          agda --html --html-dir="$out" --html-highlight=auto --highlight-occurrences "$f"
        done
    # Literate Markdown modules come out as .md (agda highlights the code and
    # leaves the prose as markdown); render those to .html so the prose and any
    # images display. --unsafe passes the embedded highlighted-code HTML through.
    for md in "$out"/*.md; do
      [ -e "$md" ] || continue
      name=$(basename "$md" .md)
      {
        printf '<!DOCTYPE html>\n<html lang="en"><head><meta charset="utf-8">'
        printf '<title>%s</title><link rel="stylesheet" href="Agda.css"></head><body>\n' "$name"
        cmark-gfm --unsafe "$md"
        printf '</body></html>\n'
      } > "''${md%.md}.html"
      rm "$md"
    done
    runHook postBuild
  '';
  installPhase = "true";
})
