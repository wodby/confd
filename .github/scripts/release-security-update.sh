#!/usr/bin/env bash
# Merge a Dependabot security update that CI has passed, and release it as the
# next patch tag. Called by the "Release security updates" workflow with the
# repository, branch and commit of the CI run; DRY_RUN=1 only reports.
#
# It acts only on a pull request that Dependabot opened in this repository
# against the default branch, whose commits are all Dependabot's and which
# changes nothing but go.mod and go.sum. An update that moves the etcd client
# off the 3.6 line is left open with a comment, for review.
set -euo pipefail

: "${REPO:?}" "${HEAD_BRANCH:?}" "${HEAD_SHA:?}"
dry_run="${DRY_RUN:-0}"
dependabot="dependabot[bot]"
etcd_line="v3.6"
review_marker="<!-- release-security-updates: review -->"

# Leave a pull request open for review, with one explanatory comment.
request_review() {
  local number="${1}" reason="${2}"
  echo "Leaving #${number} for review: ${reason}"
  [[ "${dry_run}" == 1 ]] && return 0
  local comments
  comments=$(gh api --paginate "repos/${REPO}/issues/${number}/comments" --jq '.[].body')
  grep -qF "${review_marker}" <<<"${comments}" && return 0
  gh api "repos/${REPO}/issues/${number}/comments" --silent \
    -f body="${review_marker}
This update was not merged automatically: ${reason}. Review and merge it by hand, then publish a release tag."
}

# "module: old -> new" for each requirement a go.mod patch changes.
module_changes() {
  awk '
    /^[-+][[:space:]]/ {
      sign = substr($0, 1, 1)
      n = split(substr($0, 2), f, " ")
      if (n < 2 || f[2] !~ /^v[0-9]/) next
      if (sign == "-") { old[f[1]] = f[2] } else { new[f[1]] = f[2]; order[++k] = f[1] }
    }
    END {
      for (i = 1; i <= k; i++) {
        m = order[i]
        if (m in old) printf "- %s: %s -> %s\n", m, old[m], new[m]
        else printf "- %s: added at %s\n", m, new[m]
      }
    }'
}

default_branch=$(gh api "repos/${REPO}" --jq .default_branch)

# The pull request that CI passed on, matched by branch and exact head commit.
pr=$(gh api "repos/${REPO}/pulls?state=all&head=${REPO%%/*}:${HEAD_BRANCH}" |
  jq -c --arg sha "${HEAD_SHA}" '[.[] | select(.head.sha == $sha)] | first // empty')
if [[ -z "${pr}" ]]; then
  echo "No pull request from ${HEAD_BRANCH} at ${HEAD_SHA}; nothing to do."
  exit 0
fi

number=$(jq -r .number <<<"${pr}")
title=$(jq -r .title <<<"${pr}")
if [[ "$(jq -r .user.login <<<"${pr}")" != "${dependabot}" ||
  "$(jq -r .head.repo.full_name <<<"${pr}")" != "${REPO}" ||
  "$(jq -r .base.ref <<<"${pr}")" != "${default_branch}" ]]; then
  echo "#${number} is not a Dependabot pull request against ${default_branch}; nothing to do."
  exit 0
fi

if [[ "$(jq -r .state <<<"${pr}")" == open ]]; then
  files=$(gh api --paginate "repos/${REPO}/pulls/${number}/files" --jq '.[].filename')
  if grep -qvxE 'go\.(mod|sum)' <<<"${files}"; then
    request_review "${number}" "it changes files other than go.mod and go.sum"
    exit 0
  fi
  authors=$(gh api --paginate "repos/${REPO}/pulls/${number}/commits" --jq '.[].author.login // ""')
  if grep -qvxF "${dependabot}" <<<"${authors}"; then
    request_review "${number}" "it has commits that Dependabot did not make"
    exit 0
  fi
  gomod=$(gh api "repos/${REPO}/contents/go.mod?ref=${HEAD_SHA}" -H "Accept: application/vnd.github.raw")
  if ! grep -qE "^[[:space:]]*go\.etcd\.io/etcd/client/v3 ${etcd_line//./\\.}\.[0-9]+([[:space:]]|$)" <<<"${gomod}"; then
    request_review "${number}" "it moves the etcd client off ${etcd_line}"
    exit 0
  fi

  echo "Merging #${number}: ${title}"
  if [[ "${dry_run}" == 1 ]]; then
    echo "Dry run: would merge #${number} and tag it."
    exit 0
  fi
  gh pr merge "${number}" --repo "${REPO}" --squash --match-head-commit "${HEAD_SHA}"
  pr=$(gh api "repos/${REPO}/pulls/${number}")
fi

if [[ "$(jq -r '.merged_at != null' <<<"${pr}")" != true ]]; then
  echo "#${number} was closed without merging; nothing to do."
  exit 0
fi
merge_sha=$(jq -r .merge_commit_sha <<<"${pr}")

# The next patch after the newest vX.Y.Z tag. A rerun after a merge whose tag
# failed tags it now; a merge that a later tag already contains is released.
latest=$(gh api --paginate "repos/${REPO}/git/matching-refs/tags/v" --jq '.[].ref | ltrimstr("refs/tags/")' |
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
status=$(gh api "repos/${REPO}/compare/${latest}...${merge_sha}" --jq .status)
case "${status}" in
  ahead) ;;
  identical | behind)
    echo "${latest} already contains #${number}; nothing to release."
    exit 0 ;;
  *)
    echo >&2 "#${number} (${merge_sha}) has diverged from ${latest}; refusing to tag it."
    exit 1 ;;
esac
next="${latest%.*}.$((${latest##*.} + 1))"

changes=$(gh api --paginate "repos/${REPO}/pulls/${number}/files" --jq '.[] | select(.filename == "go.mod") | .patch' |
  module_changes)
message="${next}

Security update from #${number}: ${title}

${changes}"

echo "Tagging ${merge_sha} as ${next}"
echo "${message}"
if [[ "${dry_run}" == 1 ]]; then
  exit 0
fi
tag_sha=$(gh api "repos/${REPO}/git/tags" --jq .sha \
  -f tag="${next}" -f message="${message}" -f object="${merge_sha}" -f type=commit \
  -f 'tagger[name]=github-actions[bot]' \
  -f 'tagger[email]=41898282+github-actions[bot]@users.noreply.github.com' \
  -f "tagger[date]=$(date -u +%Y-%m-%dT%H:%M:%SZ)")
gh api "repos/${REPO}/git/refs" --silent -f ref="refs/tags/${next}" -f sha="${tag_sha}"
echo "Released ${next}."
