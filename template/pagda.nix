{ agdaPackages }: with agdaPackages; rec {

  example = mkDerivation {
    pname = "example";
    version = "0.1";
    src = ./.;
    meta = { };
    libraryFile = "example.agda-lib";
    buildInputs = [
      standard-library
      standard-library-classes
      standard-library-meta
    ];
  };

  default = example;
}
