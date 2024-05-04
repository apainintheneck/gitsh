# gitsh

A simple shell wrapper for Git that provides logical shell operators, completions, history and doesn't require you to add the `git` prefix to each command.

## Installation

1. Clone this repo
2. Run `shards build --release`
3. Checkout `./bin/gitsh`

## Usage

- Type any Git subcommand to run it without prefixing 'git'.
- Type 'exit' or 'quit' to leave.
- Use the arrow keys for command line history.
- Linenoise provides inline editing as well.

## Development

- Install: `shards install`
- Running: `shards run`
- Linting: `crystal tool format`
- Testing: `crystal spec`

## Contributing

1. Fork it (<https://github.com/apainintheneck/gitsh/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Inspired By
- [zbg](https://github.com/chshersh/zbg) : `zbg` (short for Zero Bullshit Git) is a CLI tool for using `git` efficiently.
- [gitsh.awk](https://gist.github.com/apainintheneck/ddc87043a645e87f2d9e02b69be155b6) : A simplistic `gawk` based `git` shell.
- [fish-shell](https://github.com/fish-shell/fish-shell) : The `fish` shell has a great set of built-in integrations with `git`.

## Contributors

- [apainintheneck](https://github.com/apainintheneck) - creator and maintainer
