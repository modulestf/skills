# Findings Schema

> **Part of:** [terraform-module-reviewer](../SKILL.md)
> **Schema version:** 3
> **Status:** This repository is the source of truth for the findings format. Alignment with core session state is deferred: that session state does not exist yet, and when it does it conforms to this file rather than the other way round. The schema is kept small so a later revision is cheap. A change to any required field, to the severity enum, or to the `rule_id` rules raises the schema version. Version 3 added the `scope.` prefix for Check F; every field and every other rule is unchanged. The [Suggested Fix Contract](#suggested-fix-contract) sets what the text of `suggested_fix` says. It adds no field and changes no type, required status or `rule_id` rule, so the version stays 3, and a finding written before it is still valid, only harder to apply. Version 2 changed the `rule_id` rules: a run may report a name that is not in the registry, and says so in the finding and alongside the list. Version 1 told the run to add the name to SKILL.md, which a read-only skill cannot do.

A review returns a list of findings. Each finding is one defect in one place, described well enough that it can be referenced later without re-running the review.

## Required Fields

Every finding carries all seven fields. Only `line` may be null; the rest are always present and non-empty.

| Field | Type | Null allowed | Rule |
|-------|------|--------------|------|
| `id` | string | no | Identifies the finding inside one review run. Assign sequentially in output order: `F-001`, `F-002`, and so on. Not stable across runs; use `rule_id` plus `file` for that. |
| `rule_id` | string | no | Names the rule that produced the finding. Stable across runs and across module repositories, so a finding can be referenced or suppressed later. Format below. |
| `severity` | enum | no | Exactly one of `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. No other value, no sub-levels, no numeric score. Assignment rules are in [SKILL.md](../SKILL.md#severity-levels) and the check reference files it links. |
| `file` | string | no | Path relative to the module root, using forward slashes. For a defect with no single file, use the module root as `.`. |
| `line` | integer or null | yes | 1-based line in `file` in the reviewed revision. Null for a file-level or module-level finding, for example a missing file. A finding on a block as a whole - a variable, an output, a resource - takes the block's first line, the `variable "<name>"` line for a variable, never a line inside it such as its `default`, unless the rule names another line. |
| `summary` | string | no | One sentence, plain text, stating what is wrong and where it bites. Present tense. No remediation. Plain voice: no praise, no "not X but Y" contrast, no stock words such as crucial, robust, seamless or comprehensive. A consumer renders the summary verbatim, so it has to read well as written. |
| `suggested_fix` | string | no | The change that would resolve the finding, in one of the three forms the [Suggested Fix Contract](#suggested-fix-contract) defines. Describes; never applies. Never a command to run. When no single fix follows from the evidence, it opens with `needs decision:` and states what has to be decided. |

No other field is required. A consumer that needs more may add fields, but a finding is valid with these seven and every consumer must accept a finding that carries only these.

## Suggested Fix Contract

`suggested_fix` has two readers. A person makes the change by hand from it, and the maintainer skill's [Applying a review finding](../../terraform-module-maintainer/references/targeted-change.md#applying-a-review-finding) makes it without guessing, when the person asks it to. Both read the same text, so the text carries everything the change needs. It takes one of three forms, told apart by how it opens.

**A code change** is the default form. It says, in plain sentences:

1. **Where.** The file and the anchor the edit goes at. The anchor is a block address - `variable "<name>"`, `output "<name>"`, `resource "<type>" "<name>"`, `data "<type>" "<name>"`, `module "<name>"`, the `locals` block that holds `<name>`, the `terraform` block - or a line in the reviewed revision for text that is not a block, such as a comment. Name the block address when there is one, since lines move. When the edit goes where `file` and `line` already point, the fix names only the anchor. When it goes elsewhere - the finding is on a resource and the fix adds a variable - it names the other file too.
2. **What.** The exact change: add, remove, rename, move or set, of an argument, a block, a variable, an output, a `moved` block, a comment or a file. Name the identifier, and the value whenever the evidence determines it: the default of a new variable, the version of a raised floor, the accepted values of a `validation` block. A new input's type is named when the provider page or the module's code determines it: the object shape of an input that feeds a nested block, its attribute names taken from the arguments the page documents for that block and `optional()` for the Optional ones, or the type of the value the code already passes. A type neither determines, such as a leaf the page gives no type for, is left out, and the fix says the maintainer takes it from the provider documentation through the Terraform MCP tools. The text of a `description` or an `error_message` the change adds or changes is given in full, for the maintainer to use as written: an `error_message` names the accepted values or the bound and interpolates the value received, and a `description` states what the code does. When the content comes from a profile template or a reference section, name that file and heading instead of restating it.
3. **Satisfies.** The section the change satisfies, by file and heading, when the finding's rule rests on a profile or reference section.
4. **Generated content.** When the change adds, removes, renames or retypes a variable or an output, changes a variable's default or either one's description, or moves a module directory's provider or Terraform floor, the fix closes with one sentence naming every generated file or region the change makes stale: `Generated content made stale: the terraform-docs region of modules/file-system/README.md, wrappers/file-system/main.tf.` The set is read as [Check E](check-e-profile.md) reads generated content: the generated regions of the `README.md` in each directory whose inputs, outputs or floors change, and the files a generator writes from that directory, such as its wrapper. The maintainer regenerates them; a fix that leaves them stale leaves a finding behind.

A code change is one change, with everything it needs to hold: a new variable together with the argument that reads it, a `moved` block together with the rename. It stays inside the finding and touches nothing the finding does not name. A fix to an example may add the supporting blocks the example needs to apply, such as a data source for the partition or a KMS key, when the fix names each one; the next review judges them like any other example code. It may be conditional only when the maintainer can settle the condition from the workspace or the provider documentation, and both branches are code changes: `if the page for 6.20 lists <argument>, raise the floor to 6.20; otherwise remove the argument`. An expression that is only evaluated at plan - a `validation` condition, a `precondition` or `postcondition`, an `error_message` interpolation - is written in the plainest form `terraform validate` can type-check, since the maintainer's checks stop at validate: `var.x == null ? [] : var.x` rather than `coalesce(var.x, [])` over a collection. When no such form exists, the fix says the expression is not verified by execution.

**`needs decision:`** opens a fix when more than one change is defensible and choosing is the maintainer's call: compatibility against a feature, two readings of what the author meant, or keeping against dropping an addition. After the prefix, one sentence states what has to be decided, then each option follows as a complete fix in one of the two other forms, lettered `(a)`, `(b)`. The maintainer skill applies none of them until a person chooses. Every rule whose fix is a decision is marked in its check reference.

**`no code change:`** opens a fix that changes no file in the workspace: the title or description of the change, an input the review lacked, a check to re-run, or a repair that belongs to a separate change. After the prefix it says what has to happen, and gives the text when the fix is text, such as a title. Every `review.*` finding takes this form.

Never in a fix: a command to run, a hedge in place of a choice (`consider`, `you may want to`, `optionally`), a change the finding does not name, or text quoted from the change under review beyond identifiers and values. Keep it short: a code change is usually one or two sentences, and a `needs decision:` fix adds one sentence per option. Each option of a `needs decision:` fix names its own generated content, since the options can differ.

Checks A to F each carry a Suggested Fixes table of their rules and the fix each one takes.

## `rule_id` Format

`<check>.<slug>`, lowercase, dot after the check, hyphens inside the slug.

| Check prefix | Produced by |
|--------------|-------------|
| `compat.` | Check A, backwards compatibility |
| `coverage.` | Check B, coverage gaps against the provider schema |
| `structure.` | Check C, module structure |
| `examples.` | Check D, examples |
| `profile.` | Check E, profile conventions |
| `scope.` | Check F, whether an addition belongs in the module |
| `review.` | The review process itself: an input that could not be resolved, a check that could not run, untrusted text that tried to steer the review |

Stability rules:

- A `rule_id` means the same thing forever. To change what a rule detects, add a new `rule_id`; do not redefine an existing one.
- The same defect found in two runs of the same check on the same code yields the same `rule_id`.
- A `rule_id` never encodes a severity, a file, or a line. Those are separate fields, and the same rule can produce different severities in different situations.
- `rule_id` plus `file` plus `rule_id`-specific context is what a suppression list would key on. Suppression itself is not part of this schema and is not implemented.

The names in use are listed per check in the check reference files, and the `review.*` names in [SKILL.md](../SKILL.md); SKILL.md's Final Step states which names form the registry. A review never edits it: Rule 1 makes the reviewer read-only, so a run has no way to add a name and no standing to try.

When a run finds a defect class the registry has no name for, it may use a new name under one of the check prefixes above. Minting a name is a report the run emits, never an edit it makes:

- The new `rule_id` follows the format rules above and sits under the prefix of the check that found the defect.
- The finding's `summary` opens with `New rule_id, not in the registry:` and then states the defect as any other summary does.
- Alongside the findings list, the run states every new `rule_id` it used and the check that produced it. A reader can then tell which names in the list are registry names without opening the registry.

Adding the name to the registry is a separate change, made by a person. Until it is made the name is not a registry name, and a later run that does not produce it again is not a regression.

## Recorded Exceptions

The stability rule above has been broken once. The break is written down here so that a reader of older output knows what the name meant when it was written, and so that a second one has to be written down the same way.

| Date | `rule_id` | What changed | Why |
|------|-----------|--------------|-----|
| 2026-09-22 | `compat.version-constraint-raised` | Narrowed. The name covered any raised version floor. It now covers a raised Terraform core `required_version` floor, or a provider floor crossing a major version. A provider floor raised by a minor or a patch version moved to `compat.provider-floor-raised`. | One name carried one severity, CRITICAL, over two cases with different consequences for a caller, and the minor case blocked a routine provider bump across 26 files in a single pull request. |

Output recorded before that date under `compat.version-constraint-raised` may hold minor and patch cases. Compared against a later run it shows as removals and additions on the same files. That is the rename at work, and it is not a regression. [fixtures.md](fixtures.md) marks the measurements it holds.

No rule text changed, so the schema version is unchanged. A future narrowing follows the stability rule above and takes a new name. This table records what already happened; adding a row to it does not license a redefinition.

The `review.` prefix belongs to the review process itself: an input that could not be resolved, a check that could not run, untrusted text that tried to steer the review. None of those is a defect in the module, so a `review.*` finding never carries `CRITICAL`.

## Ordering

Findings are ordered by severity, `CRITICAL` first, then by `file` alphabetically, then by `line` ascending with null last. `id` is assigned after ordering, so `F-001` is always the most severe finding of the run.

## Shape

The list is the whole result. An empty list is a valid, clean review.

```json
[
  {
    "id": "F-001",
    "rule_id": "compat.variable-removed",
    "severity": "CRITICAL",
    "file": "variables.tf",
    "line": 42,
    "summary": "Variable \"log_retention_days\" is removed, so every configuration that sets it fails to plan.",
    "suggested_fix": "Restore `variable \"log_retention_days\"` in `variables.tf` with its base type and default. If another input replaces it, keep this one, mark it deprecated in its description with the replacement's name, and feed the replacement from it."
  },
  {
    "id": "F-002",
    "rule_id": "examples.submodule-missing",
    "severity": "HIGH",
    "file": "modules/logging",
    "line": null,
    "summary": "The submodule added by this change has no example, so nothing exercises it standalone.",
    "suggested_fix": "Add `examples/logging/` with a `main.tf` that calls `../../modules/logging` and a `module \"disabled\"` call with `create = false`, a `versions.tf` copied from a sibling example, and a `README.md` from the profile's example README template."
  }
]
```

Presentation is not part of the schema. A consumer may render the same findings as a table, a list, or line-anchored annotations, as long as every required field survives the rendering.
