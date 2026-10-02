# modulestf skills

Agent skills for reviewing and maintaining reusable Terraform modules, following the terraform-aws-modules conventions:

- `.agents/skills/terraform-module-pr-review`: reviews one GitHub pull request and renders a verdict and a comment.
- `.agents/skills/terraform-module-reviewer`: reviews a change and returns structured findings.
- `.agents/skills/terraform-module-maintainer`: creates, changes, fixes and upgrades modules.
- `.agents/skills/change-scope`: decides whether an addition belongs in the thing being changed.

This repository is a snapshot published for the pull request review workflow, which fetches it pinned by commit SHA. Links to the measured review fixtures point to a file that is not published here.
