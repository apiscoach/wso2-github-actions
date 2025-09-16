#!/bin/bash

# Clean Slate: Delete ALL workflow runs
# Usage: ./cleanup-workflow-runs.sh <repository> [--force]

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
GitHub Workflow Runs Clean Slate Script

DESCRIPTION:
    Deletes ALL workflow runs from a GitHub repository.
    Perfect for cleaning up after testing workflows or starting fresh with a POC.

USAGE:
    $0 <repository> [OPTIONS]

ARGUMENTS:
    repository          GitHub repository in format 'owner/repo'

OPTIONS:
    --force            Skip confirmation prompt and delete immediately
    -h, --help         Show this help message

EXAMPLES:
    # Interactive deletion (with confirmation)
    $0 apiscoach/openweather

    # Force deletion (no confirmation)
    $0 apiscoach/openweather --force

    # Show help
    $0 --help

REQUIREMENTS:
    - GitHub CLI (gh) must be installed and authenticated
    - Write access to the specified repository

WARNING:
    This script will permanently delete ALL workflow runs and their logs.
    There is no way to recover them once deleted. Use with caution!

NOTES:
    - Useful for cleaning up after workflow loops or testing
    - Perfect for resetting POC repositories to a clean state
    - Deletes runs from all workflows in the repository
    - Also deletes associated logs and artifacts

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
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [[ -z "$REPOSITORY" ]]; then
                REPOSITORY="$1"
            else
                echo "Error: Multiple repositories specified"
                echo "Please provide only one repository"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$REPOSITORY" ]]; then
    echo "Error: Repository argument is required"
    echo ""
    show_help
    exit 1
fi

# Check if gh CLI is available and authenticated
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "Error: GitHub CLI is not authenticated"
    echo "Please run: gh auth login"
    exit 1
fi

# Verify repository exists and is accessible
if ! gh repo view "$REPOSITORY" &> /dev/null; then
    echo "Error: Cannot access repository '$REPOSITORY'"
    echo "Please check the repository name and your permissions."
    exit 1
fi

echo "🗑️  Deleting ALL workflow runs from: $REPOSITORY"

# Get all workflow runs
echo "📥 Fetching workflow runs..."
RUNS=$(gh run list -R "$REPOSITORY" --limit 1000 --json databaseId --jq '.[].databaseId')

RUN_COUNT=0
if [[ -n "$RUNS" && "$RUNS" != "" ]]; then
    RUN_COUNT=$(echo "$RUNS" | wc -l)
fi

echo "Found $RUN_COUNT workflow runs"

if [[ $RUN_COUNT -eq 0 ]]; then
    echo "✅ No workflow runs found - repository is already clean!"
    exit 0
fi

if [[ "$FORCE" != true ]]; then
    echo ""
    echo "⚠️  WARNING: This will DELETE ALL workflow runs and their logs permanently!"
    echo "Total runs to delete: $RUN_COUNT"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled by user"
        exit 0
    fi
fi

echo ""
echo "🚀 Deleting all workflow runs..."

SUCCESS_COUNT=0
FAILED_COUNT=0
CURRENT=1

while IFS= read -r run_id; do
    if [[ -n "$run_id" ]]; then
        echo -n "[$CURRENT/$RUN_COUNT] Deleting run $run_id... "
        if gh run delete "$run_id" -R "$REPOSITORY" &> /dev/null; then
            echo "✅"
            ((SUCCESS_COUNT++))
        else
            echo "❌"
            ((FAILED_COUNT++))
        fi
        ((CURRENT++))
    fi
done <<< "$RUNS"

echo ""
echo "📋 Summary:"
echo "✅ Successfully deleted: $SUCCESS_COUNT workflow runs"
if [[ $FAILED_COUNT -gt 0 ]]; then
    echo "❌ Failed to delete: $FAILED_COUNT workflow runs"
fi

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo "🎉 Workflow runs cleanup completed!"
else
    echo "ℹ️  No workflow runs were deleted"
fi

echo ""
echo "Current workflow runs remaining:"
REMAINING=$(gh run list -R "$REPOSITORY" --limit 5 --json conclusion,status,workflowName,createdAt | jq -r '.[] | "\(.workflowName) - \(.status) (\(.createdAt))"')
if [[ -n "$REMAINING" ]]; then
    echo "$REMAINING"
else
    echo "None - repository is clean!"
fi