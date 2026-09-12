---
name: drawio
description: "Use when user requests diagrams, flowcharts, architecture charts, or visualizations. Also use proactively when explaining systems with 3+ components, complex data flows, or relationships that benefit from visual representation. Generates .drawio XML files and exports to PNG/SVG/PDF locally using the native draw.io desktop CLI."
license: MIT
homepage: https://github.com/Agents365-ai/drawio-skill
compatibility: "Requires draw.io desktop app CLI on PATH (macOS/Linux/Windows). Self-check step requires a vision-enabled model (e.g., Claude Sonnet/Opus); gracefully skipped if unavailable."
---

# Draw.io Diagrams

## Overview

Generate `.drawio` XML files and export to PNG/SVG/PDF/JPG locally using the native draw.io desktop app CLI.

**Supported formats:** PNG, SVG, PDF, JPG — no browser automation needed.

PNG, SVG, and PDF exports support `--embed-diagram` (`-e`) — the exported file contains the full diagram XML, so opening it in draw.io recovers the editable diagram. Use double extensions (`name.drawio.png`) to signal embedded XML.

## When to Use

**Explicit triggers:** user says "diagram", "visualize", "flowchart", "draw", "architecture diagram", "process flow", "ER diagram", "UML", "sequence diagram", "class diagram", "neural network", "model architecture"

**Proactive triggers:**

- Explaining a system with 3+ interacting components
- Describing a multi-step process or decision tree
- Comparing architectures or approaches side by side

**Skip when:** a simple list or table suffices, or user is in a quick Q&A flow

## Workflow

Before starting the workflow, assess whether the user's request is specific enough. If key details are missing, ask 1-3 focused questions:

- **Diagram type** — which preset? (ERD, UML, Sequence, Architecture, ML/DL, Flowchart, or general)
- **Output format** — PNG (default), SVG, PDF, or JPG?
- **Scope/fidelity** — how many components? Any specific technologies or labels?

Skip clarification if the request already specifies these details or is clearly simple (e.g., "draw a flowchart of X").

1. **Check deps** — verify `draw.io --version` succeeds; note platform for correct CLI path
2. **Plan** — identify shapes, relationships, layout (LR or TB), group by tier/layer
3. **Generate** — write `.drawio` XML file to disk (output dir same as user's working dir)
4. **Export draft** — run CLI to produce PNG for preview
5. **Self-check** — use the agent's built-in vision capability to read the exported PNG, catch obvious issues, auto-fix before showing user (requires a vision-enabled model such as Claude Sonnet/Opus)
6. **Review loop** — show image to user, collect feedback, apply targeted XML edits, re-export, repeat until approved
7. **Final export** — export approved version to all requested formats, report file paths

### Step 5: Self-Check

After exporting the draft PNG, use the agent's vision capability (e.g., Claude's image input) to read the image and check for these issues before showing the user. If the agent does not support vision, skip self-check and show the PNG directly:

| Check               | What to look for                                          | Auto-fix action                                                                                     |
| ------------------- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Overlapping shapes  | Two or more shapes stacked on top of each other           | Shift shapes apart by ≥200px                                                                        |
| Clipped labels      | Text cut off at shape boundaries                          | Increase shape width/height to fit label                                                            |
| Missing connections | Arrows that don't visually connect to shapes              | Verify `source`/`target` ids match existing cells                                                   |
| Off-canvas shapes   | Shapes at negative coordinates or far from the main group | Move to positive coordinates near the cluster                                                       |
| Edge-shape overlap  | An edge/arrow visually crosses through an unrelated shape | Add waypoints (`<Array as="points">`) to route around the shape, or increase spacing between shapes |
| Stacked edges       | Multiple edges overlap each other on the same path        | Distribute entry/exit points across the shape perimeter (use different exitX/entryX values)         |

- Max **2 self-check rounds** — if issues remain after 2 fixes, show the user anyway
- Re-export after each fix and re-read the new PNG

### Step 6: Review Loop

After self-check, show the exported image and ask the user for feedback.

**Targeted edit rules** — for each type of feedback, apply the minimal XML change:

| User request            | XML edit action                                                                    |
| ----------------------- | ---------------------------------------------------------------------------------- |
| Change color of X       | Find `mxCell` by `value` matching X, update `fillColor`/`strokeColor` in `style`   |
| Add a new node          | Append a new `mxCell` vertex with next available `id`, position near related nodes |
| Remove a node           | Delete the `mxCell` vertex and any edges with matching `source`/`target`           |
| Move shape X            | Update `x`/`y` in the `mxGeometry` of the matching `mxCell`                        |
| Resize shape X          | Update `width`/`height` in the `mxGeometry` of the matching `mxCell`               |
| Add arrow from A to B   | Append a new `mxCell` edge with `source`/`target` matching A and B ids             |
| Change label text       | Update the `value` attribute of the matching `mxCell`                              |
| Change layout direction | **Full regeneration** — rebuild XML with new orientation                           |

**Rules:**

- For single-element changes: edit existing XML in place — preserves layout tuning from prior iterations
- For layout-wide changes (e.g., swap LR↔TB, "start over"): regenerate full XML
- Overwrite the same `{name}.png` each iteration — do not create `v1`, `v2`, `v3` files
- After applying edits, re-export and show the updated image
- Loop continues until user says approved / done / LGTM
- **Safety valve:** after 5 iteration rounds, suggest the user open the `.drawio` file in draw.io desktop for fine-grained adjustments

### Step 7: Final Export

Once the user approves:

- Export to all requested formats (PNG, SVG, PDF, JPG) — default to PNG if not specified
- Report file paths for both the `.drawio` source file and exported image(s)
- **Auto-launch:** offer to open the `.drawio` file in draw.io desktop for fine-tuning — `open diagram.drawio` (macOS), `xdg-open` (Linux), `start` (Windows)
- Confirm files are saved and ready to use

## Draw.io XML Structure

XML スケルトン・shape / edge のプロパティ・レイアウト指針は [references/xml-structure.md](references/xml-structure.md) を参照。

## Export

### Commands

```bash
# macOS — Homebrew (draw.io in PATH)
draw.io -x -f png -e -s 2 -o diagram.drawio.png input.drawio

# macOS — full path (if not in PATH)
/Applications/draw.io.app/Contents/MacOS/draw.io -x -f png -e -s 2 -o diagram.drawio.png input.drawio

# Windows
"C:\Program Files\draw.io\draw.io.exe" -x -f png -e -s 2 -o diagram.drawio.png input.drawio

# Linux (headless — requires xvfb-run)
xvfb-run -a draw.io -x -f png -e -s 2 -o diagram.drawio.png input.drawio

# SVG export
draw.io -x -f svg -o diagram.svg input.drawio

# PDF export
draw.io -x -f pdf -o diagram.pdf input.drawio
```

**Key flags:**

- `-x` — export mode (required)
- `-f` — format: `png`, `svg`, `pdf`, `jpg`
- `-e` — embed diagram XML in output (PNG, SVG, PDF only) — exported file remains editable in draw.io
- `-s` — scale: `1`, `2`, `3` (2 recommended for PNG)
- `-o` — output file path (use `.drawio.png` double extension when embedding)
- `-b` — border width around diagram (default: 0, recommend 10)
- `-t` — transparent background (PNG only)
- `--page-index 0` — export specific page (default: all)

### Browser fallback (no CLI needed)

When the draw.io desktop CLI is unavailable, generate a browser-editable URL by deflate-compressing and base64-encoding the XML:

```bash
# Encode .drawio XML into a diagrams.net URL
python3 -c "
import zlib, base64, urllib.parse, sys
xml = open(sys.argv[1]).read()
compressed = zlib.compress(xml.encode('utf-8'), 9)
encoded = base64.urlsafe_b64encode(compressed).decode('utf-8')
print('https://viewer.diagrams.net/?tags=%7B%7D&lightbox=1&edit=_blank#R' + urllib.parse.quote(encoded, safe=''))
" input.drawio
```

This produces a client-side URL that opens the diagram in the browser for viewing and editing. No data is uploaded to any server — the entire diagram XML is encoded in the URL fragment (after `#`), which is never sent to the server. Useful when the user cannot install the desktop app.

### Fallback chain

When tools are unavailable, degrade gracefully:

| Scenario                               | Behavior                                                                                              |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| draw.io CLI missing, Python available  | Use browser fallback (diagrams.net URL)                                                               |
| draw.io CLI missing, Python missing    | Generate `.drawio` XML only; instruct user to open in draw.io desktop or diagrams.net manually        |
| Vision unavailable for self-check      | Skip self-check (step 5); proceed directly to showing user the exported PNG                           |
| Export fails (Chromium/display issues) | On Linux, retry with `xvfb-run -a`; if still failing, deliver `.drawio` XML and suggest manual export |

### Checking if draw.io is in PATH

```bash
# Try short command first
if command -v draw.io &>/dev/null; then
  DRAWIO="draw.io"
elif [ -f "/Applications/draw.io.app/Contents/MacOS/draw.io" ]; then
  DRAWIO="/Applications/draw.io.app/Contents/MacOS/draw.io"
else
  echo "draw.io not found — install from https://github.com/jgraph/drawio-desktop/releases"
fi
```

## Common Mistakes

| Mistake                                  | Fix                                                                                  |
| ---------------------------------------- | ------------------------------------------------------------------------------------ |
| Missing `id="0"` and `id="1"` root cells | Always include both at the top of `<root>`                                           |
| Shapes not connected                     | `source` and `target` on edge must match existing shape `id` values                  |
| Export command not found on macOS        | Try full path `/Applications/draw.io.app/Contents/MacOS/draw.io`                     |
| Linux: blank/error output headlessly     | Prefix command with `xvfb-run -a`                                                    |
| PDF export fails                         | Ensure Chromium is available (draw.io bundles it on desktop)                         |
| Background color wrong in CLI export     | Known CLI bug; add `--transparent` flag or set background via style                  |
| Overlapping shapes                       | Scale spacing with complexity (200–350px); leave routing corridors                   |
| Edges crossing through shapes            | Add waypoints, distribute entry/exit points, or increase spacing                     |
| Special characters in `value`            | Use XML entities: `&amp;` `&lt;` `&gt;` `&quot;`                                     |
| Iteration loop never ends                | After 5 rounds, suggest user open .drawio in draw.io desktop for fine-tuning         |
| Self-closing edge `mxCell`               | Always use expanded form with `<mxGeometry>` child — self-closing edges won't render |
| `--` inside XML comments                 | Illegal per XML spec — use single hyphens or rephrase                                |
| Arrowhead overlaps bend                  | Final edge segment before target must be ≥20px — increase spacing or add waypoints   |
| Literal `\n` in label text               | Use `&#xa;` for line breaks in `value` attributes                                    |

## Diagram Type Presets

図種別ごとのプリセット定義は [references/diagram-presets.md](references/diagram-presets.md) を参照。

## AWS Architecture Icons

AWS アイコンのスタイルテンプレートとカテゴリ色は [references/aws-icons.md](references/aws-icons.md) を参照。
