{ agdaPackages }: with agdaPackages; rec {

  simple-library = mkDerivation {
    pname = "simple";
    version = "0.1";
    src = ./.;
    meta = { };
    libraryFile = "simple.agda-lib";
    buildInputs = [
      standard-library
      standard-library-classes
      standard-library-meta
      abstract-set-theory
    ];
  };
  default = simple-library;
}
