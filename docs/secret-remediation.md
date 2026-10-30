# A secret was committed: detection and remediation

## Why the pipeline catches it

The `secret-scan` job runs Gitleaks on the **whole Git history** before anything is built or
published. A finding fails the job, and the image job depends on it, so nothing is released.
Secret values are masked in the logs (`--redact`).

## Demonstration (with a fake secret)

Never use a real secret, even for a demo.

```bash
git switch -c demo/fake-secret
# a random value with a name Gitleaks recognizes; it is not a real credential
echo "API_KEY=\"$(openssl rand -base64 24 | tr -d '/+=')\"" > demo-secret.env
git add demo-secret.env && git commit -m "demo: fake secret to test the scan"
git push -u origin demo/fake-secret
```

Open the pull request: the `Gitleaks` job must fail and the publish job must not run.
(GitHub's own push protection may block the push first. That is a second safety net and a fine
thing to show; use the pull request route if it lets the push through.)

Then clean up the branch **and** the history it created:

```bash
git switch main
git push origin --delete demo/fake-secret
git branch -D demo/fake-secret
```

After this the pipeline on `main` is green again, which is the second part of the demo.

## Real incident: remediation procedure

1. **Treat the secret as compromised, immediately.** Anyone who could read the repository
   (or a fork, a clone, a CI log) may already have it.
2. **Revoke and rotate it** at its source: delete the token, change the password, regenerate
   the key. This is the only step that really fixes the exposure.
3. **Check for abuse** in the service's audit or access logs, from the time of the commit.
4. **Remove it from Git history**, since deleting the file in a new commit leaves the secret
   in old commits. Use `git filter-repo` (or BFG Repo-Cleaner), then force-push, and ask
   everyone to re-clone. Note that this does not undo step 1: the secret stays burned.
5. **Invalidate caches:** CI caches, build artifacts, and published images that may contain it.
6. **Re-run the scan** on the cleaned history and confirm it passes.
7. **Find out why it happened** and add a guard: a `.gitignore` entry, a pre-commit hook
   running Gitleaks locally, a secret manager (Sealed Secrets or External Secrets) so secrets
   never sit in files.
8. **Write it up** (short blameless post-mortem) with the timeline and the prevention action.

## What not to do

- Do not silence the scan with an allowlist to make the pipeline green. An allowlist entry is
  only for a proven **false positive**, with a comment explaining why.
- Do not rely on deleting the file or force-pushing alone.
