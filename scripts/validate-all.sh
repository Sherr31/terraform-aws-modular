#!/usr/bin/env bash
# scripts/validate-all.sh
#
# Validate every root Terraform configuration in the project without touching
# remote state.
#
# What it does:
#   1. terraform init -backend=false   (skip the remote backend so no
#      credentials or bucket name are needed)
#   2. terraform validate               (check configuration syntax and
#      internal consistency)
#
# This is the same check that runs in CI (pr-validation.yml /
# push-validation.yml) and is safe to run locally before pushing.
#
# Usage:
#   ./scripts/validate-all.sh
#
# Exit codes:
#   0 - all configurations are valid
#   1 - at least one configuration failed to validate

set -euo pipefail

# directories that own their own state (root configurations)
CONFIGS=(
  "examples/vpc"
  "examples/ec2"
  "bootstrap/terraform-state"
  "apps/infrastructure-lab"
  "apps/containerized-api"
)

TERRAFORM="terraform"
FAILED=0

header() {
  echo ""
  echo "======================================================================"
  echo " $1"
  echo "======================================================================"
}

check() {
  local dir="$1"
  header "Validating ${dir}"

  if [ ! -d "${dir}" ]; then
    echo "  SKIP - directory does not exist: ${dir}"
    return 0
  fi

  if [ ! -f "${dir}/main.tf" ] && [ ! -f "${dir}/variables.tf" ]; then
    echo "  SKIP - does not look like a Terraform configuration: ${dir}"
    return 0
  fi

  pushd "${dir}" > /dev/null

  echo "  -> terraform init -backend=false"
  if ! ${TERRAFORM} init -backend=false > /tmp/tf-init-${dir//\//-}.log 2>&1; then
    echo "  ERROR: terraform init failed for ${dir}"
    echo "  See: /tmp/tf-init-${dir//\//-}.log"
    FAILED=1
    popd > /dev/null
    return 1
  fi

  echo "  -> terraform validate"
  if ! ${TERRAFORM} validate > /tmp/tf-validate-${dir//\//-}.log 2>&1; then
    echo "  ERROR: terraform validate failed for ${dir}"
    echo "  See: /tmp/tf-validate-${dir//\//-}.log"
    echo "  Output:"
    sed 's/^/    /' /tmp/tf-validate-${dir//\//-}.log
    FAILED=1
  else
    echo "  OK"
  fi

  popd > /dev/null
}

echo "Validating all root Terraform configurations"
echo "terraform: $(${TERRAFORM} version | head -1)"
echo "Working directories are cleaned before and after each check."

for dir in "${CONFIGS[@]}"; do
  check "${dir}"
done

echo ""
echo "======================================================================"
if [ "${FAILED}" -eq 0 ]; then
  echo " All configurations validated successfully."
  echo "======================================================================"
  exit 0
else
  echo " Some configurations FAILED to validate. See errors above."
  echo "======================================================================"
  exit 1
fi
