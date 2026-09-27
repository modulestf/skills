# Fixtures

> **Part of:** [terraform-module-reviewer](../SKILL.md)
> **Status:** dated evidence, not a reproducible run. See [What This File Is](#what-this-file-is) before using it to justify a rule change.

Eight real pull requests, seven against `terraform-aws-modules/terraform-aws-s3-bucket` and one against `terraform-aws-modules/terraform-aws-eks`, pinned to head SHAs, with what the skill emitted on them and what it should emit after the pending rule changes land. Three have the "main.tf plus a regenerated README region" shape. The other five are one each of an examples-only change, a docs-only change, a CI and tooling bump, a submodule-only change, and a revert. [Case 9](#case-9-pr-410-at-its-current-head) measures PR 410 again, at the head it moved to after a rebase.

## What This File Is

A skill run is a model run, not a deterministic command. Re-running the review on the same commit can produce a different list. This file therefore records what was observed on a stated date, not what will be observed again.

A later run that differs from the MEASURED-AT-HEAD column is a signal to investigate, not an automatic failure. The difference is reported as added and removed `{rule_id, file, severity}` triples, never as a count of findings, so the investigation starts from something specific.

Three things follow from that, and they are the whole protocol:

1. **Fetch by SHA, never by the pull request head reference.** That reference moves with every push and returns a different commit under the same name. Fetch the SHA recorded below, then assert the checked-out commit equals it.
2. **When the SHA is unreachable**, because the branch was deleted or the history rewritten, mark the case STALE and leave it. Never re-measure a case at a new SHA. Overwriting the measurement with whatever the skill does today is how a fixture stops being one.
3. **The two columns are different facts.** MEASURED-AT-HEAD is evidence and is frozen. EXPECTED-AFTER is a target and moves as work items ship. They diverge the moment the first rule change lands, and conflating them destroys the only record of what the skill used to do.

| Column | Contains | Updated |
|--------|----------|---------|
| MEASURED-AT-HEAD | What the unmodified skill emitted on the recorded date. | Never. |
| RE-MEASURED | What the skill as written on a later, stated date emitted at the same SHA, with every difference from MEASURED-AT-HEAD named. | Never, once written. A later measurement is a new dated section. |
| EXPECTED-AFTER | What the skill should emit once the named work items land. | As each item ships, naming the item beside each difference. |

## Comparison Rule

Two findings lists are compared as sets of `{rule_id, file, severity}` triples.

`line` is recorded per finding and excluded from the comparison. A rebase moves a line without changing the defect, and a fixture that fails on a rebase gets switched off. `id` and `summary` are also excluded: `id` is positional, and summary wording is not a contract.

Two findings with the same `rule_id`, `file` and `severity` at different lines are one triple. Where that matters, the lines are listed in the notes column.

## Provenance of the Measured Column

MEASURED-AT-HEAD was not produced by a fresh run for this file. It was assembled on 2026-09-22 from two earlier review runs over the same three commits, and every finding carried across was re-checked against the code at the recorded SHA before being written down. Findings that did not survive that check are in [Dropped Candidates](#dropped-candidates) with the reason.

Where a third pass disputed a finding from those runs, the dispute was resolved against the checkout, not by preferring one report over the other. The provider schema facts behind the Check B findings were re-fetched at 6.66.0 through the registry on the same date.

## Provenance of the Re-Measured Column

The column above was transcribed, not run. On 2026-09-24 each case was measured again by applying the skill end to end, and the result is recorded in its own RE-MEASURED section per case. The frozen column is left exactly as it was.

How the re-measurement was made:

- **Skill text.** `SKILL.md` as it stands at pofix-agent commit `c8648ec`. Its content last changed in `66a4452`; `6ba2f5e` only moved it to `.agents/skills`. Every check A to E and the Final Step were applied by reading the rule and then the diff. Several rule changes named under EXPECTED-AFTER had shipped by then (`pofix-agent-ut4`, `pofix-agent-9vi`, `pofix-agent-3lz`, `pofix-agent-8qu`, `pofix-agent-3c9`), and other Check C rules were added after 2026-09-22. This measures the skill as written on that date, not the unmodified skill that MEASURED-AT-HEAD describes. The unmodified skill cannot be re-run at a SHA it no longer matches.
- **Workspace.** No clone was made. The diff between the recorded base and the recorded head, and individual files at the head, were fetched through the GitHub REST API by SHA (the `compare` and `contents` endpoints). The `commits/<sha>` endpoint returned the recorded SHA for every case, and it stands in for asserting the checked-out commit. Nothing from the fetched repositories was run.
- **Provider schema.** From the Terraform registry tools only, never from memory: `hashicorp/aws` 6.66.0 (latest on the date), plus the declared floors 6.42.0 and 6.44.0 where a check compares versions. Every resource type a case touches was fetched, so no `review.check-not-run` was needed.
- **No Terraform command** was run, per Rule 1. A conclusion about whether an example plans is read from the files and the schema, and it is labelled that way.

A RE-MEASURED list is still a single model run applying rules that call for judgement. Where a rule's text could be read two ways, the reading taken is stated next to the triple. Candidates the reading did not reach are listed under each case, so a reviewer can dispute the reading rather than rediscover the candidate.

## Provenance of Cases 5 to 8

Cases 5 to 8 were added on 2026-09-24 and measured the way the re-measured column was, with these differences:

- **Skill text.** The reviewer as it stands at pofix-agent commit `f13ceaa`, before the Reverts paragraph of [Check A](check-a-compatibility.md) was added. Case 8 is also read against that paragraph, and the reading is stated in the case.
- **Workspace.** The GitHub REST `compare`, `contents` and `commits` endpoints, by SHA. `commits/<sha>` returned the recorded SHA for every head. Case 8 came from a search of merged pull requests in the `terraform-aws-modules` organization with "revert" in the title. It was the first result that reverts a grant the module produces, and the other results were not examined.
- **Provider schema.** Registry tools only: `hashicorp/aws` 6.66.0, the latest on the date, plus the declared floor each case names.
- **First measurement.** None of these cases has a MEASURED-AT-HEAD column. Its RE-MEASURED section is its frozen record, as for Case 4.

## Provenance of Case 9

Case 9 was added on 2026-09-24 and measured this way:

- **Skill text.** The reviewer as it stands at pofix-agent commit `8769264`: Checks A to F, the pass-through procedure of Check C, the generated-content rule of Check E after `pofix-agent-5zd` and pull request 25, [large-changes.md](large-changes.md) for the classification and the schema budget, and [quoted-claims.md](quoted-claims.md) for the conversation comment. The verdict is read off the ladder in the pull request review skill's `references/verdict.md` at the same commit.
- **Workspace.** No clone was made. The trees at the head, the base, and Case 1's head and base were fetched as GitHub REST `tarball` archives by SHA into a temporary directory outside this repository, and each archive's top directory names the requested SHA. The diff is the REST `compare` of the base against the head. `commits/<sha>` returned the recorded head, and `compare` returned the recorded base as the merge base. Nothing from the fetched repository was run.
- **Host prose.** The pull request's title, body and conversation comments were read through the REST `pulls` and `issues/<n>/comments` endpoints on the same date, as the pull request review skill would hand them over: the title as the release title, the body as a `body` item of origin `change-author`, the one conversation comment as a `conversation` item of origin `other`. The pull request had no review threads and no reviews. Host signals were not read, because the verdict does not reach the rungs that use them.
- **Provider schema.** Registry tools only. Latest `hashicorp/aws` was 6.66.0. Fetched on the date: `aws_s3files_file_system`, `aws_s3files_access_point` and `aws_s3files_synchronization_configuration` at 6.66.0, `aws_s3files_file_system` and `aws_s3files_synchronization_configuration` at 6.42.0, and the `aws_iam_policy_document` data source at 6.66.0. Every `.tf` file the change touches is byte for byte the file at Case 1's head `26cfa8c` (checked with `cmp`), so for the other types the facts are the registry fetches Case 1's re-measurement made on the same date, and they are cited, not recalled.
- **No Terraform command** was run, per Rule 1. A conclusion about whether an example or a precondition plans is read from the files and the schema, and it is labelled that way.

## Case 1: PR 410

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 410 |
| Head SHA | `26cfa8c815883fabecdc04f4e694de7e783868db` |
| Base | `d3a4f6203fe79299ffb790902944b1dcaa3711b6` |
| Task text | Review the diff `master..pr-410`. Release commit message: `feat: Add Amazon S3 Files support`. Profile `terraform-aws-modules`. |
| Shape | New submodule plus root passthrough. 61 files: `main.tf`, `variables.tf`, `outputs.tf`, 26 `versions.tf`, 20 `README.md`, 12 files under `wrappers/`, a new example. |
| Date of measurement | 2026-09-22 |
| State | LIVE. The recorded SHA still resolves. The pull request itself has moved on: on 2026-09-24 its head was `30cd3728d16cc5a1e1fa25d0d891015b6e4a0ada` on base `5dc2f1f89743ab935114b0b039bc88044a672ca2`, a rebase that diverged from the recorded SHA. Both measurements below are at the recorded SHA, not at the current head. A review of the current head is a new case: [Case 9](#case-9-pr-410-at-its-current-head). |

### MEASURED-AT-HEAD (PR 410)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `compat.version-constraint-raised` | `versions.tf` | CRITICAL | 7 | `>= 6.42` to `>= 6.44`. No `!` and no `BREAKING CHANGE:` trailer in the release message, so Check A's CRITICAL bullet applies. |
| `compat.version-constraint-raised` | `modules/account-public-access/versions.tf` | CRITICAL | 7 | Same bump. |
| `compat.version-constraint-raised` | `modules/notification/versions.tf` | CRITICAL | 7 | Same bump. |
| `compat.version-constraint-raised` | `modules/object/versions.tf` | CRITICAL | 7 | Same bump. |
| `compat.version-constraint-raised` | `modules/table-bucket/versions.tf` | CRITICAL | 7 | Same bump. |
| `compat.version-constraint-raised` | `modules/vectors/versions.tf` | CRITICAL | 7 | Same bump. |
| `profile.generated-content-handwritten` | 18 `README.md` files | HIGH | varies | Every changed README whose edit falls between `BEGIN_TF_DOCS` and `END_TF_DOCS`. File list below. |
| `profile.generated-content-handwritten` | 12 files under `wrappers/` | HIGH | varies | Check E's bullet names `wrappers/` outright, so every changed file there fires. File list below. |
| `coverage.attribute-not-output` | `modules/file-system/outputs.tf` | MEDIUM | null | `aws_s3files_synchronization_configuration` exports `latest_version_number` at 6.66.0. The submodule's outputs stop at `arn`, `id`, `name`, `status`. |
| `structure.argument-order` | `modules/file-system/main.tf` | LOW | 37, 437 | `tags` precedes `dynamic "timeouts"` in `aws_s3files_file_system.this` and in `aws_s3files_access_point.this`. One triple, two lines. |
| `examples.argument-undemonstrated` | `examples/file-system/main.tf` | LOW | null | The example sets the module block but no example sets `iam_role_policies`, `create_iam_role = false`, `accept_bucket_warning` or `security_group_egress_rules`. |

The six `compat.version-constraint-raised` triples were recorded under that name's pre-narrowing meaning, when it covered any raised version floor. `pofix-agent-9vi` narrowed the name on 2026-09-22, so a run after that date cannot produce them on a minor bump. The narrowing is written down in [findings-schema.md](findings-schema.md#recorded-exceptions).

Verdict at head: ladder rule 1, block.

READMEs firing Check E: `README.md`, `examples/account-public-access/README.md`, `examples/acl/README.md`, `examples/bucket-policies/README.md`, `examples/complete/README.md`, `examples/directory-bucket/README.md`, `examples/inventory-and-analytics/README.md`, `examples/notification/README.md`, `examples/object/README.md`, `examples/s3-replication/README.md`, `examples/table-bucket/README.md`, `examples/vectors/README.md`, `modules/account-public-access/README.md`, `modules/notification/README.md`, `modules/object/README.md`, `modules/table-bucket/README.md`, `modules/vectors/README.md`, `wrappers/file-system/README.md`.

Files under `wrappers/` firing Check E: `wrappers/main.tf`, `wrappers/versions.tf`, `wrappers/file-system/main.tf`, `wrappers/file-system/outputs.tf`, `wrappers/file-system/variables.tf`, `wrappers/file-system/versions.tf`, `wrappers/file-system/README.md`, `wrappers/account-public-access/versions.tf`, `wrappers/notification/versions.tf`, `wrappers/object/versions.tf`, `wrappers/table-bucket/versions.tf`, `wrappers/vectors/versions.tf`. `wrappers/file-system/README.md` is counted once, under this rule.

### RE-MEASURED 2026-09-24 (PR 410)

Diff `d3a4f6203fe79299ffb790902944b1dcaa3711b6...26cfa8c815883fabecdc04f4e694de7e783868db`, 61 files, merge base equal to the recorded base. Same task text as above.

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `examples.example-broken` | `examples/file-system/main.tf` | HIGH | 111 | Access point `reports` sets no `posix_user`. `aws_s3files_access_point` marks `posix_user` Required at 6.66.0, and the module renders it through a `dynamic` block over an optional input, so this access point renders zero `posix_user` blocks and cannot plan. Inferred from the files and the schema, not verified by execution. |
| `compat.provider-floor-raised` | `versions.tf` | LOW | 7 | 6.42 to 6.44. Every s3files argument the change uses is present at 6.42.0 (`aws_s3files_file_system` fetched at 6.42.0, 6.44.0 and 6.66.0; `aws_s3files_synchronization_configuration` at 6.44.0 and 6.66.0). |
| `compat.provider-floor-raised` | `modules/account-public-access/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/notification/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/object/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/table-bucket/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/vectors/versions.tf` | LOW | 7 | Same bump. |
| `coverage.optional-argument-unexposed` | `modules/file-system/main.tf` | MEDIUM | 138 | `max_session_duration` is Optional on `aws_iam_role` at 6.66.0. The new role neither exposes it nor documents the omission. The deprecated `inline_policy` and `managed_policy_arns` were not counted. |
| `coverage.attribute-not-output` | `modules/file-system/outputs.tf` | MEDIUM | null | `latest_version_number` on `aws_s3files_synchronization_configuration` has no output. |
| `structure.flag-polarity` | `modules/file-system/variables.tf` | MEDIUM | 335 | `create_policy` is a new `create_*` boolean defaulting to `false`. Literal reading of the Check C bullet. |
| `structure.comment-unsourced` | `modules/file-system/main.tf` | MEDIUM | 59, 78, 91, 219, 302, 551, 590 | New comments assert service behaviour with no source and no date: directory buckets unsupported, the role must reach the bucket for the file system's lifetime, AWS's own template scope, S3 Files managing its own EventBridge rule, the default security group fallback, allows being additive, AWS rejecting an empty policy. |
| `structure.comment-unsourced` | `main.tf` | MEDIUM | 1579 | `# S3 Files supports general purpose buckets only`, no source and no date. |
| `structure.comment-unsourced` | `examples/file-system/main.tf` | MEDIUM | 125 | "file data is always served from S3", no source and no date. |
| `structure.copied-content-unattributed` | `modules/file-system/main.tf` | MEDIUM | 153, 258 | The role's permissions document follows AWS's published inline policy, with condition keys and the `DO-NOT-DELETE-S3-Files*` rule name copied from it. The comment at 258 names the source URL but no date, and the convention asks for both. |
| `structure.copied-content-unattributed` | `examples/file-system/main.tf` | MEDIUM | 260, 285 | The literal service principal `lambda.amazonaws.com` and the `s3files:ClientRootAccess` statement carry no source and date. Literal reading: the bullet does not exclude examples. |
| `examples.feature-undemonstrated` | `examples/file-system/main.tf` | MEDIUM | null | `aws_iam_role_policy_attachment` and `aws_vpc_security_group_egress_rule` are new resources that no example creates: no example sets `iam_role_policies` or any egress rule. |
| `structure.argument-order` | `modules/file-system/main.tf` | LOW | 37, 437 | Unchanged from MEASURED-AT-HEAD. |
| `coverage.enum-value-unknown` | `examples/file-system/main.tf` | LOW | 76, 129 | `trigger = "ON_DIRECTORY_FIRST_ACCESS"`; the documented value set at 6.44.0 and 6.66.0 is `ON_FILE_ACCESS`. |
| `examples.argument-undemonstrated` | `examples/file-system/main.tf` | LOW | null | Attributes of `file_systems` no example sets, for example `accept_bucket_warning` and `iam_role_kms_key_arns`. |

Verdict at re-measurement: ladder rule 2, block, on `examples.example-broken`.

Check E is silent on every README and `wrappers/` file. Each changed row inside the documentation markers lines up with the change: provider version rows with the `versions.tf` bumps, input and output rows with the new variables and outputs, the six new lines in `wrappers/main.tf` with the six new root inputs, and `wrappers/file-system/` with the new submodule. The prose added outside the markers is not generated content. `structure.sibling-argument-omitted` is silent: every s3files resource and the security group resources set `region`, and the IAM resources have no `region` argument.

Difference from MEASURED-AT-HEAD, as `{rule_id, file, severity}` triples:

| Change | Triples | Why |
|--------|---------|-----|
| Removed | 30 `profile.generated-content-handwritten` HIGH | `pofix-agent-ut4` shipped: regenerated rows that match the change are not a finding. |
| Removed | 6 `compat.version-constraint-raised` CRITICAL | `pofix-agent-9vi` shipped. |
| Added | 6 `compat.provider-floor-raised` LOW, same files | `pofix-agent-9vi` shipped. |
| Added | `examples.example-broken` HIGH | Check D reached the missing `posix_user` through the example. The 2026-09-22 runs recorded the same defect only as a Check B candidate (see [Dropped Candidates](#dropped-candidates)). |
| Added | `coverage.enum-value-unknown` LOW | `pofix-agent-8qu` shipped. |
| Added | `coverage.optional-argument-unexposed` MEDIUM on `modules/file-system/main.tf` | The earlier runs did not fetch the `aws_iam_role` schema. A miss in the transcribed column, not a rule change. |
| Added | `structure.flag-polarity` MEDIUM | The bullet existed on 2026-09-22 and the earlier runs did not report it. A miss in the transcribed column. |
| Added | 3 `structure.comment-unsourced` MEDIUM, 2 `structure.copied-content-unattributed` MEDIUM | Check C rules added after 2026-09-22. |
| Added | `examples.feature-undemonstrated` MEDIUM | The earlier runs recorded the undemonstrated inputs only at LOW, and a new resource no example creates is the MEDIUM bullet. |
| Unchanged | `coverage.attribute-not-output` MEDIUM, `structure.argument-order` LOW, `examples.argument-undemonstrated` LOW | |

Not reported by this reading. Each is a place where EXPECTED-AFTER or an earlier candidate disagrees with the rule text as it stands:

- `structure.input-ignored-in-branch` on `iam_role_policies`, which EXPECTED-AFTER adds under `pofix-agent-3lz`. The switching input is `create_iam_role`, and the Check C bullet carves out `create_*` flags: "The module's own creation flag - `create`, `create_*` - is not the switching input". As written, the rule is silent here. Either the carve-out is narrowed to the module-wide flag, or EXPECTED-AFTER loses this row. Settled 2026-09-24 under `pofix-agent-dpk`: see [EXPECTED-AFTER (PR 410)](#expected-after-pr-410).
- `coverage.required-argument-unreachable` on `modules/file-system/main.tf:409`, which EXPECTED-AFTER adds under `pofix-agent-3lz`. The Check B bullet now says a value the caller supplies through an exposed input "is the normal shape and not a finding", and `posix_user` is an exposed input. The defect is reported once, as `examples.example-broken`. Settled 2026-09-24 under `pofix-agent-dpk`: see [EXPECTED-AFTER (PR 410)](#expected-after-pr-410).
- `structure.docs-contradict-code` on the root `README.md` note that "a read-only principal is also denied writes through its own access point". The file system policy grants only `s3files:ClientMount` to a read principal and writes no explicit deny for `s3files:ClientWrite` on its own access point, so whether writes are denied depends on the principal's identity policy. Left out because the conclusion rests on IAM evaluation outside the files.
- `structure.validation-missing` on `ip_address_type`, `trigger` and `ip_protocol`. Each passes straight to a provider argument, so a typo fails at plan against that argument rather than far from the input.
- `structure.comment-redundant` on short labels such as `# Allow each listed principal through its access point`. A judgement call, not reported.

### EXPECTED-AFTER (PR 410)

| Change | Item | Effect on the triples above |
|--------|------|-----------------------------|
| Check E stops firing on regenerated documentation and wrappers | `pofix-agent-ut4` | Removes all 30 `profile.generated-content-handwritten` triples. These are false positives: the READMEs and wrappers are tf-docs and wrapper-generator output regenerated alongside the code change. |
| Raising a provider floor by a minor version moves to its own rule | `pofix-agent-9vi` | Removes all 6 `compat.version-constraint-raised` CRITICAL triples and adds 6 `compat.provider-floor-raised` LOW triples on the same files. 6.42 to 6.44 is a minor, and `compat.version-constraint-raised` now covers only a core floor or a major crossing. Every s3files argument the change uses is present in the 6.42.0 schema, so the bump carries a provider fix and no new schema feature. The comparison unit is `{rule_id, file, severity}`, so this scores as 6 removals and 6 additions, and a run that still reports the old name here is a regression. |
| Check B's required-argument bullet keeps the caller-supplied exemption | `pofix-agent-dpk`, replacing the `pofix-agent-3lz` row | Adds nothing, and that is the assertion. This row used to add `coverage.required-argument-unreachable` on `modules/file-system/main.tf` at HIGH, line 409: `posix_user` is Required on `aws_s3files_access_point` and rendered through a `dynamic` block over an `optional(object(...))` input. Decided 2026-09-24: the row is dropped and the rule stays. An `optional()` attribute or a `dynamic` block feeding a Required block is the caller-supplied shape: the caller can set the value, and leaving it out fails at plan. The reading that counted such an input as unreachable matched nearly every optional nested block, which is why it was withdrawn. The defect is reported once, as `examples.example-broken` HIGH on `examples/file-system/main.tf:111`. |
| `coverage.enum-value-unknown` | `pofix-agent-8qu` | Adds a LOW triple on `examples/file-system/main.tf`. The example sets `trigger = "ON_DIRECTORY_FIRST_ACCESS"`; the documented value set at 6.66.0 is `ON_FILE_ACCESS` only. The rule asks rather than asserts, because the author applied this live and the documentation may lag. |
| `structure.input-ignored-in-branch` keys its `create_<x>` carve-out on the input's name | `pofix-agent-dpk`, replacing the `pofix-agent-3lz` row | Adds nothing, and that is the assertion. This row used to add a HIGH triple on `modules/file-system/main.tf`, line 252, where `aws_iam_role_policy_attachment.this` filters `iam_role_policies` on `local.create_iam_role`. Decided 2026-09-24: the carve-out is narrowed and the row is dropped. The old text exempted every `create_*` flag, which also excused a flag disabling an unrelated input. The new text exempts a `create_<x>` flag only for inputs whose name contains `<x>`, because such an input configures the thing the flag creates. `iam_role_policies` contains `iam_role`, so it stays exempt under both texts. The narrowed text adds no triple here: the access point grants that `create_policy` switches off are guarded by a precondition at `modules/file-system/main.tf:72`, so setting them without the flag raises an error. |
| `structure.passthrough-field-drift` | `pofix-agent-j81` | Adds a MEDIUM triple on `variables.tf`, line 850, at the recorded head `26cfa8c`. The root's `file_systems[*].mount_targets` object has no `security_groups` attribute, while `modules/file-system/variables.tf:183` declares `security_groups = optional(list(string), [])` in the same object and `modules/file-system/main.tf:276` reads it. No root caller can set security groups per mount target. MEDIUM: the attribute is optional in the submodule, so the capability is unreachable but nothing fails. |
| `structure.passthrough-default-drift` | `pofix-agent-j81` | Adds nothing at `26cfa8c`, and that is the assertion. Every forwarded field's unset value agrees between the root's `file_systems` type and the submodule's variables. `security_group_use_name_prefix` shows why the null rule matters: the root yields null from `optional(bool)`, and the submodule variable defaults to `true` with `nullable = false`, so Terraform substitutes `true` and the two sides agree. |
| `profile.unrelated-change-bundled` | `pofix-agent-j81` | Adds two LOW triples at `26cfa8c`: `modules/notification/main.tf`, line 1, where `data "aws_partition" "this"` gains a `count`, and `modules/table-bucket/main.tf`, line 32, where the policy statement's `resources` fallback changes at line 37. The title is `feat` and neither directory takes part in the feature: the change adds no block there, extends no variable type, and adds nothing that reads a new input. |
| Check D reaches the missing `posix_user` through the example | Shipped text, measured 2026-09-24 | Adds `examples.example-broken` on `examples/file-system/main.tf` at HIGH, line 111. It carries the block today. |
| `structure.sibling-argument-omitted` reads the provider schema before it counts siblings | `pofix-agent-3c9` | Adds nothing. The rule is silent on PR 410, and that is the assertion. Without the schema gate it fires HIGH three times in `modules/file-system/main.tf`, on `aws_iam_role` (138), `aws_iam_role_policy_attachment` (251) and `aws_iam_role_policy` (260): 8 of the other 10 resource blocks in that file set `region = var.region`, which is exactly the 80 percent the rule asks for. IAM is global and none of those three resources carries a `region` argument in the schema, so all three are false positives. |

| Check B reads `data` blocks for validity | `pofix-agent-5wq` | Adds `coverage.mutual-exclusion-unguarded` HIGH on `modules/file-system/main.tf`, line 496. The `aws_iam_policy_document` data source page documents `resources` as conflicting with `not_resources`, and `not_resources` as conflicting with `resources`, in the same words at 6.44.0 and 6.66.0, fetched on 2026-09-24. There, one `dynamic "statement"` fills both from the `policy_statements` input, whose object type makes both optional, and no validation or precondition stops a caller setting both. The block is added, so it has no base. Adds nothing on `modules/table-bucket/main.tf`, and that is the assertion: the change edits the same pattern at line 37, but the base block already passed a caller's `resources` and `not_resources` through together, so under the edited-block rule of [Which blocks](check-b-coverage.md#which-blocks) the defect holds at the base and is not this change's. The change narrows it: at the base a statement with `not_resources` also got the default `resources`. The same inputs also carry `actions` and `not_actions`, and `principals` and `not_principals`, but the page states no conflict for either pair at either version, so no finding rests on them. |

Expected verdict after every item above: ladder rule 2, block, proposed action `REQUEST_CHANGES`. Nothing is CRITICAL once `pofix-agent-9vi` lands. As of 2026-09-24 the block rests on `examples.example-broken` HIGH, under a prefix other than `compat.`, which disarms rule 0. The `pofix-agent-j81` rows add one MEDIUM and two LOW triples, which do not change the verdict, and the `pofix-agent-5wq` row adds one more HIGH triple under `coverage.`, which leaves it at rule 2.

## Case 2: PR 393

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 393 |
| Head SHA | `110c01c8e078f556744a218ee24c55fd23e46e07` |
| Base | `dd0c434de5e74d8864e249ee020d917b076b6e32`. Recorded on 2026-09-24; it is the merge base of the head. |
| Task text | Review the diff `master..pr-393`. Release commit message: `feat: Support S3 bucket ABAC`. Profile `terraform-aws-modules`. |
| Shape | One new resource in the root `main.tf`, plus regenerated README regions and wrappers. 8 files. |
| Date of measurement | 2026-09-22 |
| State | LIVE |

### MEASURED-AT-HEAD (PR 393)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `coverage.deprecated-argument` | `main.tf` | HIGH | 1391 | `expected_bucket_owner` is marked `(Optional, Forces new resource, Deprecated)` on `aws_s3_bucket_abac` at 6.42.0 and 6.66.0. Re-fetched from the registry on the measurement date. The argument is not deprecated on the eight other resources in the file that use it, so this is specific to the new resource. |
| `profile.generated-content-handwritten` | `README.md` | HIGH | 175, 218, 297 | All three edits fall between `BEGIN_TF_DOCS` (155) and `END_TF_DOCS` (315). |
| `profile.generated-content-handwritten` | `examples/complete/README.md` | HIGH | 72 | Between markers at 27 and 86. |
| `profile.generated-content-handwritten` | `wrappers/main.tf` | HIGH | 4 | Under `wrappers/`. |
| `coverage.optional-argument-unexposed` | `main.tf` | MEDIUM | 1387 | `region` is an optional argument on `aws_s3_bucket_abac`. The new block is the only one of the 22 resource blocks in the file that does not set `region = var.region`, and the omission carries no stated reason. Check B's severity block rates this MEDIUM. |

Verdict at head: ladder rule 2, block.

Four earlier review passes over PR 393 all looked for what the skill misses and none of them reported the `coverage.deprecated-argument` finding, which the skill already produces and which blocks.

### RE-MEASURED 2026-09-24 (PR 393)

Diff `dd0c434de5e74d8864e249ee020d917b076b6e32...110c01c8e078f556744a218ee24c55fd23e46e07`, 8 files. Schema for `aws_s3_bucket_abac` fetched at 6.42.0, the declared floor, and at 6.66.0.

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `coverage.deprecated-argument` | `main.tf` | HIGH | 1391 | `expected_bucket_owner` is `(Optional, Forces new resource, Deprecated)` on `aws_s3_bucket_abac` at 6.42.0 and 6.66.0. |
| `structure.sibling-argument-omitted` | `main.tf` | HIGH | 1387 | `aws_s3_bucket_abac` carries `region` in its schema. All 21 other `resource` blocks in the file set `region = var.region`; the one `data` block that does is not counted. |
| `coverage.default-for-required-argument` | `variables.tf` | HIGH | 151 | `status = optional(string, "Enabled")` backs `abac_status.status`, which the provider marks Required and documents as disabled by default. |

Verdict at re-measurement: ladder rule 2, block.

Check E is silent: the added README rows (one resource, one input, one output), the added `examples/complete/README.md` output row and the added `wrappers/main.tf` line each match an input, output or resource the same change adds. The `validation` message names the accepted values, so `structure.validation-message-uninformative` is silent.

Difference from MEASURED-AT-HEAD:

| Change | Triples | Why |
|--------|---------|-----|
| Removed | 3 `profile.generated-content-handwritten` HIGH | `pofix-agent-ut4` shipped. |
| Removed | `coverage.optional-argument-unexposed` MEDIUM on `main.tf` | Dropped under the Final Step dedup in favour of the HIGH below, as EXPECTED-AFTER predicted. |
| Added | `structure.sibling-argument-omitted` HIGH on `main.tf` | `pofix-agent-3c9` shipped. |
| Added | `coverage.default-for-required-argument` HIGH on `variables.tf` | `pofix-agent-3lz` shipped. |
| Unchanged | `coverage.deprecated-argument` HIGH | |

The re-measured set equals the EXPECTED-AFTER set below exactly.

### EXPECTED-AFTER (PR 393)

| Change | Item | Effect on the triples above |
|--------|------|-----------------------------|
| Check E stops firing on regenerated documentation and wrappers | `pofix-agent-ut4` | Removes the three `profile.generated-content-handwritten` triples. |
| `structure.sibling-argument-omitted` | `pofix-agent-3c9` | Adds a HIGH triple on `main.tf` at line 1387 for the missing `region`, and the `coverage.optional-argument-unexposed` MEDIUM triple for the same argument is dropped under the Final Step dedup rule. One defect, one finding, at the higher severity. |
| The module defaults an argument the provider marks Required | `pofix-agent-3lz` | Adds `coverage.default-for-required-argument` on `variables.tf` at HIGH, line 151. `abac_status` is typed `object({ status = optional(string, "Enabled") })` with `default = null`, so `abac_status = {}` turns ABAC on. The provider marks `status` Required and documents that ABAC is disabled by default. Check B owns this under its required-argument severity line. Check C's insecure-default list still does not reach a permissive default here, which is why the Check C candidate stays in [Dropped Candidates](#dropped-candidates). |

Expected verdict after every item above: ladder rule 2, block, proposed action `REQUEST_CHANGES`. `coverage.deprecated-argument`, `structure.sibling-argument-omitted` and `coverage.default-for-required-argument` are all HIGH under a prefix other than `compat.`, so ladder rule 0 does not fire.

## Case 3: PR 406

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 406 |
| Head SHA | `1b217919f578edd9e8d3c0648d32470aa8131163` |
| Base | `d3a4f6203fe79299ffb790902944b1dcaa3711b6`. Recorded on 2026-09-24; it is the merge base of the head. |
| Task text | Review the diff `master..pr-406`. Release commit message: `feat(#405): Remove legacy ELB access log delivery policy from main.tf`. Profile `terraform-aws-modules`. |
| Shape | Deletion from the root `main.tf` plus one regenerated README line. 2 files, +1 -62. |
| Date of measurement | 2026-09-22 |
| State | LIVE |

### MEASURED-AT-HEAD (PR 406)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `profile.generated-content-handwritten` | `README.md` | HIGH | 217 | The only README change, and it falls between `BEGIN_TF_DOCS` (161) and `END_TF_DOCS` (317). |

Verdict at head: ladder rule 2, block, on one false positive.

An earlier pass recorded this case as an empty findings list and an approval. That is wrong, and the correction is the reason the measured column exists at all: the earlier claim and the claim that Check E over-fires were both made about this same commit, in the same round of work, and neither noticed the other.

Contested at head, recorded separately because the rule text does not settle it: the change deletes `data "aws_region" "current"` from `main.tf:1`. Check A's bullet reads "A resource is removed, renamed, or has its address changed ... with no `moved` block". The skill nowhere says whether a `data` block is a resource for that bullet. A literal reader emits `compat.resource-address-changed` on `main.tf`; a reader who takes "resource" to mean a `resource` block does not. This is an ambiguity in the rule, not a measurement, and it is left out of the set above so that a comparison does not turn on it.

### RE-MEASURED 2026-09-24 (PR 406)

Diff `d3a4f6203fe79299ffb790902944b1dcaa3711b6...1b217919f578edd9e8d3c0648d32470aa8131163`, 2 files, +1 -62. The task carries no accompanying prose, so no claim is checked.

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `compat.generated-policy-narrowed` | `main.tf` | CRITICAL | 747 | The `ELBRegion<Name>` statement is removed from the bucket policy the module generates when `attach_elb_log_delivery_policy = true`. The title carries no `!` and no `BREAKING CHANGE:` trailer, so the break is undeclared. |

Verdict at re-measurement: ladder rule 0, hold for the next major. The only CRITICAL is `compat.*` and nothing else is CRITICAL or HIGH.

Check E is silent: the one README change removes the `aws_region.current` row, and the same change removes that `data` block. The contested `data` block question is settled by the rule text as it now stands: removing a `data` block "is never `compat.resource-address-changed`", and it is judged by what it fed. It fed the narrowed policy, which is the finding above. `profile.commit-type-mismatch` is silent under the dedup paragraph at the end of Check E, because Check A reports the undeclared break.

Difference from MEASURED-AT-HEAD:

| Change | Triples | Why |
|--------|---------|-----|
| Removed | `profile.generated-content-handwritten` HIGH on `README.md` | `pofix-agent-ut4` shipped. |
| Added | `compat.generated-policy-narrowed` CRITICAL on `main.tf` | Check A now reads the documents the module generates. |

The re-measured set equals the EXPECTED-AFTER set below, with the `data` block row settled as excluded.

Not reported by this reading: the added comment `# Recommended AWS policy using the Elastic Load Balancing service principal.` at `main.tf:750` makes a claim the code cannot show and cites no source. The comment it replaces carried a link. It is left out because a recommendation is not one of the kinds the comment bullet names (a limitation, a defect, an ordering requirement or other non-obvious behaviour). A reader who counts it adds `structure.comment-unsourced` MEDIUM on `main.tf`.

### EXPECTED-AFTER (PR 406)

| Change | Item | Effect on the triples above |
|--------|------|-----------------------------|
| Check E stops firing on regenerated documentation and wrappers | `pofix-agent-ut4` | Removes the one triple, leaving an empty list. |
| Check A reads the generated resources, not only the interface | `pofix-agent-p2m` | Adds `compat.generated-policy-narrowed` on `main.tf` at CRITICAL, line 747. Every caller with `attach_elb_log_delivery_policy = true` loses the `ELBRegion<Name>` statement from the generated bucket policy on the next apply. The interface is untouched, so nothing fails at plan or apply and log delivery stops silently at the AWS control plane. The maintainer called this a breaking change on the pull request. |
| The `data` block ambiguity is settled | `pofix-agent-p2m` | Either adds or permanently excludes the contested `compat.resource-address-changed` triple. Whichever way it is settled, the contested paragraph above is deleted and the triple moves into or out of the expected set. |

Expected verdict after both: hold for the next major, action COMMENT. The CRITICAL carries a `compat.*` rule_id, nothing else is CRITICAL or HIGH, so rule 0 of the verdict ladder in `terraform-module-pr-review` fires before rule 1.

PR 406 is the case rule 0 was written for, and it is the only one of the three where rule 0 fires: PR 410 and PR 393 each carry a HIGH under a prefix other than `compat.`, which disarms it. Settling the contested `compat.resource-address-changed` either way leaves the verdict alone, because that name is also `compat.*`. A `compat.claim-contradicts-analysis` HIGH alongside the CRITICAL would leave it alone too.

## Case 4: PR 402

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 402 (merged as `d2f564255b22b7467550ed5bab189e571d7b9fb1`) |
| Head SHA | `f33c6852220ea508fe962df5d3f69aa22f6bcaba` |
| Base | `97bb13eff35489bd38993487c3d04c5b6d024cb6`, the merge base of the head |
| Task text | Review the diff `97bb13eff35489bd38993487c3d04c5b6d024cb6...f33c6852220ea508fe962df5d3f69aa22f6bcaba`. Release commit message: `fix: Replace deprecated data.aws_region.current.name with .region in example`. Profile `terraform-aws-modules`. |
| Shape | Examples only. One line in `examples/complete/main.tf`: `data.aws_region.current.name` becomes `data.aws_region.current.region`. No module file, README or wrapper changes. |
| Date of measurement | 2026-09-24 |
| State | LIVE |

There is no MEASURED-AT-HEAD column for this case. It was first measured on 2026-09-24 with the skill described in [Provenance of the Re-Measured Column](#provenance-of-the-re-measured-column), and that measurement is its frozen record.

### RE-MEASURED 2026-09-24 (PR 402)

Empty findings list. Checks A to E ran and found nothing.

- Checks A and B: no module file changed. The example's `versions.tf` declares `hashicorp/aws >= 6.42`, and the `aws_region` data source documents `region` at 6.42.0, fetched on the measurement date, so the new reference exists at the example's floor. The change stops using `name`, which 6.42.0 marks Deprecated.
- Check C: no resource, variable, output, comment or constant added.
- Check D: the example still references a real attribute and needs no custom input. The region literal `eu-west-1` elsewhere in the file is untouched.
- Check E: no generated region or wrapper changed. `fix` suits a change that repairs an example, and the identifiers in the title match the diff.

Verdict at re-measurement: ladder rule 8, approve, on findings alone. Host signals were not read.

What this case pins: the skill stays silent on a correct examples-only change. It does not test Check C's multi-provider exclusion for `examples/`, because the change adds no provider block.

### EXPECTED-AFTER (PR 402)

An empty list. No pending work item is expected to change it.

## Case 5: PR 411

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 411 (merged as `2c8cce73ef1f0932cac501af4e2ce51ecb076342`) |
| Head SHA | `67db5ae5843901670971fa16870d22a702b08fd4` |
| Base | `d3a4f6203fe79299ffb790902944b1dcaa3711b6`, the merge base of the head |
| Task text | Review the diff `d3a4f6203fe79299ffb790902944b1dcaa3711b6...67db5ae5843901670971fa16870d22a702b08fd4`. Release commit message: `fix: Document known Terraform/OpenTofu limitations in README`. Profile `terraform-aws-modules`. |
| Shape | Docs only. One file, `README.md`, +51 -0. The whole addition is a new region between `<!-- BEGIN_KNOWN_LIMITATIONS -->` (147) and `<!-- END_KNOWN_LIMITATIONS -->` (196), above the terraform-docs region (212 to 369). No `.tf` file and no terraform-docs row changes. |
| Date of measurement | 2026-09-24 |
| State | LIVE |

### RE-MEASURED 2026-09-24 (PR 411)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `profile.generated-content-handwritten` | `README.md` | HIGH | 147 | The profile names `BEGIN_KNOWN_LIMITATIONS` and `END_KNOWN_LIMITATIONS` as a managed region with its own generator, governed by the same rule as the terraform-docs region. Check E's test for regenerated content is rows that line up with the inputs, outputs or resources the same change touched. This region is 48 lines of prose no variable or output backs, and the change touches no code, so the literal reading fires. |

Verdict at re-measurement: ladder rule 2, block.

The Gaps table asked whether Check E still fires on a docs-only change with no code for the region to be consistent with. It does, here in a region that is prose by design. Nothing in the diff lets the reviewer tell generator output from a hand edit: Rule 1 forbids running the generator, and the region has no code to line up with. The finding is recorded because the rule as written produces it, not because the reading is judged right.

- Checks A, B and D: no `.tf` file and no example changed.
- Check C: the new section says the module cannot take `prevent_destroy` or `ignore_changes` through an input. The head's `main.tf` carries no `lifecycle` block setting either, so `structure.docs-contradict-code` is silent. The rest describes Terraform, OpenTofu and an external registry service, which that bullet does not reach.
- Check E, title: `fix` on a documentation-only change cuts a patch release. The commit-type bullet names `fix` only when it adds an input, an output or a feature, so `profile.commit-type-mismatch` is silent. A reader who counts it adds MEDIUM on `.`.

### RE-MEASURED 2026-09-24 after pofix-agent-5zd (PR 411)

The generated-content rule of Check E changed on 2026-09-24 under `pofix-agent-5zd`: a README region counts as generated only when its marker pair is a terraform-docs pair or appears literally in a base hook's arguments or a configuration file they name. The rule was applied again at the same SHA. The other checks were not re-run: nothing their readings above rest on changed between the two measurements.

Empty findings list.

- Check E, generated content: the base revision's `.pre-commit-config.yaml` lists `terraform_fmt`, `terraform_wrapper_module_for_each`, `terraform_docs` (its only argument turns the lockfile off), `terraform_tflint`, `terraform_validate`, `check-merge-conflict`, `end-of-file-fixer` and `trailing-whitespace`. No hook argument contains `BEGIN_KNOWN_LIMITATIONS` or `END_KNOWN_LIMITATIONS`, no argument names a configuration file, and the base tree has no terraform-docs configuration file. The pair is a layout convention, so `profile.generated-content-handwritten` does not reach it. The terraform-docs region (212 to 369) is unchanged.
- The region's prose falls to Check C, which the section above records as silent.

Verdict at re-measurement: ladder rule 8, approve, on findings alone. Host signals were not read.

### EXPECTED-AFTER (PR 411)

| Change | Item | Effect on the triples above |
|--------|------|-----------------------------|
| Check E's generated-content rule reaches only regions whose marker pair passes its textual test | `pofix-agent-5zd` | Removes the `profile.generated-content-handwritten` HIGH on `README.md`. The limitations pair is not a terraform-docs pair and no hook argument in the module's quality gate names it, so its text is hand-written by design and nothing overwrites it. |

Expected list: empty. Expected verdict: ladder rule 8, approve. This case pins that a marker pair alone does not make a region generated.

## Case 6: PR 404

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 404 (merged as `58a531d293ab0fe3a06307f9c40c1bed7ef1239f`) |
| Head SHA | `514c2ae313d7640509cb2677a6462e7570ef8bab` |
| Base | `c148de30295b121cce45cef21b7c280b19283935`, the merge base of the head |
| Task text | Review the diff `c148de30295b121cce45cef21b7c280b19283935...514c2ae313d7640509cb2677a6462e7570ef8bab`. Release commit message: `fix: Update GitHub Actions and pre-commit hook versions`. Profile `terraform-aws-modules`. |
| Shape | CI and tooling bump. 28 files: four workflows, `.pre-commit-config.yaml`, `.gitignore`, 16 `README.md` files whose terraform-docs tables change only their separator rows, and 6 `versions.tf` files under `wrappers/` whose `provider_meta "aws"` block loses its `user_agent` list. No provider floor moves, and no `.tf` file outside `wrappers/` changes. |
| Date of measurement | 2026-09-24 |
| State | LIVE |

### RE-MEASURED 2026-09-24 (PR 404)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `profile.release-config-changed` | `.github/workflows/release.yml` | HIGH | 23 | semantic-release 25.0.0 to 25.0.8, its action v5 to v6.0.0, `@semantic-release/changelog` 6.0.3 to 7.0.0, `@semantic-release/git` 10.0.1 to 11.0.1. Release automation the profile owns now behaves differently. |
| `profile.release-config-changed` | `.github/workflows/pre-commit.yml` | HIGH | 10 | terraform-docs v0.20.0 to v0.24.0 and TFLint v0.59.1 to v0.64.0 change what the quality gate generates and checks. The README separator rows in the same change are the new generator's output. |
| `profile.generated-content-handwritten` | `wrappers/versions.tf` | HIGH | 11 | `provider_meta "aws"` loses its `user_agent` list while the root `versions.tf` it is generated from keeps it, and the change touches nothing the wrapper derives from. Whether pre-commit-terraform v1.108.1 emits this is not established: Rule 1 forbids running the hook. |
| `profile.generated-content-handwritten` | `wrappers/account-public-access/versions.tf` | HIGH | 11 | Same, against `modules/account-public-access/versions.tf`. |
| `profile.generated-content-handwritten` | `wrappers/notification/versions.tf` | HIGH | 11 | Same, against `modules/notification/versions.tf`. |
| `profile.generated-content-handwritten` | `wrappers/object/versions.tf` | HIGH | 11 | Same, against `modules/object/versions.tf`. |
| `profile.generated-content-handwritten` | `wrappers/table-bucket/versions.tf` | HIGH | 11 | Same, against `modules/table-bucket/versions.tf`. |
| `profile.generated-content-handwritten` | `wrappers/vectors/versions.tf` | HIGH | 11 | Same, against `modules/vectors/versions.tf`. |

Verdict at re-measurement: ladder rule 2, block.

Silent, with the reading taken:

- The 16 README files: every changed row is a table separator, `|------|` rewritten as `| ---- |`. Every input, output, resource and provider row is unchanged, so generated content and code still agree and none of the three non-matching shapes in Check E applies. A format-only rewrite by a newer generator is read as no disagreement.
- `.pre-commit-config.yaml`: `rev` v1.105.0 to v1.108.1. The profile expects these pins to move ahead of the template.
- `lock.yml` and `stale-actions.yaml`: major bumps of issue-housekeeping actions. Neither releases nor runs a check, so `profile.release-config-changed` does not reach them, and the title states the reason for the drift from the template.
- `.gitignore`: a typo fixed in a comment the template does not carry. The divergence from the template predates the change.
- Check A: `provider_meta` is not a variable, output, resource or floor, and no floor moves. Check C: every changed wrapper declares the same floors as the module it calls (`>= 1.5.7`, `hashicorp/aws >= 6.42`), so `structure.version-floor-understated` is silent. Checks B and D: no resource or example changed.
- Title: `fix` on a CI change is not in the commit-type bullet's list. A reader who counts it adds MEDIUM on `.`.

What this case does not test: a provider floor raised across every `versions.tf` with nothing else, which stays in the Gaps table.

### RE-MEASURED 2026-09-24 after pofix-agent-5zd (PR 404)

The generated-content rule of Check E changed on 2026-09-24 under `pofix-agent-5zd`: generated content that loses or reshapes content relative to its source, in a change that also moves its generator's version, is a check that cannot run rather than a hand edit. Content it gains stays HIGH. Every changed wrapper line here is a removal, so the six files fall under the first part. The rule was applied again at the same SHA. The other checks were not re-run: nothing their readings above rest on changed between the two measurements.

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `profile.release-config-changed` | `.github/workflows/release.yml` | HIGH | 23 | Unchanged from the section above. |
| `profile.release-config-changed` | `.github/workflows/pre-commit.yml` | HIGH | 10 | Unchanged from the section above. |
| `review.check-not-run` | `wrappers` | MEDIUM | null | The six wrapper `versions.tf` files do not match the `versions.tf` of the module each wraps, and the same change moves the `rev` of the `.pre-commit-config.yaml` entry that lists `terraform_wrapper_module_for_each` from v1.105.0 to v1.108.1. What v1.108.1 emits cannot be read from the workspace. One finding for the one generator, with `file` the directory holding all six. |

Verdict at re-measurement: ladder rule 2, block. The two HIGH findings outrank the unknown, so rule 4 is not reached.

- The 16 README files: the rule now names a change that only reformats rows as no disagreement, which is the reading the section above already took. terraform-docs also moves, in the workflow from v0.20.0 to v0.24.0 and with the hook `rev`, but the version move matters only for content that does not match, and this content matches.
- Outside the review, and not available to it, read 2026-09-24: the pre-commit-terraform release notes for v1.106.0 carry the entry "Strip `provider_meta` blocks from `versions.tf`" under `terraform_wrapper_module_for_each` (#967). The hook's source, `hooks/terraform_wrapper_module_for_each.sh` at v1.108.1, lines 397 to 404, copies the wrapped module's `versions.tf` and then removes two attributes with `hcledit`: `terraform.provider_meta.<provider>.user_agent` and `terraform.provider_meta.<provider>.module_name`. Only `user_agent` is present in these modules, and removing it leaves the empty `provider_meta "aws"` block. That is the diff exactly. The six HIGH findings in the section above were false positives. The review cannot learn this without running or reading the generator, so the rule asks instead of asserting.

### EXPECTED-AFTER (PR 404)

| Change | Item | Effect on the triples above |
|--------|------|-----------------------------|
| Generated content that only loses or reshapes lines under a moved generator version is a check that cannot run | `pofix-agent-5zd` | Removes the six `profile.generated-content-handwritten` HIGH triples on `wrappers/**/versions.tf` and adds one `review.check-not-run` MEDIUM on `wrappers`. |

The two `profile.release-config-changed` triples are the rule working as intended: release automation changed, and the maintainer overrides the block knowingly. Expected verdict: ladder rule 2, block, on those two. Without them the `review.check-not-run` would take the verdict to rule 4, inconclusive, never to approve.

## Case 7: PR 354

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 354 (merged as `2dd4364b67d89cb9c881be465e5e4196ef8dea8f`) |
| Head SHA | `c8894ccfcf92ef7a5c872473b7413ce2ccd973bd` |
| Base | `cdf595d9291fbb395b51dc8f1c10285fd3574e18`, the merge base of the head |
| Task text | Review the diff `cdf595d9291fbb395b51dc8f1c10285fd3574e18...c8894ccfcf92ef7a5c872473b7413ce2ccd973bd`. Release commit message: `feat: Add Region parameter to notification module`. Profile `terraform-aws-modules`. |
| Shape | Submodule only. `modules/notification/main.tf` (+8), `modules/notification/variables.tf` (+6), one row in `modules/notification/README.md` and one line in `wrappers/notification/main.tf`. The root module is untouched. |
| Date of measurement | 2026-09-24 |
| State | LIVE |

### RE-MEASURED 2026-09-24 (PR 354)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `examples.argument-undemonstrated` | `examples/notification/main.tf` | LOW | 109 | `module "all_notifications"` calls `../../modules/notification` and does not set the new `region` input. |

Verdict at re-measurement: ladder rule 7, approve with nits.

- Check A: the new `region` input is optional with a `null` default, and `region = var.region` on the four existing resources leaves the provider's region in force when it is unset. Nothing breaks.
- Check B: `region` is Optional on `aws_s3_bucket_notification`, `aws_lambda_permission`, `aws_sqs_queue_policy` and `aws_sns_topic_policy` at 6.5.0, the submodule's declared floor (`hashicorp/aws >= 6.5`), and at 6.66.0. No argument sits above the floor.
- Check C: the new variable carries a `type` and a `description`, and each touched block keeps `for_each` or `count` first. `structure.sibling-argument-omitted` is silent because the change adds no resource block, only an argument to existing ones. The mixed-service count the Gaps table asks about is therefore not exercised here.
- Check D: no submodule is added, and the example still applies as written.
- Check E: the README row and the wrapper line match the new input one for one. `feat` suits a new input, and the description names the surface.

### EXPECTED-AFTER (PR 354)

Equal to the re-measured list. No pending work item is expected to change it.

## Case 8: PR 3668

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-eks` |
| Pull request | 3668 (merged as `f13e8db8e5eb38a957c29299d85bdcff2464ff23`, released as v21.16.1) |
| Head SHA | `c71a1fb103a4c9d7043e3ef724a141febd6eaea2` |
| Base | `75b4fc547df610ca3bd4cd6bcabce11e5abe722d`, the merge base of the head. It is the release commit tag v21.16.0 points at. |
| Task text | Review the diff `75b4fc547df610ca3bd4cd6bcabce11e5abe722d...c71a1fb103a4c9d7043e3ef724a141febd6eaea2`. Release commit message: `fix: Revert "feat: Add ECR Public permissions to EKS Auto Mode node IAM role"`. Profile `terraform-aws-modules`. |
| Shape | Revert. One file, `main.tf`, +2 -3: the `AmazonElasticContainerRegistryPublicReadOnly` entry leaves the `for_each` map of `aws_iam_role_policy_attachment.eks_auto`. The head commit's message carries `This reverts commit c07c26c18598182785ec36df2b30d05fa7a016b4.` That commit is pull request 3665, and v21.16.0 contains it: the tag's commit is its direct child. |
| Date of measurement | 2026-09-24 |
| State | LIVE |

### RE-MEASURED 2026-09-24 (PR 3668)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `compat.generated-policy-narrowed` | `main.tf` | CRITICAL | 923 | Every caller on v21.16.0 whose configuration creates the Auto Mode node role loses `AmazonElasticContainerRegistryPublicReadOnly` from it on the next apply: an unchanged configuration now permits less, and nothing errors at plan or apply. The title carries no `!` and no `BREAKING CHANGE:` trailer. Reading taken: a grant removed from a role the module produces is this bullet's case. |

Verdict at re-measurement: ladder rule 0, hold for the next major, action COMMENT.

- The same removal also reads as `compat.resource-address-changed`: the instance `aws_iam_role_policy_attachment.eks_auto["AmazonElasticContainerRegistryPublicReadOnly"]` is destroyed with no successor. One defect gives one finding under the Final Step. Both names are `compat.*` at CRITICAL, so the verdict does not turn on the choice.
- The maintainer released the revert as a patch. The reason is in the pull request body: the managed policy does not exist in the GovCloud partition. The task carries no prose, so no claim is checked. The skill rates the rollback of a released grant a break, and that disagreement with the release is what this case records.
- Check B: `aws_iam_role_policy_attachment` fetched at 6.66.0 and at the declared floor 6.28.0. The change sets no new argument.
- Checks C and D: no resource, variable, output, comment or example is added or changed.
- Check E: `profile.commit-type-mismatch` is silent under the dedup paragraph at the end of Check E, because Check A reports the undeclared break.
- Against the Reverts paragraph of Check A: condition 1 holds, and condition 3 fails, because v21.16.0 contains the reverted commit. Condition 4 fails too: the head no longer reads as v21.16.0 did. The exemption does not apply and the finding stands. The rule text before and after that paragraph gives the same list.

### EXPECTED-AFTER (PR 3668)

| Change | Item | Effect on the triples above |
|--------|------|-----------------------------|
| The Reverts paragraph in Check A | `pofix-agent-xye` | Adds nothing and removes nothing. Condition 3 fails in a full clone. In a workspace fetched at depth 1, condition 2 fails first, because the reverted commit does not resolve. |

Expected verdict: ladder rule 0, hold for the next major, action COMMENT. This is the second case where rule 0 fires, after PR 406, and the first where the narrowing is a revert.

## Case 9: PR 410 at its current head

| Field | Value |
|-------|-------|
| Repository | `terraform-aws-modules/terraform-aws-s3-bucket` |
| Pull request | 410, open, not a draft |
| Head SHA | `30cd3728d16cc5a1e1fa25d0d891015b6e4a0ada` |
| Base | `5dc2f1f89743ab935114b0b039bc88044a672ca2`, the merge base of the head and the tip of `master` on the date: the release commit of version 5.16.1, whose parent merged PR 411 ([Case 5](#case-5-pr-411)) |
| Task text | Review the diff `5dc2f1f89743ab935114b0b039bc88044a672ca2...30cd3728d16cc5a1e1fa25d0d891015b6e4a0ada`. Release commit message: `feat: Add Amazon S3 Files support`. Profile `terraform-aws-modules`. The accompanying prose is the pull request body, origin `change-author`, and one conversation comment, origin `other`. |
| Shape | The same 61 files as [Case 1](#case-1-pr-410), 21 commits rebased onto the new base. `examples/file-system/variables.tf` is an empty file. |
| Date of measurement | 2026-09-24 |
| State | LIVE |

This is a new case, not a re-measurement of Case 1: the SHA differs, so Case 1's sections stay as they are. See [Provenance of Case 9](#provenance-of-case-9) for how it was measured.

What moved between the two heads. Every `.tf` file in the change is byte for byte the file at `26cfa8c`. The per-file patches of the two diffs are identical except in the root `README.md`, where every hunk after the first sits 51 lines lower and one context line differs: the new base carries the `BEGIN_KNOWN_LIMITATIONS` region PR 411 added (lines 166 to 215 at the head). The change edits no line inside that region. So any difference from Case 1 below is a rule change or a different reading of the same code, never a code change.

### RE-MEASURED 2026-09-24 (PR 410 at 30cd372)

| rule_id | file | severity | line | notes |
|---------|------|----------|------|-------|
| `examples.example-broken` | `examples/file-system/main.tf` | HIGH | 111 | Access point `reports` sets no `posix_user`, which `aws_s3files_access_point` marks Required at 6.66.0. The module renders it through a `dynamic` block over an optional input, so this access point renders no `posix_user` block and cannot plan. Inferred from the files and the schema, not verified by execution. |
| `structure.docs-contradict-code` | `modules/file-system/variables.tf` | HIGH | 323 | Reached through conversation claim 1 below and decided from the code. `source_policy_documents` (323) and `override_policy_documents` (329) are documented as merged into the file system policy. The rule fires on that promise, so the finding sits there, and the code that breaks it is the precondition at `modules/file-system/main.tf:593`. The `aws_iam_policy_document` page at 6.66.0 documents that both are merged into the exported `json`, and `statement` is the configuration block alone. With `create_policy = true`, those documents, no `policy_statements` and no access point grants, the precondition at 593 counts zero `statement` blocks and stops the plan, so no code path creates a policy from the documents alone. Whether the attribute reads as an empty list or as null is not established without running; the plan stops either way. |
| `structure.docs-contradict-code` | `variables.tf` | HIGH | 939 | The description of `create_file_system_security_group` says "A file system that sets its own `security_groups` never creates one". `main.tf:1623` decides from the file system's `create_security_group` and the root flag only, and `modules/file-system/main.tf:319` from `create` and `create_security_group`. Neither reads `security_groups`, so a file system that sets only `security_groups` still gets a group, and fails the group's `security_group_vpc_id` precondition when no VPC is set. The example's `agents` file system sets `create_security_group = false` beside its `security_groups`, which is what the description says is unnecessary. |
| `coverage.optional-argument-unexposed` | `modules/file-system/main.tf` | MEDIUM | 138 | As in Case 1: `max_session_duration` on `aws_iam_role`. |
| `coverage.attribute-not-output` | `modules/file-system/outputs.tf` | MEDIUM | null | As in Case 1: `latest_version_number` on `aws_s3files_synchronization_configuration`, confirmed at 6.66.0 and 6.42.0. |
| `scope.new-submodule` | `modules/file-system` | MEDIUM | null | The five `aws_s3files_*` types are neither adjuncts nor allowed on the base, which has no `docs/SCOPE.md`. The IAM and security group types are adjuncts, and the root's call to `./modules/file-system` is a local source. Matches the Check F worked case for this pull request. |
| `structure.flag-polarity` | `modules/file-system/variables.tf` | MEDIUM | 334 | As in Case 1: `create_policy` defaults to `false`. Recorded as 335 on 2026-09-24. Corrected on 2026-09-25 to the `variable "create_policy"` line, the block's first line, under the `line` rule of [findings-schema.md](findings-schema.md#required-fields). `line` is outside the [comparison](#comparison-rule), so the triple is unchanged. |
| `structure.comment-unsourced` | `modules/file-system/main.tf` | MEDIUM | 59, 78, 91, 219, 302, 551, 590 | As in Case 1. |
| `structure.comment-unsourced` | `main.tf` | MEDIUM | 1579 | As in Case 1. |
| `structure.comment-unsourced` | `examples/file-system/main.tf` | MEDIUM | 125 | As in Case 1. |
| `structure.copied-content-unattributed` | `modules/file-system/main.tf` | MEDIUM | 153, 258 | As in Case 1. |
| `structure.copied-content-unattributed` | `examples/file-system/main.tf` | MEDIUM | 260, 285 | As in Case 1. |
| `structure.passthrough-field-drift` | `variables.tf` | MEDIUM | 850 | The root's `file_systems[*].mount_targets` object has no `security_groups`, while `modules/file-system/variables.tf:183` declares `security_groups = optional(list(string), [])` there and `modules/file-system/main.tf:276` reads it. No root caller can set security groups per mount target. |
| `examples.feature-undemonstrated` | `examples/file-system/main.tf` | MEDIUM | null | As in Case 1: no example creates `aws_iam_role_policy_attachment` or a file system egress rule. |
| `compat.provider-floor-raised` | `versions.tf` | LOW | 7 | 6.42 to 6.44. Every s3files argument the change uses is present at 6.42.0. |
| `compat.provider-floor-raised` | `modules/account-public-access/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/notification/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/object/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/table-bucket/versions.tf` | LOW | 7 | Same bump. |
| `compat.provider-floor-raised` | `modules/vectors/versions.tf` | LOW | 7 | Same bump. |
| `structure.argument-order` | `modules/file-system/main.tf` | LOW | 37, 437 | As in Case 1. |
| `coverage.enum-value-unknown` | `examples/file-system/main.tf` | LOW | 76, 129 | `ON_DIRECTORY_FIRST_ACCESS` against the documented `ON_FILE_ACCESS`, at 6.42.0 and 6.66.0. |
| `examples.argument-undemonstrated` | `examples/file-system/main.tf` | LOW | null | As in Case 1. |
| `profile.unrelated-change-bundled` | `modules/notification/main.tf` | LOW | 1 | `data "aws_partition" "this"` gains a `count`. The directory takes no part in the feature. |
| `profile.unrelated-change-bundled` | `modules/table-bucket/main.tf` | LOW | 32 | The policy statement's `resources` fallback changes at line 37. The rule puts `line` at the file's first changed line, and that is 32, where the hunk realigns `sid` and its neighbours, so 32 matches Case 1's EXPECTED-AFTER row. The body names this as an unrelated fix, which is what the rule asks to split out. |

Verdict: ladder rule 2, block, proposed action `REQUEST_CHANGES` under no clamp. Nothing is CRITICAL, so rule 0 is not armed, and three HIGH findings sit under prefixes other than `compat.`. Summary line notes: none, since no item of origin `other` tries to steer the review and the comment's four claims are under the cap of 20.

Silent, with the reading taken:

- Check A and the body: the body says "Breaking Changes: None" and names the floor move. Check A's own conclusion is no break, only the LOW floor raise, so `compat.claim-contradicts-analysis` and `compat.break-unexplained` are silent. The new `count` on existing `data` blocks is never `compat.resource-address-changed`. The reworded `attach_elb_log_delivery_policy` and `attach_lb_log_delivery_policy` descriptions are named in the body, so they are not a silent surface change.
- Check C: `structure.input-ignored-in-branch` is silent on `iam_role_policies`, under the `create_<x>` carve-out as `pofix-agent-dpk` left it. `structure.passthrough-default-drift` is silent: every forwarded field's unset value agrees after substitution, including `create_security_group`, whose root side falls back to `create_file_system_security_group` (`true`) and whose submodule default is `true`. `structure.sibling-argument-omitted` is silent under its schema gate.
- Check E, mechanical pass: every changed terraform-docs row and wrapper line lines up with the change, as in Case 1. The known limitations region is untouched, and under `pofix-agent-5zd` it is a layout convention anyway.
- Check F: no provider added, no remote `module` source, no new file outside the layout, no scanner, test or banner change, and `.pre-commit-config.yaml` and the workflows are unchanged.
- Schema budget: the need list is the 21 types of the [worked example](large-changes.md#worked-example-pull-request-410), 62 fetches through fetch helpers under the cap of 96, so no `review.check-not-run`. Those counts were taken before `aws_s3_bucket_versioning` was added to the need list; the worked example now gives 22 types and 65 fetches. A host without isolated fetches has a cap of 11 and is expected to report the rest as `review.check-not-run`.

### Conversation comment (PR 410 at 30cd372)

One comment, posted on 2026-09-18 by an account that is neither a member of the organization nor the author, so its origin is `other`. It is 2120 characters, under the 4000-byte limit, and was selected whole. It makes four claims. None of its wording is carried into a finding; each claim was resolved in the workspace.

| Claim, paraphrased | Resolved at | Treatment |
|--------------------|-------------|-----------|
| `create_policy = true` with only `source_policy_documents` fails the precondition near `modules/file-system/main.tf:592`, because documents never reach `statement` | `modules/file-system/main.tf:589` to `:596` | Confirmed by the code and the data source documentation. Reported as `structure.docs-contradict-code` HIGH on `modules/file-system/variables.tf:323`, the second row above, with the precondition at `main.tf:593` named in its notes. The claim's null error is not established without running and the finding does not rest on it. |
| The versioning precondition's message misleads when the bucket's versioning is managed outside the module | `main.tf:1595`, `modules/file-system/main.tf:54` to `:57` | Not confirmed as a defect under any rule. The message names the requirement, so `structure.validation-message-uninformative` is silent, and the root README says only that S3 Files needs versioning on the bucket and shows it through the module's own `versioning` input. Recorded as `review.quoted-claim-unverifiable`, no finding. |
| `kms_key_id` must be an ARN while its description says "ID of the KMS key" | `modules/file-system/variables.tf:48` | Not confirmed. The registry documents `kms_key_id` as "KMS key ID for encryption" at 6.42.0 and 6.66.0, and the claim rests on provider source, which Rule 2 puts out of reach. Recorded as `review.quoted-claim-unverifiable`, no finding. |
| `iam_role_policies` is dropped without an error when a role is brought in | `modules/file-system/main.tf:252` | The code filters on `local.create_iam_role` as the claim says, and the `create_<x>` carve-out of `structure.input-ignored-in-branch` exempts it, because `iam_role_policies` contains `iam_role`. Not a defect under the rule. Recorded as `review.quoted-claim-unverifiable`, no finding. |

The comment carries no compatibility claim that could arm Check A, and could not: a `conversation` item never does.

### Difference from Case 1 (PR 410 at 30cd372)

Against [RE-MEASURED 2026-09-24 (PR 410)](#re-measured-2026-09-24-pr-410), as `{rule_id, file, severity}` triples:

| Change | Triples | Why |
|--------|---------|-----|
| Added | `scope.new-submodule` MEDIUM on `modules/file-system` | Rule change: Check F shipped after Case 1 was measured. |
| Added | `structure.passthrough-field-drift` MEDIUM on `variables.tf` | Rule change: `pofix-agent-j81`, as Case 1's EXPECTED-AFTER predicted. |
| Added | 2 `profile.unrelated-change-bundled` LOW, on `modules/notification/main.tf` and `modules/table-bucket/main.tf` | Rule change: `pofix-agent-j81`, as Case 1's EXPECTED-AFTER predicted. |
| Added | `structure.docs-contradict-code` HIGH on `modules/file-system/variables.tf` | Input change: conversation comments now reach the reviewer (`pofix-agent-t3o`), and the comment pointed at code Case 1's reading passed over. The code is unchanged. |
| Added | `structure.docs-contradict-code` HIGH on `variables.tf` | A miss in Case 1's re-measurement: the bullet and the code were the same then. |
| Removed | none | |
| Unchanged | `examples.example-broken` HIGH, 6 `compat.provider-floor-raised` LOW, `coverage.optional-argument-unexposed` MEDIUM, `coverage.attribute-not-output` MEDIUM, `structure.flag-polarity` MEDIUM, 3 `structure.comment-unsourced` MEDIUM, 2 `structure.copied-content-unattributed` MEDIUM, `examples.feature-undemonstrated` MEDIUM, `structure.argument-order` LOW, `coverage.enum-value-unknown` LOW, `examples.argument-undemonstrated` LOW | The code is byte for byte the same and these rules did not change. |

No difference comes from a code change between the two heads. The verdict is the same, ladder rule 2, block, and it now rests on three HIGH findings instead of one.

Not reported by this reading, as in Case 1: `structure.docs-contradict-code` on the root README note that a read-only principal is also denied writes, `structure.validation-missing` on `ip_address_type`, `trigger` and `ip_protocol`, and `structure.comment-redundant` on short labels.

### EXPECTED-AFTER (PR 410 at 30cd372)

The re-measured list, plus the one `coverage.mutual-exclusion-unguarded` HIGH triple on `modules/file-system/main.tf` of the `pofix-agent-5wq` row in [Case 1's EXPECTED-AFTER](#expected-after-pr-410), for the same reason: every `.tf` file is byte for byte the file at Case 1's head. The verdict stays ladder rule 2, block. Two other readings from the same item add nothing here, and that is the assertion. `modules/file-system` has no `iam.tf`, so keeping its IAM resources in `main.tf` is no `structure.wrong-file` under [Check C](check-c-structure.md). In `modules/file-system/main.tf`, `aws_vpc_security_group_ingress_rule.this` and `aws_vpc_security_group_egress_rule.this` set `security_group_id = aws_security_group.this[0].id`, so leaving out the inline `ingress` and `egress` of `aws_security_group` is a documented omission under [Check B](check-b-coverage.md#documented-omissions). The `aws_security_group` page warns, in the same words at 6.44.0 and 6.66.0, fetched on 2026-09-24, against using its in-line `ingress` and `egress` rules together with `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule`.

## Dropped Candidates

Findings that the earlier runs recorded and that are not in the measured columns above, with why. They are here so that a later reader does not rediscover them and assume the fixture missed something.

| Candidate | Case | Why it is not in MEASURED-AT-HEAD |
|-----------|------|-----------------------------------|
| `coverage.required-argument-unreachable` on `modules/file-system/main.tf:409` | 410 | Check B's bullet reads "has no corresponding input and no static value". The input exists and permits null, so the bullet does not fire as written. Dropped for good on 2026-09-24 under `pofix-agent-dpk`: the caller-supplied exemption stays, and the defect is `examples.example-broken` HIGH. See [EXPECTED-AFTER (PR 410)](#expected-after-pr-410). |
| `coverage.optional-argument-unexposed` on `modules/file-system/variables.tf:380` | 410 | `expiration_data_rule` is Optional at 6.66.0 and the module types it as a required attribute of the `synchronization_configuration` object. The argument is exposed, so the bullet ("neither an exposed input nor an omission documented with a reason") does not fire. The defect is that it cannot be omitted, which no current bullet names. |
| `coverage.optional-argument-unexposed` on `variables.tf:850` | 410 | The root `file_systems[*].mount_targets` object omits `security_groups`, which `modules/file-system/variables.tf:183` does expose. The argument is an exposed input somewhere in the module under review, so the bullet does not fire. The root-versus-submodule interface gap is real and unnamed. |
| `structure.precondition-null-collection` and `structure.precondition-references-conditional-resource` | 410 | Both were recorded with new slugs and a note that no check directs at them. Neither name is in the registry. |
| `structure.description-contradicts-provider-type` on `modules/file-system/variables.tf:48` | 410 | New slug, and the evidence for it is the provider's Go source, which Rule 2 and the workspace-only input rule both put out of reach. |
| `structure.insecure-default` on `variables.tf:151` | 393 | Check C's CRITICAL bullet lists encryption, public access, logging and deletion protection. ABAC is none of those, and no other Check C bullet reaches a permissive default. Recorded under EXPECTED-AFTER as `coverage.default-for-required-argument`, which Check B owns. |
| `structure.validation-message-uninformative` on `variables.tf:163` | 393 | The bullet fires when the message "names neither the accepted values or the bound nor the value that was received". The message names the accepted values, so it does not fire. |
| `structure.grouping` on `main.tf:1387` | 393 | The claim was that `main.tf` separates every resource group with a `####` banner. `grep -c '^####' main.tf` at this SHA returns 0. The file uses plain `# Comment` lines. The banners were in a different file in a different pull request. |
| Dead `try()` on `main.tf:1394` | 393 | No registry rule covers it, and proving the fallback unreachable needs the nullability analysis that has no owner yet. |
| `coverage.attribute-not-output` on `outputs.tf:80` | 393 | `aws_s3_bucket_abac` exports no additional attributes at 6.66.0, confirmed on the measurement date. No finding. |
| `profile.commit-type-mismatch` on the PR 406 title | 406 | Check E's bullet needs the change to be "declared breaking only in the README or release config". The pull request body says "Breaking Changes: No", so it is declared breaking nowhere and the bullet does not fire. Once `pofix-agent-p2m` makes Check A emit the CRITICAL, the dedup paragraph at the end of Check E keeps this from firing anyway. |
| Empty first line of `main.tf` | 406 | Formatting, with no registry rule and no `rule_id`. |

## Gaps in the Evidence Base

Cases 1 to 3 have the same shape: `main.tf` plus a regenerated README region in the same module. Cases 4 to 8 add one each of an examples-only change, a docs-only change, a CI and tooling bump, a submodule-only change and a revert. Several rules in and around the pending work have still never been measured against anything else. These are named so that nobody reads their absence as a pass, and no finding is invented for them.

| Missing shape | Why it is needed | What would be measured |
|---------------|------------------|------------------------|
| Examples-only pull request, adding a provider | Case 4 covers an examples-only change and pins silence on a correct one. It adds no provider block, so the boundary for Check C's multi-provider rule is still untested. | Whether Check C's multi-provider rule and Check E's profile rules correctly stay out of `examples/` when an example declares an aliased provider. Not found within the time given to the search on 2026-09-24. Merged pull requests titled for cross-region examples exist in `terraform-aws-modules/terraform-aws-rds` (428 and 554); whether either adds a provider block was not checked. |
| Provider floor bump on its own | A bot pull request that raises a provider floor across every `versions.tf` and changes nothing else. PR 410 raises 23 of them, but alongside a feature, so the floor rule has never been measured on its own. [Case 6](#case-6-pr-404) is a CI and tooling bump and moves no floor. | Whether `pofix-agent-9vi` leaves a bot bump at LOW across every file, and whether Check E's commit-type rules handle `chore` and `build` correctly. |
| Revert of a change no release shipped | [Case 8](#case-8-pr-3668) reverts a released change, so the Reverts paragraph of Check A leaves the CRITICAL in place. The paragraph's exemption, where no tag contains the reverted commit, has never been measured. It needs a workspace with full history and tags, since a single-commit workspace cannot establish it. In this family every merge to the default branch cuts a release, so such a revert may be rare. | An empty Check A list on a revert whose reverted commit no tag contains, and the CRITICAL again when the same review runs on a single-commit workspace. Also the failure the paragraph admits it cannot rule out: Case 8's revert reviewed on a full-history workspace that carries an older tag but not the release tag containing the reverted commit. Condition 3 then passes and the CRITICAL drops, which would pin that a workspace builder must supply every tag. |
| Submodule file mixing two services | [Case 7](#case-7-pr-354) is confined to `modules/notification/` and measures the submodule scope with the root untouched. It adds no resource block, so it does not exercise `structure.sibling-argument-omitted`: the rule counts comparable resource blocks per file, and a submodule file holding two services at once (s3files resources that take `region`, IAM resources that cannot) pushes the count over 80 percent for blocks whose schema has no such argument. | Whether the schema gate keeps `structure.sibling-argument-omitted` silent on a new resource block in a file that mixes two services. |
| Plan failure that reproduces at the merge base | Check D reports an example failure the verification record marks as reproducing at the merge base at LOW, as `examples.example-broken-at-base`, and only a failure new under the change reaches HIGH. No case carries a verification record, so nothing stops an edit from dropping that base gate and turning every pull request that touches a long-broken example into a blocking HIGH. | With a record for the head and the base: `examples.example-broken-at-base` LOW on the example, no `examples.example-broken` HIGH, and a verdict decided by the other findings. Candidate measured and dropped: `terraform-aws-modules/terraform-aws-lambda` PR 770 (`feat: Enabling poller_group_name atribut for reducing Event Poller Unit lambda costs`), head `29b0e40f37150349519185f3c1a43bb91162c77b`, merge base `9d32ec285f7c30c784516ff546ae282cce71e8a7` from the compare API. On 2026-09-24 the plan pass ran in the isolated runner (`plan-runner/run-pass.sh`, runner mode) on `examples/event-source-mapping`. `plan: planned` at the head (`Plan: 44 to add, 0 to change, 0 to destroy.`), and `plan: planned` at the merge base (`Plan: 43 to add`), so the failure it was chosen for does not reproduce and it is not a case. Before the runner could plan it, it produced a failure that did reproduce at the base, `code-error | Error: External Program Lookup Failed` and then `External Program Execution Failed`: the runner image had no `python3` for the module's packaging script, and the example directory was read-only. Both were the runner's, not the example's, which is the other half of this gap: a base re-run cannot tell an environment defect that both sides share from a long-broken example. The gap stays open until a pull request touching an example that fails in the same way at the head and at the base, for a reason in the example, is found and measured. |
| Runner-mode plan evidence | A verification record whose `plan pass mode:` line says `runner` came from a pass that ran the head's code with credentials, so [Check D](check-d-examples.md#plan-evidence) never quotes its kept lines. No case carries such a record, so nothing stops an edit from quoting a runner-mode `code-error` line in a `summary`. | With a runner-mode record carrying a new `code-error`: an `examples.example-broken` HIGH whose `summary` names the class and the cause from the files, and contains no text of the kept line. |

Filling a gap means measuring a real pull request at a real SHA and adding a case in the form above. A hand-written diff is not a case: the value of the three live cases is that a maintainer and a community reviewer already disagreed about them, which is what makes a false positive visible.
