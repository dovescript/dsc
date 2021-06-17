# The DoveScript Compiler

[DoveScript](https://github.com/dovescript/DeveloperNetwork#demonstration) Semantic Data Model, Syntax Parsing and Verification.

## Status

_CURRENT GOALS:_

- [ ] WebAssembly target
- [ ] Full Global Object definitions
- [ ] Object Reference Generator
- [ ] Runtime

## Building

Basic requirements:
- [Node.js](https://nodejs.org)

Backend requirements:
- JRE or JDK 8 ([jdk.java.net](https://jdk.java.net))
- Terminal environment variable `JAVA_HOME` must point to JRE or JDK 8 installation.
- [Adobe AIR SDK](http://airsdk.harman.com/download)
- `asconfigc` tool, which may be installed with the command `npm install asconfigc -g`

Run:

```sh
cd backend && asconfigc
cd ../frontend && npm install -g
```

## Usage

The frontend provides the commands `dsc` and `dsdoc`.

For now, code or documentation generation are not yet supported. Running `dsc` will only verify sources; for example:

```
dsc --includeSources CustomProgram.ds --includeSources src
```

- [More backend information](backend/README.md)