# Rule to Provider Fact

> **Part of:** [terraform-module-reviewer](../SKILL.md)
> **Purpose:** For every `rule_id`, which provider facts it needs and whether a type read from [host fact sheets](large-changes.md#budget) also needs its page. Step 1 reads this table to fix the need list. It is static: a rule's need never depends on what a sheet or a page says.

Columns:

- **Provider facts:** `none`, the rule reads no provider schema; `schema`, it needs facts a host fact sheet carries (names, required, optional and computed flags, deprecation, block names, nesting modes, item limits, exported attributes), and a page serves too; `page`, it needs a page fact.
- **Page facts:** the facts only the page has that the rule may need: allowed values, conflicts, validator limits, documented defaults and omissions, data source behaviour, prose-only notes and import.
- **Page entry when:** for a type read from host fact sheets, the condition, taken from the need list, under which the type also takes a page entry at the latest version for this rule. `-` means never.
- **Carry:** whether a finding of this rule may be carried unchanged from an earlier review of the same change, as [Incremental task lines](findings-schema.md#incremental-task-lines) describes. `file` only when the audit below shows the rule's evidence is the target file's own bytes, at the base and the head, and nothing else: no other file, no provider fact, no title or body, no verification result, no example, no documentation, no generated content, and no scope, compatibility or `review.*` judgement. Every other rule is `never`, and so is a rule added without an audit.

`tests/skills-test.sh` checks that every `rule_id` the skill names has exactly one row here, and no other row, that each row's carry value is `file` or `never`, and that every `file` row has one line in [Carry audit](#carry-audit) and no other rule does.

| `rule_id` | Provider facts | Page facts | Page entry when | Carry |
|-----------|----------------|------------|-----------------|-------|
| `compat.break-unexplained` | none | - | - | never |
| `compat.claim-contradicts-analysis` | none | - | - | never |
| `compat.default-changed` | none | - | - | never |
| `compat.generated-policy-narrowed` | none | - | - | never |
| `compat.provider-floor-raised` | schema | - | - | never |
| `compat.resource-address-changed` | none | - | - | never |
| `compat.type-narrowed` | none | - | - | never |
| `compat.variable-now-required` | none | - | - | never |
| `compat.variable-removed` | none | - | - | never |
| `compat.version-constraint-raised` | none | - | - | never |
| `coverage.argument-above-min-version` | schema | - | - | never |
| `coverage.attribute-not-output` | schema | prose-only notes: an attribute set on one branch only | The change adds or edits an output that reads an attribute of the type. | never |
| `coverage.block-attribute-mismatch` | schema | - | - | never |
| `coverage.default-for-required-argument` | page | documented defaults | The change adds or changes a default of an input that backs an argument of the type. | never |
| `coverage.deprecated-argument` | schema | - | - | never |
| `coverage.enum-value-unknown` | page | allowed values | The change sets a literal on an argument of the type, in the module or an example. | never |
| `coverage.mutual-exclusion-unguarded` | page | conflicts | The change adds or edits a block of the type. | never |
| `coverage.optional-argument-unexposed` | schema | documented omissions | The change adds a `resource` block of the type. | never |
| `coverage.required-argument-unreachable` | schema | - | - | never |
| `coverage.unknown-argument` | schema | validator limits | The change adds or edits a block of the type that repeats a nested block. | never |
| `examples.argument-undemonstrated` | none | - | - | never |
| `examples.custom-input-required` | none | - | - | never |
| `examples.disabled-call-missing` | none | - | - | never |
| `examples.docs-incomplete` | none | - | - | never |
| `examples.example-broken` | schema | allowed values, one-ofs | An example the change adds or edits, or one of the version bump only examples, has a block of the type. | never |
| `examples.example-broken-at-base` | none | - | - | never |
| `examples.feature-undemonstrated` | none | - | - | never |
| `examples.real-domain-zone` | none | - | - | never |
| `examples.stale-reference` | none | - | - | never |
| `examples.submodule-missing` | none | - | - | never |
| `examples.versions-missing` | none | - | - | never |
| `profile.changelog-handwritten` | none | - | - | never |
| `profile.commit-type-mismatch` | none | - | - | never |
| `profile.generated-content-handwritten` | none | - | - | never |
| `profile.layout-divergence` | none | - | - | never |
| `profile.migration-notes-misplaced` | none | - | - | never |
| `profile.nonstandard-config-file` | none | - | - | never |
| `profile.owner-identifier` | none | - | - | never |
| `profile.provider-meta-missing` | none | - | - | never |
| `profile.putin-khuylo-missing` | none | - | - | never |
| `profile.region-not-allowed` | none | - | - | file |
| `profile.release-config-changed` | none | - | - | never |
| `profile.required-file-missing` | none | - | - | never |
| `profile.template-drift` | none | - | - | never |
| `profile.title-misspelling` | none | - | - | never |
| `profile.title-uninformative` | none | - | - | never |
| `profile.unrelated-change-bundled` | none | - | - | never |
| `review.check-not-run` | none | - | - | never |
| `review.no-change-identified` | none | - | - | never |
| `review.path-missing` | none | - | - | never |
| `review.quoted-claim-unverifiable` | none | - | - | never |
| `review.untrusted-instruction` | none | - | - | never |
| `scope.boundary` | none | - | - | never |
| `scope.composition` | none | - | - | never |
| `scope.layout` | none | - | - | never |
| `scope.module-call` | none | - | - | never |
| `scope.new-module` | none | - | - | never |
| `scope.new-submodule` | none | - | - | never |
| `scope.pre-commit-hook` | none | - | - | never |
| `scope.profile-file` | none | - | - | never |
| `scope.provider` | none | - | - | never |
| `scope.readme-banner` | none | - | - | never |
| `scope.tests` | none | - | - | never |
| `scope.tooling` | none | - | - | never |
| `structure.argument-order` | none | - | - | file |
| `structure.arn-partition-hardcoded` | none | - | - | file |
| `structure.comment-redundant` | none | - | - | file |
| `structure.comment-unsourced` | none | - | - | file |
| `structure.copied-content-unattributed` | none | - | - | never |
| `structure.create-flag-ignored` | none | - | - | never |
| `structure.docs-contradict-code` | page | data source behaviour | A changed block, output, local or documentation line depends on what a data source of the type does with its inputs. | never |
| `structure.feature-above-version-floor` | none | - | - | never |
| `structure.flag-polarity` | none | - | - | file |
| `structure.grouping` | none | - | - | never |
| `structure.input-ignored-in-branch` | none | - | - | never |
| `structure.insecure-default` | none | - | - | never |
| `structure.missing-description` | none | - | - | file |
| `structure.multi-provider` | none | - | - | file |
| `structure.output-no-try` | none | - | - | never |
| `structure.passthrough-default-drift` | none | - | - | never |
| `structure.passthrough-field-drift` | none | - | - | never |
| `structure.schema-shape-flattened` | schema | - | - | never |
| `structure.sibling-argument-omitted` | schema | - | - | never |
| `structure.sibling-block-asymmetry` | schema | - | - | never |
| `structure.suppression-unexplained` | none | - | - | file |
| `structure.validation-message-uninformative` | none | - | - | never |
| `structure.validation-missing` | none | - | - | never |
| `structure.validation-overreaching` | none | - | - | never |
| `structure.variable-untyped` | none | - | - | file |
| `structure.version-floor-understated` | none | - | - | never |
| `structure.wrong-file` | none | - | - | never |

## Carry Audit

The evidence each `file` rule reads, all of it in the target file:

- `profile.region-not-allowed`: A region literal the change touches in the target, against the two the profile allows.
- `structure.argument-order`: `count`, `for_each`, `tags` and `labels` positions inside a resource block of the target, and whether the change touched that block, read from the target at the base and the head.
- `structure.arn-partition-hardcoded`: An ARN literal the change adds in the target; `local.partition` can always be added, so no other file decides it.
- `structure.comment-redundant`: A comment the change adds in the target, read against the code beside it in the same file.
- `structure.comment-unsourced`: A comment the change adds in the target and whether it carries a source link and a date.
- `structure.flag-polarity`: A new flag variable's name and default, both in its own block of the target.
- `structure.missing-description`: A new variable or output block of the target without a `description`.
- `structure.multi-provider`: A `provider` block with an `alias`, or a `provider` or `providers` argument, in the target, and whether the target's path is under `examples/`.
- `structure.suppression-unexplained`: A suppression comment the change adds in the target, and the comment lines next to it.
- `structure.variable-untyped`: A new variable block of the target without a `type`, or with `any` and no comment giving the reason.
