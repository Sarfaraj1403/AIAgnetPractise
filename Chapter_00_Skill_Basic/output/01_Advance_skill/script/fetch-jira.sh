#!/usr/bin/env bash
# fetch-jira.sh - Fetch a JIRA ticket as JSON for the testplan-creator skill.
#
# Usage:
#   ./fetch-jira.sh JIRA-1234
#
# Required environment variables (never hardcode these in the script):
#   JIRA_BASE_URL   e.g. https://your-company.atlassian.net
#   JIRA_EMAIL      e.g. your-email@example.com
#   JIRA_API_TOKEN  your Atlassian API token

set -euo pipefail

ENV_FILE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/.env"
if [[ -f "$ENV_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# || "$line" =~ ^[[:space:]]*$ ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    value="${value%$'\r'}"
    case "$key" in
      JIRA_BASE_URL) : "${JIRA_BASE_URL:=$value}" ;;
      JIRA_EMAIL) : "${JIRA_EMAIL:=$value}" ;;
      JIRA_API_TOKEN) : "${JIRA_API_TOKEN:=$value}" ;;
    esac
  done < "$ENV_FILE"
fi
export JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <JIRA-KEY>   (e.g. $0 JIRA-1234)" >&2
  exit 1
fi

ISSUE_KEY="$1"

for var in JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: environment variable $var is not set." >&2
    exit 1
  fi
done

# Strip any trailing slash from the base URL
BASE_URL="${JIRA_BASE_URL%/}"

# --fail-with-body makes curl exit non-zero on HTTP errors (401, 404, ...)
# while still printing the error body so you can see what went wrong.
curl --silent --show-error --fail-with-body \
  --request GET \
  --url "${BASE_URL}/rest/api/3/issue/${ISSUE_KEY}" \
  --user "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  --header "Accept: application/json"