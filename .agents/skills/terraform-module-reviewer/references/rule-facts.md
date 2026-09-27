# Rule to Provider Fact

> **Part of:** [terraform-module-reviewer](../SKILL.md)
> **Purpose:** For every `rule_id`, which provider facts it needs and whether a type read from [host fact sheets](large-changes.md#budget) also needs its page. Step 1 reads this table to fix the need list. It is static: a rule's need never depends on what a sheet or a page says.

Columns:

- **Provider facts:** `none`, the rule reads no provider schema; `schema`, it needs facts a host fact sheet carries (names, required, optional and computed flags, deprecation, block names, nesting modes, item limits, exported attributes), and a page serves too; `page`, it needs a page fact.
- **Page facts:** the facts only the page has that the rule may need: allowed values, conflicts, validator limits, documented defaults and omissions, data source behaviour, prose-only notes and import.
- **Page entry when:** for a type read from host fact sheets, the condition, taken from the need list, under which the type also takes a page entry at the latest version for this rule. `-` means never.

`tests/skills-test.sh` checks that every `rule_id` the skill names has exactly one row here, and no other row.

| `rule_id` | Provider facts | Page facts | Page entry when |
|-----------|----------------|------------|-----------------|
| `compat.break-unexplained` | none | - | - |
| `compat.claim-contradicts-analysis` | none | - | - |
| `compat.default-changed` | none | - | - |
| `compat.generated-policy-narrowed` | none | - | - |
| `compat.provider-floor-raised` | schema | - | - |
| `compat.resource-address-changed` | none | - | - |
| `compat.type-narrowed` | none | - | - |
| `compat.variable-now-required` | none | - | - |
| `compat.variable-removed` | none | - | - |
| `compat.version-constraint-raised` | none | - | - |
| `coverage.argument-above-min-version` | schema | - | - |
| `coverage.attribute-not-output` | schema | prose-only notes: an attribute set on one branch only | The change adds or edits an output that reads an attribute of the type. |
| `coverage.block-attribute-mismatch` | schema | - | - |
| `coverage.default-for-required-argument` | page | documented defaults | The change adds or changes a default of an input that backs an argument of the type. |
| `coverage.deprecated-argument` | schema | - | - |
| `coverage.enum-value-unknown` | page | allowed values | The change sets a literal on an argument of the type, in the module or an example. |
| `coverage.mutual-exclusion-unguarded` | page | conflicts | The change adds or edits a block of the type. |
| `coverage.optional-argument-unexposed` | schema | documented omissions | The change adds a `resource` block of the type. |
| `coverage.required-argument-unreachable` | schema | - | - |
| `coverage.unknown-argument` | schema | validator limits | The change adds or edits a block of the type that repeats a nested block. |
| `examples.argument-undemonstrated` | none | - | - |
| `examples.custom-input-required` | none | - | - |
| `examples.disabled-call-missing` | none | - | - |
| `examples.docs-incomplete` | none | - | - |
| `examples.example-broken` | schema | allowed values, one-ofs | An example the change adds or edits, or one of the version bump only examples, has a block of the type. |
| `examples.example-broken-at-base` | none | - | - |
| `examples.feature-undemonstrated` | none | - | - |
| `examples.real-domain-zone` | none | - | - |
| `examples.stale-reference` | none | - | - |
| `examples.submodule-missing` | none | - | - |
| `examples.versions-missing` | none | - | - |
| `profile.changelog-handwritten` | none | - | - |
| `profile.commit-type-mismatch` | none | - | - |
| `profile.generated-content-handwritten` | none | - | - |
| `profile.layout-divergence` | none | - | - |
| `profile.migration-notes-misplaced` | none | - | - |
| `profile.nonstandard-config-file` | none | - | - |
| `profile.owner-identifier` | none | - | - |
| `profile.provider-meta-missing` | none | - | - |
| `profile.putin-khuylo-missing` | none | - | - |
| `profile.region-not-allowed` | none | - | - |
| `profile.release-config-changed` | none | - | - |
| `profile.required-file-missing` | none | - | - |
| `profile.template-drift` | none | - | - |
| `profile.title-misspelling` | none | - | - |
| `profile.title-uninformative` | none | - | - |
| `profile.unrelated-change-bundled` | none | - | - |
| `review.check-not-run` | none | - | - |
| `review.no-change-identified` | none | - | - |
| `review.path-missing` | none | - | - |
| `review.quoted-claim-unverifiable` | none | - | - |
| `review.untrusted-instruction` | none | - | - |
| `scope.boundary` | none | - | - |
| `scope.composition` | none | - | - |
| `scope.layout` | none | - | - |
| `scope.module-call` | none | - | - |
| `scope.new-module` | none | - | - |
| `scope.new-submodule` | none | - | - |
| `scope.pre-commit-hook` | none | - | - |
| `scope.profile-file` | none | - | - |
| `scope.provider` | none | - | - |
| `scope.readme-banner` | none | - | - |
| `scope.tests` | none | - | - |
| `scope.tooling` | none | - | - |
| `structure.argument-order` | none | - | - |
| `structure.arn-partition-hardcoded` | none | - | - |
| `structure.comment-redundant` | none | - | - |
| `structure.comment-unsourced` | none | - | - |
| `structure.copied-content-unattributed` | none | - | - |
| `structure.create-flag-ignored` | none | - | - |
| `structure.docs-contradict-code` | page | data source behaviour | A changed block, output, local or documentation line depends on what a data source of the type does with its inputs. |
| `structure.feature-above-version-floor` | none | - | - |
| `structure.flag-polarity` | none | - | - |
| `structure.grouping` | none | - | - |
| `structure.input-ignored-in-branch` | none | - | - |
| `structure.insecure-default` | none | - | - |
| `structure.missing-description` | none | - | - |
| `structure.multi-provider` | none | - | - |
| `structure.output-no-try` | none | - | - |
| `structure.passthrough-default-drift` | none | - | - |
| `structure.passthrough-field-drift` | none | - | - |
| `structure.schema-shape-flattened` | schema | - | - |
| `structure.sibling-argument-omitted` | schema | - | - |
| `structure.sibling-block-asymmetry` | schema | - | - |
| `structure.suppression-unexplained` | none | - | - |
| `structure.validation-message-uninformative` | none | - | - |
| `structure.validation-missing` | none | - | - |
| `structure.validation-overreaching` | none | - | - |
| `structure.variable-untyped` | none | - | - |
| `structure.version-floor-understated` | none | - | - |
| `structure.wrong-file` | none | - | - |
