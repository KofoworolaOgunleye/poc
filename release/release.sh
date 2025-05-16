#!/bin/bash
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
CHANGELOG="CHANGELOG.md"
VERSION_FILE="VERSION"
DRY_RUN=false 

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          Oak Terraform Modules Release Tool        ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"


usage() {
  cat <<EOF
Usage: $0 <version> [--dry-run]

Arguments:
  version    SemVer string (X.Y.Z)

Flags:
  --dry-run  Show commands without executing
EOF
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

VERSION="$1"
TAG="v$VERSION"
shift

run_or_dry() {
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

echo -e "${BLUE}Step 1: Running pre-release checks${NC}"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  error "Version must be in X.Y.Z format"
fi
ok "Version format OK: $VERSION"


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

if git rev-parse "$TAG" >/dev/null 2>&1; then
    error "Tag '$TAG' already exists"
  fi
  ok "Tag is available: $TAG"


echo -e "${BLUE}Step 2: Checking release type${NC}"

log "Auto-generating changelog with conventional-changelog"
run_or_dry "npx conventional-changelog -p angular -i $CHANGELOG -s -r 0"
ok "CHANGELOG.md updated"

log "Opening CHANGELOG.md to refine entries under '## [Unreleased]'"
${EDITOR:-vim} $CHANGELOG

log "Bump version in ${VERSION_FILE}"
run_or_dry "echo $VERSION > $VERSION_FILE"
ok "Version file updated"

log "Committing version and changelog"
run_or_dry "git add $CHANGELOG $VERSION_FILE"
run_or_dry "git commit -m \"chore(release): $VERSION\""
ok "Committed release changes"

log "Creating signed tag $TAG"
run_or_dry "git tag -s $TAG -m \"Release $VERSION\""
ok "Tag $TAG created"

cat <<EOF

${GREEN}Release complete! Run the following command${NC}

Next:
 1. Push commits & tag:
      git push origin main $TAG
 2. Open GitHub Release page:
      ${REPO_URL}/releases/new?tag=${TAG}

EOF





# Determine the type of version change
LAST_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
if [ "$LAST_VERSION" == "0.0.0" ]; then
  RELEASE_TYPE="Initial release"
else
  LAST_VERSION_CLEAN=${LAST_VERSION#v}
  LAST_MAJOR=$(echo $LAST_VERSION_CLEAN | cut -d. -f1)
  LAST_MINOR=$(echo $LAST_VERSION_CLEAN | cut -d. -f2)
  LAST_PATCH=$(echo $LAST_VERSION_CLEAN | cut -d. -f3 | cut -d- -f1)

  CURRENT_MAJOR=$(echo $VERSION | cut -d. -f1)
  CURRENT_MINOR=$(echo $VERSION | cut -d. -f2)
  CURRENT_PATCH=$(echo $VERSION | cut -d. -f3 | cut -d- -f1)

  if [ "$CURRENT_MAJOR" -gt "$LAST_MAJOR" ]; then
    RELEASE_TYPE="Major version upgrade"
  elif [ "$CURRENT_MINOR" -gt "$LAST_MINOR" ]; then
    RELEASE_TYPE="Minor version upgrade"
  else
    RELEASE_TYPE="Patch release"
  fi

  if [[ $VERSION == *"-"* ]]; then
    RELEASE_TYPE="$RELEASE_TYPE (Pre-release)"
  fi
fi

echo -e "${GREEN}Release type: $RELEASE_TYPE${NC}"
echo -e "Upgrading from $LAST_VERSION to $TAG"

echo -e "${BLUE}Step 3: Updating CHANGELOG.md${NC}"

# Check if CHANGELOG.md exists
if [ ! -f "CHANGELOG.md" ]; then
  echo -e "${RED}:x: Error: CHANGELOG.md not found${NC}"
  exit 1
fi

# Check if the Unreleased section exists
if ! grep -q "\[Unreleased\]" CHANGELOG.md; then
  echo -e "${RED}:x: Error: [Unreleased] section not found in CHANGELOG.md${NC}"
  exit 1
fi

# Check if there are actually changes in the Unreleased section
UNRELEASED_CONTENT=$(sed -n '/## \[Unreleased\]/,/## \[[0-9]\+\.[0-9]\+\.[0-9]\+/p' CHANGELOG.md | grep -v "## \[")
if [ -z "$(echo "$UNRELEASED_CONTENT" | grep -v '^)" ]; then
  echo -e "${YELLOW}:warning:  Warning: No changes found in [Unreleased] section${NC}"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please add your changes to the CHANGELOG.md under the [Unreleased] section before creating a release"
    exit 1
  fi
fi

# Update CHANGELOG.md - convert Unreleased to version
today=$(date +%Y-%m-%d)
sed -i "s/## \[Unreleased\]/## \[Unreleased\]\n\n## \[$VERSION\] - $today/g" CHANGELOG.md
echo -e "${GREEN}:white_check_mark: Added version [$VERSION] dated $today to CHANGELOG.md${NC}"

# Update link reference at bottom of CHANGELOG.md
if [ -n "$LAST_VERSION" ] && [ "$LAST_VERSION" != "0.0.0" ]; then
  # Update previous version comparison link
  sed -i "s|\[Unreleased\]:.*|[Unreleased]: https://github.com/your-org/oak-terraform-modules/compare/$TAG...HEAD|g" CHANGELOG.md
  # Add new version comparison link
  if ! grep -q "\[$VERSION\]:" CHANGELOG.md; then
    sed -i "/\[Unreleased\]:/a [${VERSION}]: https://github.com/your-org/oak-terraform-modules/compare/${LAST_VERSION}...${TAG}" CHANGELOG.md
  fi
else
  # This is the first release
  sed -i "s|\[Unreleased\]:.*|[Unreleased]: https://github.com/your-org/oak-terraform-modules/compare/$TAG...HEAD|g" CHANGELOG.md
  if ! grep -q "\[$VERSION\]:" CHANGELOG.md; then
    sed -i "/\[Unreleased\]:/a [${VERSION}]: https://github.com/your-org/oak-terraform-modules/releases/tag/${TAG}" CHANGELOG.md
  fi
fi
echo -e "${GREEN}:white_check_mark: Updated version links in CHANGELOG.md${NC}"

# Open changelog for editing to finalize release notes
echo -e "${BLUE}Step 4: Opening CHANGELOG.md for final review${NC}"
echo -e "${YELLOW}Please review and save the file when done.${NC}"
${EDITOR:-vim} CHANGELOG.md

echo -e "${BLUE}Step 5: Creating release commit and tag${NC}"

# Commit changes
git add CHANGELOG.md
git commit -m "Prepare release $TAG"
echo -e "${GREEN}:white_check_mark: Committed CHANGELOG.md changes${NC}"

# Create signed tag
echo -e "Creating signed tag $TAG..."
git tag -s "$TAG" -m "Release $TAG"
echo -e "${GREEN}:white_check_mark: Created signed tag $TAG${NC}"

# Generate release notes for GitHub Release
echo -e "${BLUE}Step 6: Generating GitHub release notes${NC}"
RELEASE_NOTES=$(sed -n "/## \[$VERSION\]/,/## \[/p" CHANGELOG.md | grep -v "## \[" | sed '/^$/N;/^\n$/D')

# Create release notes file for GitHub Release
echo "$RELEASE_NOTES" > release_notes.txt
echo -e "${GREEN}:white_check_mark: Generated release notes in release_notes.txt${NC}"

echo -e "${BLUE}Release preparation completed${NC}"
echo -e "${GREEN}:white_check_mark: CHANGELOG.md updated${NC}"
echo -e "${GREEN}:white_check_mark: Changes committed${NC}"
echo -e "${GREEN}:white_check_mark: Tag $TAG created${NC}"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Push changes and tag with: ${GREEN}git push origin main $TAG${NC}"
echo -e "2. Create a GitHub Release at:"
echo -e "   ${GREEN}https://github.com/your-org/oak-terraform-modules/releases/new?tag=$TAG${NC}"
echo -e "3. Upload the generated release_notes.txt or copy its contents"

echo -e "\n${BLUE}Would you like to push changes now? (y/n)${NC} "
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Pushing to origin..."
  git push origin main "$TAG"
  echo -e "${GREEN}:white_check_mark: Changes pushed!${NC}"

  echo -e "\n${YELLOW}Remember to create the GitHub Release manually:${NC}"
  echo -e "https://github.com/your-org/oak-terraform-modules/releases/new?tag=$TAG"
fi