#!/usr/bin/env bash
# Script to assist with creating new releases for oak-terraform-modules

set -eo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${BLUE}➤ $1"; }
ok()    { echo -e "${GREEN}✔ $1"; }
error() { echo -e "${RED}✖ $1"; exit 1; }

REPO_URL="https://github.com/oaknational/oak-terraform-modules.git"

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          Oak Terraform Modules Release Tool        ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}Step 1: Running pre-release checks${NC}"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  error "Must run on 'main' branch. You are currently on '$CURRENT_BRANCH'"
fi
ok "On main branch"

if ! git diff-index --quiet HEAD --; then
    error "You have uncommitted changes. Please commit or stash them first"
fi
ok "Working directory clean, No uncommitted changes"

log "Pulling latest changes from origin/main"
git pull origin main || error "Failed to pull latest changes. Fix any conflicts before proceeding".
ok "Repo is up to date with origin/main"

log "Running standard-version"
npm ci
npm run release || error "standard-version failed"
ok "Version bump, changelog update, commit, and tag complete"

echo
NEW_VERSION=$(node -p "require('./package.json').version")
RELEASE_BRANCH="release/v${NEW_VERSION}"
log "Creating release branch ${RELEASE_BRANCH}"
git switch -c "$RELEASE_BRANCH" || error "Failed to create branch"
git reset --hard main
ok "Release branch created with bumped commit"

echo
log "Pushing release branch and tags"
git push -u origin "$RELEASE_BRANCH" --follow-tags || error "Failed to push tags or branch"
ok "Pushed release branch and tags"

echo
log "Creating Pull Request for release"
gh pr create --base main --head "$RELEASE_BRANCH" \
  --title "chore(release): v${NEW_VERSION}" \
  --body "This PR bumps the version to v${NEW_VERSION} and updates the changelog." || error "Failed to create PR"
ok "Pull Request created"
cat <<EOF

Release branch and PR prep complete!

Next:
 1. Review and merge the release PR into main (protected branch).
 2. After merge, CI will publish tags and create GitHub Release automatically.

EOF



# #!/bin/bash
# # Script to assist with creating new releases for oak-terraform-modules

# set -eo pipefail

# GREEN='\033[0;32m'
# RED='\033[0;31m'
# YELLOW='\033[0;33m'
# BLUE='\033[0;34m'
# NC='\033[0m'

# log()   { echo -e "${BLUE}➤ $1"; }
# ok()    { echo -e "${GREEN}✔ $1"; }
# error() { echo -e "${RED}✖ $1"; exit 1; }

# REPO_URL="https://github.com/oaknational/oak-terraform-modules.git"
# CHANGELOG="CHANGELOG.md"
# VERSION_FILE="VERSION"
# DRY_RUN=false 

# echo -e "${GREEN}"
# echo "╔════════════════════════════════════════════════════╗"
# echo "║          Oak Terraform Modules Release Tool        ║"
# echo "╚════════════════════════════════════════════════════╝"
# echo -e "${NC}"


# usage() {
#   cat <<EOF
# Usage: $0 <version> [--dry-run]

# Arguments:
#   version    SemVer string (X.Y.Z)

# Flags:
#   --dry-run  Show commands without executing
# EOF
#   exit 1
# }

# if [ $# -lt 1 ]; then
#   usage
# fi

# VERSION="$1"
# TAG="v$VERSION"
# shift

# run_or_dry() {
#   if [ "$DRY_RUN" = true ]; then
#     echo "[DRY-RUN] $*"
#   else
#     eval "$@"
#   fi
# }

# echo -e "${BLUE}Step 1: Running pre-release checks${NC}"

# if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
#   error "Version must be in X.Y.Z format"
# fi
# ok "Version format OK: $VERSION"


# echo -e "${BLUE}Step 1: Running pre-release checks${NC}"

# CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# if [ "$CURRENT_BRANCH" != "main" ]; then
#   error "Must run on 'main' branch. You are currently on '$CURRENT_BRANCH'"
# fi
# ok "On main branch"

# log "Pulling latest changes from origin/main"
# run_or_dry "git pull origin main" || error "Failed to pull latest changes. Fix any conflicts before proceeding."
# ok "Repo is up to date with origin/main"

# if ! git diff-index --quiet HEAD --; then
#     error "You have uncommitted changes. Please commit or stash them first"
# fi
# ok "Working directory clean, No uncommitted changes"

# if git rev-parse "$TAG" >/dev/null 2>&1 || git ls-remote --tags origin "$TAG" | grep -q "$TAG"; then 
#   error "Tag '$TAG' already exists locally or on remote"
# fi
# ok "Tag is available: $TAG"

# log "Creating tag $TAG"
# run_or_dry "git tag -a $TAG -m \"Release $VERSION\""
# ok "Tag $TAG created"

# echo -e "${BLUE}Step 2: Updating changelog and version${NC}"

# log "Auto-generating changelog with conventional-changelog"
# run_or_dry "npx conventional-changelog\
#   -p angular \
#   -i CHANGELOG.md \
#   -s \
#   -r 0 \
#   --tag-prefix 'v' \
#   --from-tag $(git ls-remote --tags origin | grep -v '{}' | tail -n1 | sed 's/.*\///') \
#   --to-tag HEAD"
# ok "CHANGELOG.md updated"

# log "Opening CHANGELOG.md to refine entries under '## [Unreleased]'"
# ${EDITOR:-vim} $CHANGELOG

# log "Bump version in ${VERSION_FILE}"
# run_or_dry "echo $VERSION > $VERSION_FILE"
# ok "Version file updated"

# log "Committing version and changelog"
# run_or_dry "git add $CHANGELOG $VERSION_FILE"
# run_or_dry "git commit -m \"chore(release): $VERSION\""
# ok "Committed release changes"

# cat <<EOF

# ${GREEN} Release complete! Run the following command ${NC}

# Next:
#  1. Push commits & tag:
#       git push origin main $TAG
#  2. Open GitHub Release page:
#       ${REPO_URL}/releases/new?tag=${TAG}

# EOF

# # if ! command -v gh >/dev/null 2>&1; then
# #   echo " GitHub CLI not found, please install manually. For mac, use: brew install gh. For others visit https://github.com/cli/cli#installation"
# # else
# #   echo "gh is installed."
# # fi

# # log "Pushing to GitHub and creating release"
# # run_or_dry "git push origin main $TAG"
# # run_or_dry "gh release create $TAG \
# #   --notes-file CHANGELOG.md \
# #   --title \"Release $VERSION\""
# # ok "GitHub Release $TAG published"

