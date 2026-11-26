#!/usr/bin/env bash
# scripts/fmt-check.sh
#
# Check that all Terraform files in the project are formatted correctly.
#
# Equivalent to the CI check (pr-validation.yml / push-validation.yml):
#   terraform fmt -check -recursive
#
# This does NOT modify any files. It only reports differences.
#
# Usage:
#   ./scripts/fmt-check.sh            # check only
#   ./scripts/fmt-check.sh --fix      # rewrite files in place (local only)
#
# Exit codes:
#   0 - all files are formatted correctly
#   1 - some files differ from the canonical formatting

set -euo pipefail

FIX=false
if [ "${1:-}" = "--fix" ]; then
  FIX=true
fi

if [ "${FIX}" = true ]; then
  echo "Formatting all Terraform files in place (local only, not for CI)."
  terraform fmt -recursive
  echo "Done."
else
  echo "Checking Terraform formatting (read-only)."
  if terraform fmt -check -recursive; then
    echo "All files are formatted correctly."
    exit 0
  else
    echo ""
    echo "The following files differ from canonical formatting:"
    terraform fmt -check -recursive 2>&1 | sed 's/^/  /'
    echo ""
    echo "To fix locally, run: ./scripts/fmt-check.sh --fix"
    echo "To see a diff, run: terraform fmt -recursive -diff"
    exit 1
  fi
fi
