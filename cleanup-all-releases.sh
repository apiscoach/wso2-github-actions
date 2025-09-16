#!/bin/bash

# Clean Slate: Delete ALL releases and tags
# Usage: ./cleanup-all-releases.sh <repository> [--force]

set -e

# No colors for maximum compatibility
RED=''
GREEN=''
YELLOW=''
BLUE=''
NC=''

# Help function
show_help() {
    cat << EOF
${BLUE}GitHub Repository Clean Slate Script${NC}

${YELLOW}DESCRIPTION:${NC}
    Deletes ALL releases and tags from a GitHub repository.
    Perfect for cleaning up after infinite loops or starting fresh with a POC.

${YELLOW}USAGE:${NC}
    $0 <repository> [OPTIONS]

${YELLOW}ARGUMENTS:${NC}
    repository          GitHub repository in format 'owner/repo'

${YELLOW}OPTIONS:${NC}
    --force            Skip confirmation prompt and delete immediately
    -h, --help         Show this help message

${YELLOW}EXAMPLES:${NC}
    # Interactive deletion (with confirmation)
    $0 apiscoach/openweather

    # Force deletion (no confirmation)
    $0 apiscoach/openweather --force

    # Show help
    $0 --help

${YELLOW}REQUIREMENTS:${NC}
    - GitHub CLI (gh) must be installed and authenticated
    - Write access to the specified repository

${RED}WARNING:${NC}
    This script will permanently delete ALL releases and their associated tags.
    There is no way to recover them once deleted. Use with caution!

${GREEN}NOTES:${NC}
    - Useful for cleaning up after workflow loops that create many releases
    - Perfect for resetting POC repositories to a clean state
    - Deletes releases in order, showing progress for each one
    - Automatically deletes associated Git tags when deleting releases

EOF
}

# Parse arguments
REPOSITORY=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [[ -z "$REPOSITORY" ]]; then
                REPOSITORY="$1"
            else
                echo -e "${RED}Error: Multiple repositories specified${NC}"
                echo "Please provide only one repository"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$REPOSITORY" ]]; then
    echo -e "${RED}Error: Repository argument is required${NC}"
    echo ""
    show_help
    exit 1
fi

# Check if gh CLI is available and authenticated
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI is not authenticated${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Verify repository exists and is accessible
if ! gh repo view "$REPOSITORY" &> /dev/null; then
    echo -e "${RED}Error: Cannot access repository '$REPOSITORY'${NC}"
    echo "Please check the repository name and your permissions."
    exit 1
fi

echo -e "${BLUE}🗑️  Deleting ALL releases and tags from: $REPOSITORY${NC}"

# Get all releases
echo -e "${YELLOW}📥 Fetching releases...${NC}"
RELEASES=$(gh release list -R "$REPOSITORY" --limit 1000 --json tagName | jq -r '.[].tagName')

# Get all Git tags
echo -e "${YELLOW}📥 Fetching Git tags...${NC}"
TAGS=$(gh api "/repos/$REPOSITORY/git/refs/tags" --jq '.[].ref' | sed 's|refs/tags/||')

RELEASE_COUNT=0
if [[ -n "$RELEASES" && "$RELEASES" != "" ]]; then
    RELEASE_COUNT=$(echo "$RELEASES" | wc -l)
fi

TAG_COUNT=0
if [[ -n "$TAGS" && "$TAGS" != "" ]]; then
    TAG_COUNT=$(echo "$TAGS" | wc -l)
fi

echo -e "${BLUE}Found $RELEASE_COUNT releases and $TAG_COUNT tags${NC}"

if [[ $RELEASE_COUNT -eq 0 && $TAG_COUNT -eq 0 ]]; then
    echo -e "${GREEN}✅ No releases or tags found - repository is already clean!${NC}"
    exit 0
fi

if [[ "$FORCE" != true ]]; then
    echo ""
    echo -e "${RED}⚠️  WARNING: This will DELETE ALL releases and tags permanently!${NC}"
    if [[ $RELEASE_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}Releases to be deleted:${NC}"
        echo "$RELEASES" | sed 's/^/   - /'
    fi
    if [[ $TAG_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}Tags to be deleted:${NC}"
        echo "$TAGS" | sed 's/^/   - /'
    fi
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cancelled by user${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}🚀 Starting cleanup...${NC}"

RELEASE_SUCCESS=0
TAG_SUCCESS=0
FAILED=0

# Delete releases first
if [[ $RELEASE_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}Deleting releases...${NC}"
    while IFS= read -r tag; do
        if [[ -n "$tag" ]]; then
            echo -n "Deleting release $tag... "
            if gh release delete "$tag" -R "$REPOSITORY" --yes &> /dev/null; then
                echo -e "${GREEN}✅${NC}"
                ((RELEASE_SUCCESS++))
            else
                echo -e "${RED}❌${NC}"
                ((FAILED++))
            fi
        fi
    done <<< "$RELEASES"
fi

# Delete all Git tags (including orphaned ones)
if [[ $TAG_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}Deleting Git tags...${NC}"
    while IFS= read -r tag; do
        if [[ -n "$tag" ]]; then
            echo -n "Deleting tag $tag... "
            if gh api -X DELETE "/repos/$REPOSITORY/git/refs/tags/$tag" &> /dev/null; then
                echo -e "${GREEN}✅${NC}"
                ((TAG_SUCCESS++))
            else
                echo -e "${RED}❌${NC}"
                ((FAILED++))
            fi
        fi
    done <<< "$TAGS"
fi

echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "${GREEN}✅ Successfully deleted: $RELEASE_SUCCESS releases${NC}"
echo -e "${GREEN}✅ Successfully deleted: $TAG_SUCCESS tags${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}❌ Failed operations: $FAILED${NC}"
fi

TOTAL_SUCCESS=$((RELEASE_SUCCESS + TAG_SUCCESS))
if [[ $TOTAL_SUCCESS -gt 0 ]]; then
    echo -e "${GREEN}🎉 Repository cleanup completed!${NC}"
else
    echo -e "${YELLOW}ℹ️  Nothing was deleted${NC}"
fi