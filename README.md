# mise-aptos

A [mise](https://mise.jdx.dev) tool plugin that installs the
[Aptos CLI](https://aptos.dev/tools/aptos-cli) using the prebuilt binaries
published at
[`aptos-labs/aptos-cli-releases`](https://github.com/aptos-labs/aptos-cli-releases/releases).

## Install

Add the plugin and install a version:

```bash
mise plugin add aptos https://github.com/gregnazario/mise-aptos-plugin
mise use -g aptos@latest
aptos --version
```

Or pin in a project:

```bash
mise use aptos@9.2.0
```

## Supported platforms

| OS       | Architecture | Target triple                       |
| -------- | ------------ | ----------------------------------- |
| macOS    | arm64        | `aarch64-apple-darwin`              |
| macOS    | x86_64       | `x86_64-apple-darwin`               |
| Linux    | x86_64       | `x86_64-unknown-linux-gnu`          |
| Linux    | arm64        | `aarch64-unknown-linux-gnu`         |
| Windows  | x86_64       | `x86_64-pc-windows-msvc`            |

### Older glibc (Linux)

The default Linux build targets a modern glibc (≈2.31+). On older
distributions (e.g. RHEL 7, CentOS 7) set:

```bash
MISE_APTOS_LINUX_COMPAT=1 mise install aptos@latest
```

to download the `*-unknown-linux-gnu-compat.zip` build instead.

## Versions

Versions track the upstream release tags, with the `aptos-cli-v` prefix
stripped. For example, the upstream tag `aptos-cli-v9.2.0` is exposed as
`9.2.0`. Pre-release tags are surfaced with a `pre-release` note.

## Development

```bash
mise plugin link --force aptos .   # link the local checkout
mise run test                      # install & smoke-test 9.2.0
mise run lint                      # stylua + luacheck + actionlint via hk
mise run ci                        # everything
```

Override the test version with `APTOS_TEST_VERSION=9.1.0 mise run test`.

## License

MIT
