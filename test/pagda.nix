{ agdaPackages }: with agdaPackages; rec {

  lib = mkDerivation {
    pname = "lib";
    version = "0.1";
    src = ./lib;
    meta = { };
    libraryFile = "lib.agda-lib";
    everythingFile = "Lib.agda";
    buildInputs = [
      standard-library
      standard-library-classes
      standard-library-meta
    ];
  };

  test = mkDerivation {
    pname = "test";
    version = "0.1";
    src = ./test;
    meta = { };
    libraryFile = "test.agda-lib";
    everythingFile = "Test.agda";
    buildInputs = [
      standard-library
      standard-library-classes
      standard-library-meta
      lib
    ];
  };

  default = lib;
}
