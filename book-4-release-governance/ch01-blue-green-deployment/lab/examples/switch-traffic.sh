#!/usr/bin/env bash
# switch-traffic.sh
# Automates the blue-green traffic switch sequence for the lab exercise.
# Performs: smoke test → traffic switch → verify → optional cleanup.
#
# Usage:
#   ./switch-traffic.sh --target green           # Switch to green
#   ./switch-traffic.sh --target blue            # Rollback to blue
#   ./switch-traffic.sh --target green --dry-run # Preview without applying
#   ./switch-traffic.sh --cleanup                # Delete blue after confirming green is stable

set -euo pipefail

# ---------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------
TARGET_VERSION=""
DRY_RUN=false
CLEANUP=false
SERVICE_NAME="webapp"
NAMESPACE="default"
PORT_FORWARD_PORT=8080

# ---------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET_VERSION="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --cleanup)
      CLEANUP=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 --target <blue|green> [--dry-run] [--cleanup]"
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------
log() { echo "[$(date -u +%H:%M:%S)] $*"; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

check_prerequisites() {
  for cmd in kubectl curl; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd"
  done
}

get_active_version() {
  kubectl get service "$SERVICE_NAME" \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown"
}

run_smoke_tests() {
  local target="$1"
  log "Running smoke tests against deployment/webapp-${target} ..."

  # Start port-forward to the target deployment directly (bypasses the service)
  kubectl port-forward \
    "deployment/webapp-${target}" \
    "${PORT_FORWARD_PORT}:80" \
    -n "$NAMESPACE" \
    >/dev/null 2>&1 &
  PF_PID=$!
  sleep 2

  local all_passed=true

  # Health check
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://localhost:${PORT_FORWARD_PORT}/healthz" 2>/dev/null || echo "000")
  if [[ "$HTTP_CODE" == "200" ]]; then
    log "  PASS: Health check returned HTTP 200"
  else
    log "  FAIL: Health check returned HTTP ${HTTP_CODE}"
    all_passed=false
  fi

  # Version check
  CONTENT=$(curl -s "http://localhost:${PORT_FORWARD_PORT}/" 2>/dev/null || echo "")
  if echo "$CONTENT" | grep -q "$target"; then
    log "  PASS: Version label '${target}' present in response"
  else
    log "  FAIL: Version label '${target}' not found in response"
    all_passed=false
  fi

  kill "$PF_PID" 2>/dev/null || true

  if [[ "$all_passed" == "false" ]]; then
    fail "Smoke tests failed for ${target}. Aborting traffic switch."
  fi

  log "All smoke tests passed for ${target}."
}

switch_traffic() {
  local target="$1"
  log "Switching traffic to ${target} ..."

  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY RUN] Would run: kubectl patch service ${SERVICE_NAME} -p '{\"spec\":{\"selector\":{\"version\":\"${target}\"}}}'"
    return
  fi

  kubectl patch service "$SERVICE_NAME" \
    -n "$NAMESPACE" \
    -p "{\"spec\":{\"selector\":{\"version\":\"${target}\"}}}"

  sleep 1

  ACTIVE=$(get_active_version)
  if [[ "$ACTIVE" == "$target" ]]; then
    log "Traffic switch confirmed. Active version: ${ACTIVE}"
  else
    fail "Traffic switch verification failed. Expected ${target}, got ${ACTIVE}."
  fi
}

verify_live_traffic() {
  local target="$1"
  log "Verifying live traffic is serving ${target} ..."

  kubectl port-forward \
    "service/${SERVICE_NAME}" \
    "${PORT_FORWARD_PORT}:80" \
    -n "$NAMESPACE" \
    >/dev/null 2>&1 &
  PF_PID=$!
  sleep 2

  CONTENT=$(curl -s "http://localhost:${PORT_FORWARD_PORT}/" 2>/dev/null || echo "")
  kill "$PF_PID" 2>/dev/null || true

  if echo "$CONTENT" | grep -q "$target"; then
    log "  PASS: Service is serving traffic from ${target}"
  else
    fail "  FAIL: Service traffic verification failed for ${target}. Content: ${CONTENT}"
  fi
}

cleanup_old_version() {
  local old_version="$1"
  log "Cleaning up old deployment: webapp-${old_version}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY RUN] Would delete: deployment/webapp-${old_version}, configmap/webapp-${old_version}-content"
    return
  fi

  kubectl delete deployment "webapp-${old_version}" -n "$NAMESPACE" --ignore-not-found
  kubectl delete configmap "webapp-${old_version}-content" -n "$NAMESPACE" --ignore-not-found
  log "Cleanup complete."
}

# ---------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------
check_prerequisites

CURRENT=$(get_active_version)
log "Current active version: ${CURRENT}"

if [[ "$CLEANUP" == "true" ]]; then
  # Determine which version to clean up (the inactive one)
  if [[ "$CURRENT" == "green" ]]; then
    INACTIVE="blue"
  else
    INACTIVE="green"
  fi
  log "Preparing to clean up inactive version: ${INACTIVE}"
  cleanup_old_version "$INACTIVE"
  exit 0
fi

if [[ -z "$TARGET_VERSION" ]]; then
  fail "No --target specified. Use --target blue or --target green."
fi

if [[ "$TARGET_VERSION" != "blue" && "$TARGET_VERSION" != "green" ]]; then
  fail "Invalid target: ${TARGET_VERSION}. Must be 'blue' or 'green'."
fi

if [[ "$CURRENT" == "$TARGET_VERSION" ]]; then
  log "Service is already routing to ${TARGET_VERSION}. No action required."
  exit 0
fi

# Full switch sequence
run_smoke_tests "$TARGET_VERSION"
switch_traffic "$TARGET_VERSION"

if [[ "$DRY_RUN" == "false" ]]; then
  verify_live_traffic "$TARGET_VERSION"
fi

log "Blue-green switch complete. Active version: ${TARGET_VERSION}"
log "To rollback: $0 --target ${CURRENT}"
log "To clean up old version after monitoring period: $0 --cleanup"
