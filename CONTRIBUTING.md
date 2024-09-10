# Contributing to Private Location Worker

We’re excited to have you contribute to **Private Location Worker**! Here’s a simple guide to help you get started.

## How Can I Contribute?

### 1. Reporting Issues
If you find a bug or have a suggestion, please [open an issue](https://github.com/OctoMind-dev/private-location-worker/issues). Provide details such as:
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots or logs (if applicable)

### 2. Submitting Pull Requests
1. Fork the repository and create a branch for your changes.
2. Make your changes in the branch.
3. Test your changes.
4. Submit a Pull Request (PR) with a clear explanation of what you’ve done.

### 3. Code Style
Please follow the existing code style in the project. Run any provided linters or formatters before submitting your changes.

## Setting Up the Development Environment

We use Docker to run the project. Follow these steps to set up the environment:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/OctoMind-dev/private-location-worker.git
   cd private-location-worker

2. **Build and start the Docker container:**

    ```bash
    docker build . -t plw:local
    docker run --rm -it --name plw -e <vars> plw:local

3. **Stopping the container:**

    ```bash
    docker stop plw
    -- or --
    just Crtl-C if it was started with -it option

Thank you for contributing to Private Location Worker!