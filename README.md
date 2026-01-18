# Dotfiles

## Overview

This repository contains my **personal configuration files (Dotfiles)** for a macOS (Apple Silicon) environment.

### Environment

- **OS**: macOS (Apple Silicon)

## Installation

To set up your environment with these Dotfiles, please follow these steps:

1.  mise Configuration:
    Create and place your `config.toml` file in the `config/mise/` directory located at the root of this Dotfiles repository.
2.  **Git Personal Information**:
    Create and place your `config.local` file, containing your Git account information, in the `config/git/` directory located at the root of this Dotfiles repository.
3.  Run Installation Script:
    After cloning the repository, execute the following command **from the project root**:

    ```bash
    ./scripts/install.sh
    ```

4.  Refresh Zsh Session:
    Once the installation is complete, start a new Zsh session or run `exec zsh` to apply the settings.
5.  **Features Requiring Manual Import**:
    For tools like Raycast, you'll need to **manually import** your existing settings.
