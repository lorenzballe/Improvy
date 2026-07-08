# Graphify Technical Setup

## Prerequisites

- Python 3.10+
- Node.js (optional, for MCP server)
- Claude Code (for skill integration)

## Installation

### Via PyPI (recommended)

```bash
pip install graphifyy
```

> **Windows:** If `graphify` not recognized, add Python Scripts to PATH:
> `%APPDATA%\Python\Python3xx\Scripts` (replace `3xx` with your version)

> **macOS externally managed:** Use `pipx install graphifyy` instead

### Verify Installation

```bash
graphify --version
# Output: graphify 0.9.9
```

## Claude Code Integration

### Method 1: Auto (Recommended)

In Claude Code, type `/graphify` and Claude will suggest it as a skill.

### Method 2: Manual

Create skill directory:

```bash
mkdir -p ~/.claude/skills/graphify
```

Fetch skill file:

```bash
curl -fsSL https://raw.githubusercontent.com/safishamsi/graphify/v1/skills/graphify/skill.md \
  > ~/.claude/skills/graphify/SKILL.md
```

### Method 3: Global Install

```bash
graphify install
# Installs to ~/.claude/skills/graphify automatically
```

## Configuration

### Project-Level Config

Create `.graphify.json` in project root:

```json
{
  "mode": "standard",
  "languages": [
    "dart",
    "swift",
    "kotlin",
    "python",
    "markdown"
  ],
  "edge_modes": [
    "EXTRACTED",
    "INFERRED"
  ],
  "inferred_edge_limit": 50,
  "similarity_threshold": 0.75,
  "cache_strategy": "sha256",
  "cache_dir": "graphify-out/cache",
  "output_dir": "graphify-out",
  "auto_sync": false,
  "git_hook": false,
  "export_formats": {
    "html": true,
    "json": true,
    "obsidian": false,
    "wiki": false,
    "svg": false,
    "graphml": false,
    "neo4j": false
  },
  "extraction": {
    "code": {
      "extract_functions": true,
      "extract_classes": true,
      "extract_imports": true,
      "extract_type_hints": true,
      "max_depth": 5
    },
    "docs": {
      "extract_headings": true,
      "extract_code_blocks": true,
      "extract_links": true
    },
    "images": {
      "extract_text_ocr": false,
      "extract_diagrams": true,
      "extract_objects": true
    }
  },
  "node_ranking": {
    "betweenness_centrality": 0.3,
    "degree_centrality": 0.3,
    "closeness_centrality": 0.2,
    "pagerank": 0.2
  }
}
```

### Environment Variables

```bash
# .env.graphify
GRAPHIFY_DEBUG=false
GRAPHIFY_LOG_LEVEL=info
GRAPHIFY_CACHE_DIR=graphify-out/cache
GRAPHIFY_OUTPUT_DIR=graphify-out
GRAPHIFY_PYTHON_PATH=/usr/bin/python3
```

## Usage

### Basic Commands

```bash
# Map current directory
graphify .

# Map specific folder
graphify ./lib

# Deep extraction (more inferred edges)
graphify ./lib --mode deep

# Update only changed files
graphify ./lib --update

# Watch mode (auto-sync on file changes)
graphify ./lib --watch

# Watch with notifications
graphify ./lib --watch --notify
```

### Query Commands

```bash
# Query the graph
graphify query "what connects A to B?"

# Find path between two nodes
graphify path "NodeA" "NodeB"

# Explain a node
graphify explain "ConceptName"

# List all god nodes
graphify god-nodes

# List communities
graphify communities
```

### Add External Sources

```bash
# Fetch and extract arXiv paper
graphify add https://arxiv.org/abs/1706.03762

# Fetch Twitter thread
graphify add https://x.com/user/status/123456

# Clone and graph repo
graphify add https://github.com/org/repo
```

### Export Formats

```bash
# HTML interactive graph
graphify . --html
# → graphify-out/graph.html

# Obsidian vault
graphify . --obsidian
# → graphify-out/obsidian/

# Wikipedia-style wiki
graphify . --wiki
# → graphify-out/wiki/index.md + articles/

# SVG export
graphify . --svg
# → graphify-out/graph.svg

# GraphML (Gephi/yEd)
graphify . --graphml
# → graphify-out/graph.graphml

# Neo4j Cypher
graphify . --neo4j
# → graphify-out/cypher.txt

# MCP server
graphify . --mcp
# → Starts stdio MCP server
```

### Git Integration

```bash
# Install post-commit hook
graphify hook install

# Uninstall hook
graphify hook uninstall

# Check hook status
graphify hook status
```

## Output Structure

After running `graphify .`:

```
improvy_flutter/
└── graphify-out/
    ├── graph.html              ← Interactive visualization
    ├── graph.json              ← Persistent graph data
    ├── GRAPH_REPORT.md         ← Analysis + recommendations
    ├── cache/
    │   ├── lib_main_dart.sha256
    │   ├── pubspec_yaml.sha256
    │   └── ...
    ├── obsidian/               ← Obsidian vault (if --obsidian)
    │   ├── AudioService.md
    │   ├── RevenueCat.md
    │   └── index.md
    └── wiki/                   ← Wiki articles (if --wiki)
        ├── index.md
        ├── AudioService.md
        ├── RevenueCat.md
        └── god_nodes.md
```

### graph.json Structure

```json
{
  "nodes": [
    {
      "id": "AudioService",
      "label": "AudioService",
      "type": "class",
      "file": "lib/services/audio_service.dart",
      "lineno": 42,
      "degree": 47,
      "betweenness": 0.23,
      "community": "audio"
    }
  ],
  "edges": [
    {
      "source": "AudioService",
      "target": "MusicPlayer",
      "type": "EXTRACTED",
      "weight": 0.95,
      "reason": "Direct dependency"
    },
    {
      "source": "AudioService",
      "target": "RevenueCat",
      "type": "INFERRED",
      "weight": 0.62,
      "reason": "Audio playback triggers IAP check"
    }
  ],
  "metrics": {
    "total_nodes": 347,
    "total_edges": 2103,
    "density": 0.034,
    "avg_degree": 12.1,
    "num_communities": 8,
    "token_reduction": 71.5
  }
}
```

## Performance

### Processing Speed

| Corpus Size | Time | Speed |
|-------------|------|-------|
| 5 files | 10s | AST-only (code) |
| 50 files | 1-2m | First run (all files) |
| 50 files | 5-10s | Incremental (--update) |
| 52 files + papers + images | 3-5m | Full extraction + vision |

### Memory Usage

- Base: ~100MB
- Per 100 nodes: ~5MB
- Per 1000 edges: ~2MB
- improvy_flutter (347 nodes, 2103 edges): ~50-100MB

### Token Usage

```
Without Graphify:
  Read 50 files manually → ~450,000 tokens per query

With Graphify:
  Query graph + context → ~6,300 tokens per query

Reduction: 71.5x (scales with corpus size)
```

## Troubleshooting

### "graphify: command not found"

**Windows:**
```bash
# Add to PATH manually
python -m graphifyy --help
```

Or use `pipx`:
```bash
pipx install graphifyy
```

### "No module named tree_sitter"

```bash
# Reinstall with dependencies
pip install --upgrade graphifyy
```

### Graph file too large

```bash
# Use shallow mode
graphify . --mode shallow

# Or exclude large files
# Edit .graphify.json:
# "exclude_patterns": ["node_modules/**", "build/**"]
```

### Cache stale/wrong results

```bash
# Force full rebuild
rm -rf graphify-out/cache
graphify . --update
```

## Integration with Ruflo

### Agent Navigation

Ruflo agents can read the wiki:

```yaml
# In .claude/agents.json
{
  "agent": "CodeReviewer",
  "knowledge_base": "graphify-out/wiki",
  "search_strategy": "hnsw"
}
```

### Custom MCP Tools

Add graphify as MCP:

```bash
# Generate MCP server wrapper
graphify . --mcp > graphify-mcp.json

# Register in claude settings
claude mcp add graphify -- graphify . --mcp
```

---

## Uninstall

```bash
pip uninstall graphifyy

# Remove cached files
rm -rf graphify-out
rm -rf ~/.claude/skills/graphify
```

---

## API Reference

### Python API (Advanced)

```python
from graphifyy import Graphifier

# Create instance
g = Graphifier(
    paths=["./lib", "./ios"],
    mode="standard",
    export_formats=["html", "json", "wiki"]
)

# Run extraction
graph = g.extract()

# Query
paths = g.shortest_path("AuthService", "RevenueCat")
god_nodes = g.get_god_nodes(top_k=10)
communities = g.get_communities()

# Export
g.export_html("output/graph.html")
g.export_json("output/graph.json")
g.export_wiki("output/wiki")
```

### CLI Reference

```bash
graphify [PATH] [OPTIONS]

Options:
  --mode {standard|deep|shallow}     Extraction aggressiveness
  --update                           Only changed files
  --watch                            Auto-sync on changes
  --wiki                             Generate wiki
  --obsidian                         Generate Obsidian vault
  --svg                              Export SVG
  --graphml                          Export GraphML
  --neo4j                            Export Neo4j Cypher
  --mcp                              Start MCP server
  --query TEXT                       Query the graph
  --path SOURCE TARGET               Find shortest path
  --explain NODE                     Explain a node
  --debug                            Verbose logging

Examples:
  graphify .
  graphify ./lib --mode deep --wiki
  graphify . --watch --update
  graphify query "audio to payment flow"
  graphify path RevenueCat AudioService
```

---

## Support

- GitHub: https://github.com/Graphify-Labs/graphify
- Issues: https://github.com/Graphify-Labs/graphify/issues
- Docs: https://github.com/Graphify-Labs/graphify/tree/main/docs
