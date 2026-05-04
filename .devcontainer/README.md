# Development Container

This dev container provides a stable, reproducible Ruby 2.7.8 environment for developing the Workato Connector SDK, with all native dependencies pre-configured.

## Why Use a Dev Container?

The SDK depends on `charlock_holmes` gem which requires:
- C++17-capable compiler
- ICU library (libicu-dev)
- Specific system dependencies

On Apple Silicon Macs, these dependencies can be difficult to compile against Ruby 2.7.x due to compiler compatibility issues. The dev container solves this by providing a Linux (Debian Bullseye) environment where all dependencies compile cleanly.

## How to Use

### With VS Code / Cursor:
1. Install the "Dev Containers" extension (ms-vscode-remote.remote-containers)
2. Open this project in VS Code/Cursor
3. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
4. Select "Dev Containers: Reopen in Container"
5. Wait for the container to build and dependencies to install
6. You're ready to develop!

### What's Included:
- Ruby 2.7.8 (matches CI environment)
- Bundler with all gems installed
- ICU library and C++ build tools
- Git and GitHub CLI
- Ruby VS Code extensions (Solargraph, EndWise)

### Running Commands:
All commands run inside the container automatically:
```bash
bundle exec exe/workato validate spec/fixtures/validation/valid_connector_test/valid_connector.rb
bundle exec rspec
```

## Alignment with CI

This dev container matches the GitHub Actions CI environment:
- Ruby 2.7.8 (see `.github/workflows/rspec-ruby-current.yml`)
- Linux (Debian Bullseye)
- Same gem versions via `Gemfile.lock`

Changes tested in the dev container should behave identically in CI.
