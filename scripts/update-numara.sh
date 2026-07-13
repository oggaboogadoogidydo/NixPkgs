#!/usr/bin/env bash
set -euo pipefail

# Path to the package file
PKG_FILE="pkgs/numara.nix"

# Temporary file for editing
TMP_FILE=$(mktemp)

# Helper to get current version from the nix file
get_current_version() {
    grep -oP 'version = "\K[^"]+' "$PKG_FILE"
}

# Fetch latest tag from GitHub API
LATEST_TAG=$(curl -s https://api.github.com/repos/bornova/numara-calculator/releases/latest | jq -r .tag_name)
if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" == "null" ]; then
    echo "Failed to fetch latest tag"
    exit 1
fi
LATEST_VERSION="${LATEST_TAG#v}"  # remove leading 'v' if present

CURRENT_VERSION=$(get_current_version)
echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
    echo "Already up to date."
    exit 0
fi

echo "Updating to version $LATEST_VERSION"

# Update the version in the package file
sed -i "s/version = \".*\";/version = \"$LATEST_VERSION\";/" "$PKG_FILE"

# Compute new source hash using nix-prefetch-git
# The 'rev' is the tag name (e.g., "v7.4.1")
NEW_SRC_HASH=$(nix-prefetch-git --url https://github.com/bornova/numara-calculator --rev "$LATEST_TAG" --fetch-submodules | jq -r .sha256)
# Convert to SRI format (nix-prefetch-git gives base64? Actually it gives a hash that can be used directly in fetchFromGitHub if prefixed with sha256-)
# We need to use the format "sha256-<base64>" - but nix-prefetch-git outputs a base64 hash without prefix.
# So we prepend "sha256-"
NEW_SRC_HASH="sha256-${NEW_SRC_HASH}"
echo "New source hash: $NEW_SRC_HASH"

# Update the src hash in the package file
sed -i "s|hash = \"sha256-.*\";|hash = \"$NEW_SRC_HASH\";|" "$PKG_FILE"

# Now update npmDepsHash
# We'll set a dummy value and run the build to get the correct hash
DUMMY_HASH="sha256-0000000000000000000000000000000000000000000000000000"
sed -i "s|npmDepsHash = \"sha256-.*\";|npmDepsHash = \"$DUMMY_HASH\";|" "$PKG_FILE"

# Build the package with the dummy hash – the build will fail and print the correct hash.
# We capture the error output and extract the hash.
# The error message looks like: "error: hash mismatch in fixed-output derivation ..."
# We'll run nix-build in a subshell and capture stderr.
set +e
BUILD_OUTPUT=$(nix-build -E "with import <nixpkgs> {}; callPackage ./pkgs/numara.nix {}" 2>&1)
BUILD_EXIT=$?
set -e

if [ $BUILD_EXIT -eq 0 ]; then
    echo "Build succeeded unexpectedly – no hash mismatch?"
    exit 1
fi

# Extract the correct npmDepsHash from the error message.
# The message contains something like: "got: sha256-ABCD... expected: sha256-..."
# We want the 'got' hash.
CORRECT_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got:\s+\Ksha256-[a-zA-Z0-9+/=]+' | head -1)
if [ -z "$CORRECT_HASH" ]; then
    echo "Could not extract correct npmDepsHash from build output:"
    echo "$BUILD_OUTPUT"
    exit 1
fi

echo "Correct npmDepsHash: $CORRECT_HASH"
# Update the npmDepsHash in the file
sed -i "s|npmDepsHash = \"sha256-.*\";|npmDepsHash = \"$CORRECT_HASH\";|" "$PKG_FILE"

# Ensure the package builds now
nix-build -E "with import <nixpkgs> {}; callPackage ./pkgs/numara.nix {}" --no-out-link

echo "Update completed successfully. Version: $LATEST_VERSION"
