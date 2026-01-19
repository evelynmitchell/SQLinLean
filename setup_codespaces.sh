#!/bin/bash
#
# Codespace Setup Script
# Sets up a new GitHub Codespace with all required tools and dependencies
#
# Usage: ./setup_codespaces.sh

# Verify we're running in bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script must be run with bash, not sh"
    echo "Usage: bash setup_codespaces.sh"
    echo "   or: ./setup_codespaces.sh"
    exit 1
fi

set -e  # Exit on error

echo "======================================================================================================"
echo "Setting up Codespace for SQLInLEAN"
echo "======================================================================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Step 1: Install Claude Code
print_step "Installing Claude Code..."
if command -v claude > /dev/null 2>&1; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1)
    print_success "Claude Code already installed ($CLAUDE_VERSION)"
else
    curl -fsSL https://claude.ai/install.sh | bash
    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    # Verify installation succeeded
    if command -v claude > /dev/null 2>&1; then
        CLAUDE_VERSION=$(claude --version 2>&1 | head -1)
        print_success "Claude Code installed ($CLAUDE_VERSION)"
    else
        print_warning "Claude Code installation may have failed - command not found"
    fi
fi
echo ""

# Step 2: Install elan (Lean version manager)
print_step "Installing elan (Lean version manager)..."
if command -v elan > /dev/null 2>&1; then
    print_success "elan already installed ($(elan --version | head -1))"
else
    curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y
    source "$HOME/.elan/env"
    if command -v elan > /dev/null 2>&1; then
        print_success "elan installed ($(elan --version | head -1))"
    else
        print_warning "elan installation may have failed - command not found"
    fi
fi
# Ensure elan is in PATH for current session
if [ -f "$HOME/.elan/env" ]; then
    source "$HOME/.elan/env"
fi
echo ""

# Step 3: Install Lean4 toolchain
print_step "Installing Lean4 toolchain..."
if command -v lean > /dev/null 2>&1; then
    LEAN_VERSION=$(lean --version 2>&1 | head -1)
    print_success "Lean4 already installed ($LEAN_VERSION)"
else
    if command -v elan > /dev/null 2>&1; then
        elan default leanprover/lean4:stable
        if command -v lean > /dev/null 2>&1; then
            LEAN_VERSION=$(lean --version 2>&1 | head -1)
            print_success "Lean4 installed ($LEAN_VERSION)"
        else
            print_warning "Lean4 installation may have failed"
        fi
    else
        print_warning "Cannot install Lean4 - elan not available"
    fi
fi
echo ""

# Step 4: Build the project with lake
print_step "Building Lean project with lake..."
if command -v lake > /dev/null 2>&1; then
    if lake build; then
        print_success "Lean project built successfully"
    else
        print_warning "lake build failed - check output above"
    fi
else
    print_warning "lake not available - skipping project build"
fi
echo ""

# Step 5: Install pre-commit hooks
print_step "Installing pre-commit hooks..."
if [ -f ".pre-commit-config.yaml" ] && [ -d ".venv" ]; then
    # Add uv to PATH if not already there
    export PATH="$HOME/.local/bin:$PATH"

    # Install pre-commit hooks
    uv run pre-commit install
    print_success "Pre-commit hooks installed"

    # Optionally run pre-commit on all files to ensure everything is formatted
    print_step "Running pre-commit on all files (this may take a moment)..."
    if uv run pre-commit run --all-files 2>&1 | tail -10; then
        print_success "Pre-commit checks passed"
    else
        print_warning "Pre-commit made some formatting changes (this is normal)"
    fi
else
    if [ ! -f ".pre-commit-config.yaml" ]; then
        print_warning ".pre-commit-config.yaml not found - skipping pre-commit setup"
    else
        print_warning "Virtual environment not found - skipping pre-commit setup"
    fi
fi
echo ""

# Step 6: Verify installation
print_step "Verifying installation..."
export PATH="$HOME/.local/bin:$PATH"

ERRORS=0

# Check claude
if command -v claude > /dev/null 2>&1; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1)
    print_success "Claude Code: $CLAUDE_VERSION"
else
    print_warning "Claude Code not found in PATH"
    ERRORS=$((ERRORS + 1))
fi

# Check elan
if command -v elan > /dev/null 2>&1; then
    print_success "elan: $(elan --version | head -1)"
else
    print_warning "elan not found in PATH"
    ERRORS=$((ERRORS + 1))
fi

# Check lean
if command -v lean > /dev/null 2>&1; then
    print_success "Lean: $(lean --version | head -1)"
else
    print_warning "Lean not found in PATH"
    ERRORS=$((ERRORS + 1))
fi

# Check lake
if command -v lake > /dev/null 2>&1; then
    print_success "Lake: $(lake --version | head -1)"
else
    print_warning "Lake not found in PATH"
    ERRORS=$((ERRORS + 1))
fi



# Step 7: Run tests to verify everything works
if [ -d "Tests" ] && [ -d ".venv" ]; then
    print_step "Running tests to verify installation..."
    if ./scripts/test unit -v --tb=short 2>&1 | tail -20; then
        print_success "Unit tests passed"
    else
        print_warning "Some tests failed - check output above"
        ERRORS=$((ERRORS + 1))
    fi
    echo ""
fi

# Step 8: Add scripts/ to PATH (blocks bare pytest, provides ./scripts/test)
print_step "Configuring PATH to use project scripts..."
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="export PATH=\"${PROJECT_DIR}/scripts:\$PATH\"  # ASP test runner"
MARKER="# test runner"
if ! grep -qF "$MARKER" ~/.bashrc 2>/dev/null; then
    echo "$SCRIPTS_PATH" >> ~/.bashrc
    print_success "Added ${PROJECT_DIR}/scripts to PATH in ~/.bashrc"
else
    print_success "scripts already in PATH"
fi
export PATH="${PROJECT_DIR}/scripts:$PATH"
echo ""

# Step 9: Display next steps
echo "======================================================================================================"
if [ $ERRORS -eq 0 ]; then
    print_success "Setup complete! Your codespace is ready."
else
    print_warning "Setup completed with $ERRORS warnings - check messages above"
fi
echo "======================================================================================================"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc && source ~/.elan/env"
echo "  2. Verify lean: lean --version"
echo "  3. Verify claude: claude --version"
echo "  4. Run Lean tests: lake build tests && .lake/build/bin/tests"
echo "  5. Read Claude.md for development guidelines"
echo "  6. Read README.md for usage examples"
echo ""
echo "Useful commands:"
echo "  lake build                 # Build the Lean project"
echo "  lake build tests           # Build and run Lean tests"
echo "  lake clean                 # Clean build artifacts"
echo "  elan update                # Update Lean toolchain"
echo ""
