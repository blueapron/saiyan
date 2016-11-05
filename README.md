# saiyan

The strongest and fastest API gateway in the universe.

## Getting started - The Docker way

```bash
make build
make up
```

## Getting started - The old fashioned way

Install crystal:
```bash
brew update
brew install crystal-lang
```

Then check out the codez, and from the root directory of the codez:
```bash
shards install
crystal build --release src/saiyan.cr
./saiyan

```
