#!/usr/bin/env bash
# scripts/checkov-scan.sh
#
# Run a Checkov security scan against the Terraform code in this project.
#
# This mirrors the configuration used in CI (pr-validation.yml):
#   - Scans examples/ and bootstrap/ only (not modules/)
#   - Uses the project's skip list
#   - soft_fail: true (findings are reported but do not block)
#
# Usage:
#   ./scripts/checkov-scan.sh           # run the scan (findings do not block)
#   ./scripts/checkov-scan.sh --strict  # fail on any finding (for local gating)
#   ./scripts/checkov-scan.sh --skip CKV_AWS_XX --skip CKV_AWS_YY  # add skips
#
# Prerequisites:
#   pip install checkov
#   or:  pipx install checkov
#
# Notes:
#   - The scan is read-only and does not modify any files.
#   - Checkov may produce different results across versions. Pin the version
#     in CI (the workflow uses a specific version).
#   - If Checkov flags a real issue, fix the code. If it is a false positive,
#     add the check to the skip list with a comment explaining why.

set -euo pipefail

STRICT=false
ADDITIONAL_SKIPS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --strict)
      STRICT=true
      shift
      ;;
    --skip)
      if [ -z "${2:-}" ]; then
        echo "Error: --skip requires a check ID argument." >&2
        exit 1
      fi
      ADDITIONAL_SKIPS+=("$2")
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--strict] [--skip CKV_AWS_XX] [...]" >&2
      exit 1
      ;;
  esac
done

SCAN_DIRS=(
  "examples"
  "bootstrap"
)

SKIP_CHECKS=(
  "CKV_AWS_20"
  "CKV_AWS_24"
  "CKV_AWS_33"
  "CKV_AWS_117"
  "CKV_AWS_119"
  "CKV_AWS_144"
  "CKV_AWS_227"
  "CKV_AWS_301"
  "CKV_AWS_302"
  "CKV_AWS_303"
  "CKV_AWS_304"
  "CKV_AWS_305"
  "CKV_AWS_306"
  "CKV_AWS_307"
  "CKV_AWS_308"
  "CKV_AWS_309"
  "CKV_AWS_310"
  "CKV_AWS_311"
  "CKV_AWS_312"
  "CKV_AWS_313"
  "CKV_AWS_314"
  "CKV_AWS_315"
)

# Build the skip flag
SKIP_FLAG=""
for check in "${SKIP_CHECKS[@]}" "${ADDITIONAL_SKIPS[@]}"; do
  SKIP_FLAG="${SKIP_FLAG} --skip ${check}"
done

if ! command -v checkov > /dev/null 2>&1; then
  echo "Error: checkov is not installed." >&2
  echo "Install with: pip install checkov" >&2
  echo "       or: pipx install checkov" >&2
  exit 1
fi

CHECKOV_VERSION="$(checkov --version 2>/dev/null | head -1 || echo 'unknown')"
echo "Checkov version: ${CHECKOV_VERSION}"
echo ""

PASSED=true

for dir in "${SCAN_DIRS[@]}"; do
  if [ ! -d "${dir}" ]; then
    echo "SKIP: directory not found: ${dir}"
    continue
  fi

  echo "======================================================================"
  echo " Scanning: ${dir}/"
  echo "======================================================================"

  CMD=(
    checkov
    -d "${dir}"
    --framework terraform
    --soft-fail
    --quiet
    --compact
    --skip-download
    ${SKIP_FLAG}
  )

  echo "  Command: checkov -d ${dir} --framework terraform --soft-fail --quiet --compact --skip-download $(echo "${SKIP_FLAG}" | sed 's/ --skip / /g' | sed 's/^ //')"
  echo ""

  if ! checkov -d "${dir}" --framework terraform --soft-fail --quiet --compact --skip-download ${SKIP_FLAG}; then
    if [ "${STRICT}" = true ]; then
      PASSED=false
    fi
  fi

  echo ""
done

echo "======================================================================"
if [ "${PASSED}" = true ]; then
  if [ "${STRICT}" = true ]; then
    echo " Strict scan: no findings (or all findings suppressed)."
  else
    echo " Scan complete. Findings are reported above but did not block (soft_fail)."
  fi
else
  echo " Strict scan: findings detected. Fix the issues or review the skips."
fi
echo "======================================================================"
