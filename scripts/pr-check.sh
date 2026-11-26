#!/usr/bin/env bash
# scripts/pr-check.sh
#
# Run the checks that CI would run on a pull request, locally.
# Equivalent to: pr-validation.yml (format + validate + secrets + security scan).
#
# Usage:
#   ./scripts/pr-check.sh
#
# Exit codes:
#   0 - all checks pass
#   1 - at least one check fails
#
# This is a convenience wrapper. Each check can also be run individually:
#   ./scripts/fmt-check.sh
#   ./scripts/validate-all.sh
#   ./scripts/checkov-scan.sh

set -euo pipefail

FAILED=0

pass()  { echo "  PASS: $1"; }
fail()  { echo "  FAIL: $1"; FAILED=1; }

echo "======================================================================"
echo " Local PR check (what CI runs on a pull request)"
echo "======================================================================"
echo ""

echo "1/4  Terraform formatting"
if ./scripts/fmt-check.sh > /tmp/pr-fmt.log 2>&1; then
  pass "fmt-check"
else
  fail "fmt-check (see /tmp/pr-fmt.log)"
fi
echo ""

echo "2/4  Terraform validation"
if ./scripts/validate-all.sh > /tmp/pr-validate.log 2>&1; then
  pass "validate-all"
else
  fail "validate-all (see /tmp/pr-validate.log)"
fi
echo ""

echo "3/4  Secret scan"
if python3 -m gitleaks detect --source . --no-banner --verbose > /tmp/pr-secrets.log 2>&1; then
  pass "gitleaks"
else
  # gitleaks returns non-zero when findings exist; treat that as a failure
  fail "gitleaks (see /tmp/pr-secrets.log)"
fi
echo ""

echo "4/4  Security scan (Checkov)"
if ./scripts/checkov-scan.sh --strict > /tmp/pr-checkov.log 2>&1; then
  pass "checkov --strict"
else
  fail "checkov --strict (see /tmp/pr-checkov.log)"
fi
echo ""

echo "======================================================================"
if [ "${FAILED}" -eq 0 ]; then
  echo " All PR checks pass."
  echo "======================================================================"
  exit 0
else
  echo " Some PR checks failed. Review the logs above."
  echo "======================================================================"
  exit 1
fi
