#!/bin/bash

# Exit on any error
set -e

# Store current branch name
CURRENT_BRANCH=$(git branch --show-current)

# Store original git config
ORIGINAL_USER_NAME=$(git config user.name)
ORIGINAL_USER_EMAIL=$(git config user.email)

# Function to restore git config
restore_git_config() {
    echo "Restoring original git config..."
    git config --local user.name "$ORIGINAL_USER_NAME"
    git config --local user.email "$ORIGINAL_USER_EMAIL"
}

# Set trap to restore git config on script exit (success, error, or interrupt)
trap restore_git_config EXIT

# Set temporary git config
git config --local user.name "Clean History Script"
git config --local user.email "info@git-scm.com"

echo "Current branch: $CURRENT_BRANCH"

# Stash all changes including untracked files
echo "Stashing current changes..."
git stash push -u -m "before cleaning history"

# Check if clean-history branch exists and delete it if it does
if git show-ref --verify --quiet refs/heads/clean-history; then
    echo "Removing existing clean-history branch..."
    git branch -D clean-history
fi

# Create new clean-history branch from current branch
echo "Creating new clean-history branch..."
git checkout -b clean-history

# Merge the blinded branch if it exists
if git show-ref --verify --quiet refs/heads/blinded; then
    echo "Merging blinded branch into clean-history..."
    git merge blinded --no-commit --no-ff
    # Commit the merge
    echo "Committing merge..."
    git commit -m "Merge blinded branch into clean-history"
fi

# Get the hash of the first commit
FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD)

# Soft reset to the first commit
echo "Resetting to first commit..."
git reset --soft $FIRST_COMMIT

# Undo the first commit while keeping changes (equivalent to VSCode undo)
# This is done by resetting to before the first commit while keeping changes
echo "Undoing first commit while keeping changes..."
git update-ref -d HEAD

# Create new initial commit with all current changes
echo "Creating new clean commit..."
git add .
git commit -m "Clean initial state"


# Force push to remote and set upstream
echo "Force pushing to remote..."
git push -uf clean HEAD:main

echo "Success! Clean history has been pushed to clean/main"
git checkout $CURRENT_BRANCH
echo "To recover your stashed changes: git stash pop"