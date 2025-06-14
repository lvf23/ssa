# SSA - Simple SSH Agent

**SSA** (Simple SSH Agent) is a Bash utility that simplifies managing the `ssh-agent` in your terminal. It allows you to start, stop, and check the status of the SSH agent, with support for key caching and automatic integration with `.bashrc`.

## Installation

With cURL

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/lvf23/ssa/refs/heads/stable/ssa.sh)" ssa install
```

With wget

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/lvf23/ssa/refs/heads/stable/ssa.sh)" ssa install
```

To install SSA, you can run the install command. The `install` command supports two optional arguments:

1. **Cache time (in seconds)** — This sets the default duration for caching your SSH key in the agent. If not specified, it defaults to 3600 seconds (1 hour).
2. **Repository reference (ref)** — This specifies which version of the repository to install. It can be:
   - A tag, e.g. `refs/tags/v1.0.0`
   - A branch, e.g. `refs/heads/main`
   - - A specific commit hash (must be the **full** commit hash), e.g. `a1b2c3d4e5f6g7h8i9j0k123456789abcdef`

Example usage:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/lvf23/ssa/refs/heads/stable/ssa.sh)" ssa install 7200 refs/tags/v1.2.3
```

## Commands

```bash
ssa start  # Starts the SSH agent and adds the SSH key with caching enabled. You can optionally specify the cache time (in seconds) for the SSH key. For example: ssa start 1200
ssa stop # Stops the agent and removes environment variables
ssa status # Shows the current agent and key status
ssa uninstall # Removes SSA from the system
```

## Security Disclaimer

SSH key caching can improve convenience but introduces security risks.
By enabling an SSH agent to cache your private key in memory, anyone with access to your user session might potentially use it without needing your passphrase — especially if your system is left unlocked or compromised. Here are some key points to consider:

- Never share your private SSH key.

- Use a strong passphrase to protect your key.

- Its advised to not use it in public machines.

- Consider locking your screen when away from your computer.

This utility helps manage your keys locally and does not transmit, upload, or store them externally, but you are responsible for how and where you use it.

> **Use at your own risk.**
>
> While SSA is provided under the MIT License (which limits liability), you should understand and accept the potential risks involved before using this tool in sensitive environments.

## License

This project is licensed under the [MIT License](./LICENSE).
