#!/usr/bin/env bash
# scripts/plan-all.sh
#
# Run terraform plan for every root configuration in the project, writing
# each plan to a local file. No terraform apply is performed.
#
# The plans use -backend=false so they can run without the remote state
# bucket existing yet. This is useful for reviewing what each example would
# create before bootstrapping the state infrastructure.
#
# Outputs (one per configuration, in the project root):
#   plans/<config>.plan   - binary plan file
#   plans/<config>.txt    - human-readable plan text
#
# Usage:
#   ./scripts/plan-all.sh             # generate plans for all configs
#   terraform show plans/vpc.plan     # inspect a single plan
#
# Important:
#   - This script does NOT apply anything.
#   - Plans are generated WITHOUT a real backend, so they may not reflect
#     the exact remote state behavior. After bootstrapping the state
#     bucket, run `terraform plan` in each directory for the real plan.
#   - Plans reference real AWS resources. Review each plan before applying
#     in a real account.

set -euo pipefail

TERRAFORM="terraform"
PLAN_DIR="plans"
CONFIGS=(
  "examples/vpc"
  "examples/ec2"
  "bootstrap/terraform-state"
  "apps/infrastructure-lab"
  "apps/containerized-api"
)

header() {
  echo ""
  echo "======================================================================"
  echo " $1"
  echo "======================================================================"
}

mkdir -p "${PLAN_DIR}"

if [ ! -d "${PLAN_DIR}" ]; then
  echo "ERROR: ${PLAN_DIR} directory missing and could not be created." >&2
  exit 1
fi

echo "Generating Terraform plans for all root configurations"
echo "terraform: $(${TERRAFORM} version | head -1)"
echo "Plans will be written to: ${PLAN_DIR}/"
echo ""

for dir in "${CONFIGS[@]}"; do
  name="$(basename "${dir}")"
  header "Planning ${dir}"

  if [ ! -d "${dir}" ]; then
    echo "  SKIP - directory does not exist: ${dir}"
    continue
  fi

  if [ ! -f "${dir}/main.tf" ] && [ ! -f "${dir}/variables.tf" ]; then
    echo "  SKIP - does not look like a Terraform configuration: ${dir}"
    continue
  fi

  pushd "${dir}" > /dev/null

  echo "  -> terraform init -backend=false"
  if ! ${TERRAFORM} init -backend=false > /dev/null 2>&1; then
    echo "  ERROR: terraform init failed for ${dir}"
    popd > /dev/null
    continue
  fi

  echo "  -> terraform plan -out=${PLAN_DIR}/${name}.plan"
  if ${TERRAFORM} plan -out="${PLAN_DIR}/${name}.plan" > /tmp/tf-plan-${name}.log 2>&1; then
    echo "  -> terraform show -no-color ${PLAN_DIR}/${name}.plan > ${PLAN_DIR}/${name}.txt"
    ${TERRAFORM} show -no-color "${PLAN_DIR}/${name}.plan" > "${PLAN_DIR}/${name}.txt" 2>&1
    echo "  Plan written: ${PLAN_DIR}/${name}.plan (${PLAN_DIR}/${name}.txt)"
  else
    echo "  WARNING: plan failed for ${dir} (may need variables)"
    echo "  See: /tmp/tf-plan-${name}.log"
    echo "  Copied log to: ${PLAN_DIR}/${name}.txt (error output)"
    mkdir -p "${PLAN_DIR}" 2>&1 || true
    cp /tmp/tf-plan-${name}.log "${PLAN_DIR}/${name}.txt" 2>&1 || true
  fi

      popd > /dev/null
done

PLAN_DIR="plans"

echo ""
header "Plan summary"




echo "Generated plans:"
  for plan in "${PLAN_DIR}"/*.plan; do
  if [ -f "${plan}" ]; then
    name="$(basename "${plan}" .plan)"
    txt="${PLAN_DIR}/${name}.txt"
    if [ -f "${txt}" ]; then
      size_txt="$(stat -c%s "${txt}" 2>/dev/null || echo '?')"
      echo "  - ${name}.plan  ($(stat -c%s "${plan}" 2>/dev/null || echo '?') bytes, ${size_txt} bytes text)"
    else
      echo "  - ${name}.plan  ($(stat -c%s "${plan}" 2>/dev/null || echo '?') bytes)"
    fi
  fi
done

echo ""
echo "DEBUG after summary loop — files in ${PLAN_DIR}:"
ls -la "${PLAN_DIR}" 2>&1 || true

echo ""
echo "To inspect a plan:"
echo "    terraform show plans/<name>.plan"
echo ""
echo "To clean up plans:"
echo "    rm -rf plans/"
