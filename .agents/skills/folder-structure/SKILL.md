---
name: folder-structure
description: Use before any structural change — adding, moving, or renaming files and directories in the Jocker repository — and after it, to keep FOLDER_STRUCTURE_SPEC.md authoritative. Covers the one-type-per-file rule, source-to-test placement mapping, target boundaries, and artifact locations.
---

# Folder structure

Read [FOLDER_STRUCTURE_SPEC.md](../../../FOLDER_STRUCTURE_SPEC.md) before adding,
moving or renaming files. It owns placement, type/file conventions and target
boundaries. [AGENTS.md](../../../AGENTS.md) owns the stack and verification policy.

## Procedure

1. Find the owning layer and test location in the specification. For a new
   placement convention, explain the reason and update that source in the same task.
2. Add or move the file and update its consumers. Keep filesystem paths and Xcode
   groups aligned; register Swift sources in the correct Sources build phases.
   Directory alone does not establish membership, especially for training sources.
3. Update the specification when a layer, placement mapping, build boundary or
   concrete referenced path changes, including tooling outside Xcode. Adding a file
   within an existing area needs no inventory entry. Use checked repo-relative
   paths and explicit templates as described there; keep task status in backlog.
4. For skill/profile additions, removals, renames or metadata changes, regenerate
   the catalog according to the root maintenance instructions.
5. Use the root harness for verification. Report old/new paths, target membership
   changes and the resulting check evidence; do not repeat covered tests.

Game rule texts are product contracts: changing them is not a side effect of
moving source files. Build/test/training outputs stay in gitignored `.derivedData/`.
