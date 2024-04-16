# Beast

Proof of concept for literate integration testing of networked command-line applications, based on Nix.

## Idea

The guiding questions behind Beast are:
- What if an integration test suite was actually a stand-alone project that happens to rely primarily on the system under test?
- What if each test case is a user story in that stand-alone project, implemented as a [literate program](https://en.wikipedia.org/wiki/Literate_programming)?
- What if *all* interactions, including network operations, could be under fully deterministic control within such a test suite?

Nix on its own easily allows expressing such test cases as derivations where the source is the project directory and the `builder` executable wraps the literate program to capture its documentation part.
Then, a successful build means a successful test, and the derivation's output is tested end-user documentation.
But there is one limitation:
Networking cannot be handled conveniently, because derivations run in a sandbox.

Beast provides:
- Convenience for capturing and replaying network responses to be accessed in Nix derivations
- A convention with associate support tools to write literate tests in Bash.

## Prior art

- https://github.com/OceanSprint/tesh

  tesh amounts to the same idea with regards to literate testing.
  Beast approaches the problem from the opposite direction:
  Instead of breaking down annotated Markdown into test cases, test cases are first-class objects from which documentation is produced.
  This has the advantage of allowing use native tooling for the code under test, and does not tie the test framework to the documentation source format.

- https://github.com/polygon/nix-buildproxy

  Nix Buildproxy does the right thing in principle, but only supports tools that obey `HTTP[S]_PROXY`, and requires splicing in network responses via `stdenv` hooks.
  Beast should mock (potentially) all network operations, and simply wrap derivations where the `builder` executable needs to access the network.

## Limitations

- Mocking network responses is only easy if they amount to files.
  Streaming may only be possible with extra setup.
- Literate testing is only as easy for non-interactive command-line programs.
  Literate testing of interactive or graphical programs may not be practical at all with this paradigm.

## Future work

This prototype does two indepenent things, because its purpose is to explore pathways for writing documentation that is automatically tested.
It should be split into separate projects for further development.
