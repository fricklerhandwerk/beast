/**
  This does not work, and is currently not intended to.
  It merely shows that it can be done when filling in all the blanks.
*/
{ systemUnderTest, networkResponses ? { }, proxychains, mitmproxy, runCommand, writeShellApplication }:
rec {
  # a test case written by developers
  exampleTestCase = pkgs.writeShellApplication {
    name = "myTestCase";
    runtimeInputs = [ systemUnderTest ];
    text = ''
      cat <<MARKDOWN
      # This is madness
      MARKDOWN

      system-under-test https://example.com/something

      cat <<MARKDOWN
      This is LITERATE TESTING!
      MARKDOWN
    '';
  };
  # a documentation rendering wrapper written for a particular style of literate testing
  exampleLiterateTesting = { testCase }:
    let
      postProcessor = null; # TODO: take Bash- `set -x`-style output and produce markdown
    in
    pkgs.writeShellApplication {
      name = "render-bash-docs";
      runtimeInputs = [ testCase postProcessor ];
      text = ''
        set -x
        source testCase | post-process $1 # TODO: `$1` is expected to be the `$out` of a derivation this is being run in
      '';
    };

  captureRequestsHelper = { testCase }: pkgs.writeShellApplication {
    name = "capture-requests-helper";
    runtimeInputs = [ testCase mitmproxy (cacert.override { extraCertificateFiles = [ mitmconfig.certificateFile ]; }) ];
    # NOTE: this is exactly the same as `makeTest`, except for s/mitmproxy/mitmdump
    # TODO: make that explicit with a conditional, i.e. merge
    text = ''
      mitmdump # TODO: configure properly using ${mitmconfig.certificatePrivateKey}
      proxychains4 -f ${mitmconfig.proxyconfig} ${testCase.mainProgram} $out;
    '';
  };
  captureRequestsDrv = testCase: runCommand "foo"
    # wrapping this in a derivation ensures that the setup is exactly the same as for the actual test run.
    # make this to be a fixed-output derivation to allow network access.
    # this will fail, but we can pull out the results with `--keep-failed`.
    { outputHash = ""; }
    ''
      ${captureRequestsHelper {inherit testCase;}.mainProgram}
    '';
  # this should be available in the development environment of the test cases
  captureRequests = { testCase }: pkgs.writeShellApplication {
    name = "capture-requests";
    runtimeInputs = [ captureRequests ];
    text = ''
      nix-build ${captureRequestsDrv testCase} --keep-failed
      # TODO: output the captured responses in a structured format on stdout
      # probably have to add some precautions to discern test case failure from the expected hash failure
    '';
  };
  mitmconfig = {
    certificateFile = null; # TODO: derivation that makes all that stuff
    certificatePrivateKey = null; # TODO
    proxyconfig = null; # TODO
  };
  makeTest = { testCase }: writeShellApplication {
    name = "test";
    runtimeInputs = [ testCase (cacert.override { extraCertificateFiles = [ mitmconfig.certificateFile ]; }) ];
    text = ''
      mitmproxy -p 54321 # TODO: configure if ${networkResponses != {}} &
      # TODO: wire it such that testCase accepts $out as an argument
      proxychains4 -f ${mitmconfig.proxyconfig} ${testCase.mainProgram} $out;
    '';
  };
  # TODO: replace the `testCase` terminology, because it's really just about derivations
  makeTestDrv = testCase: runCommand "testcase" { } "${(makeTest { inherit testCase; }).mainProgram} $out";
}
