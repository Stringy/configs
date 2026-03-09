# General Context for Claude

## Primary Work Context

I work primarily on **StackRox/RHACS** (Red Hat Advanced Cluster Security for Kubernetes), a Kubernetes security platform focused on runtime detection and policy enforcement.

### Key StackRox Components I Work On
- **Detection Engine**: Runtime detection of security threats in Kubernetes environments
- **Policy Matching**: Complex policy evaluation using QueryTree and boolean logic
- **File Access Monitoring**: Detection of file system access patterns for security policies
- **Collector**: eBPF-based system monitoring component for host and container events
- **Runtime Detection**: Node-level and deployment-level security policies

### StackRox Codebase Locations
- Main: `/home/ghutton/code/go/src/github.com/stackrox/stackrox`
- Collector: `/home/ghutton/code/go/src/github.com/stackrox/collector`
- FACT: `/home/ghutton/code/go/src/github.com/stackrox/fact`

## Programming Languages & Tools

### Primary Languages
- **Go**: Main language for StackRox development
  - Heavy use of Protocol Buffers
  - Kubernetes API interactions
  - eBPF/BPF programming
- **Rust**: For game development side projects (ECS, macroquad)

### LSP Plugins Enabled
- `gopls-lsp` - Go language server
- `rust-analyzer-lsp` - Rust language server

## Common Development Patterns

### Code Style Preferences
- **Follow existing patterns**: When adding new code, always follow the style and patterns already present in the file
- **Minimize test bloat**: Deduplicate test cases based on behavior rather than having redundant tests
- **Keep it simple**: Don't over-engineer solutions; focus on what's actually needed
- **Pragmatic testing**: Test cases should be useful and meaningful, not just null checks

### Testing Approach
- Use `go test -test.v ./pkg/...` for running tests
- Test files to reference:
  - `node_policies_test.go` - For node-level file access policies
  - `deployment_policies_test.go` - For deployment-level policies
  - `node_criteria_test.go` - For policy criteria matching
- When adding tests, group successful cases before failure cases

### File Path Matching
- Working on glob/wildcard support for file path matching in policies
- Using `pkg/fileutils/match.go` for custom path matching (not stdlib's filepath.Match)
- Need to support globstar `**` pattern for recursive directory matching
- Preference for using third-party glob libraries when stdlib doesn't support needed features

### CI/CD Patterns
- GitHub workflows in `.github/workflows/`
- PR comment posting patterns - check existing workflows for examples
- Conditional workflow runs based on changed files

## Common Investigation Patterns

### Debugging Approaches
When I ask you to investigate issues, I typically want you to:
1. Read the relevant code files first
2. Look at error messages and trace through the logic
3. Check test failures and explain what's happening
4. Suggest fixes based on the codebase patterns

### eBPF/BPF Specific
- Watch for BPF map size limits and `max_entries` constraints
- Error E2BIG (os error 7) often relates to BPF map limits or argument sizes
- BPF code is in the collector repository

## Kubernetes Context

### Common K8s Operations
- ConfigMaps: Used for storing configuration data
  - Can mount as volumes into pods
  - Data is represented as files when mounted (key = filename, value = file contents)
  - Use YAML for structured data in ConfigMaps
- Deployment editing: Adding volume mounts for ConfigMaps

### Protocol Buffers
- Heavy use of protobuf definitions
- Often convert proto → JSON → YAML for storage/configuration

## Side Projects

### ASCII Game Development
- Building a Dwarf Fortress/Rogue-like game in Rust
- Tech stack exploration: ratatui → bracket-lib → macroquad + specs (ECS)
- CP437 glyphs for ASCII graphics
- Requirements:
  - Wayland support (no X11)
  - ECS architecture (specs library)
  - World simulation with terrain (500x500+ grids)
  - Viewport/camera system for large maps
  - Support for terrain modification (digging, construction)
- Current: Using macroquad for rendering, specs for ECS
- Tiles defined in `assets/tiles.yaml`

## Workflow Preferences

### Session Management
- Use `/resume` to continue previous conversations
- Use `exit` or `q` to end sessions
- Use `/plan` when working on complex multi-step changes

### When to Use Planning Mode
- For complex refactoring or architectural changes
- When modifying detection/policy engine logic
- When adding new major features to StackRox

## Technical Interests

- **Security**: Runtime detection, policy enforcement, eBPF monitoring
- **Systems Programming**: Low-level Linux, BPF, file system monitoring
- **Game Development**: ASCII games, ECS architecture, procedural generation
- **Testing**: Comprehensive test coverage with meaningful test cases

## Common Gotchas to Remember

### StackRox/Security
- Detection policies have both node-level and deployment-level variants
- File access policies need to detect both Effective Path and Actual Path
- Policy violations should be deduplicated to avoid duplicate alerts

### Go Development
- Always check for existing test patterns before adding new tests
- Follow the codebase's existing structure for new features
- stdlib `filepath.Match` doesn't support `**` globstar

### Game Development
- Terminal emulators have limitations for complex graphics
- Square tiles in terminals require special handling
- Wayland compatibility is essential

## Key Files & Patterns

When working on detection/policy features, reference these files:
- `pkg/booleanpolicy/` - Policy evaluation logic
- `pkg/fileutils/match.go` - File path matching
- Test files: `*_test.go` for patterns to follow

## Questions I Frequently Ask

- "How does [X component] work?" - Want architectural understanding
- "Can you investigate why [error]?" - Debugging assistance
- "Tell me about [technology/concept]" - Learning new things
- "Look at [file] and tell me what's wrong" - Code review help
- "Add test cases for [feature]" - Test coverage improvements
- "Follow the existing patterns in [file]" - Consistency is important

## Reminder for Claude

When helping me:
- **Read files first** before proposing changes
- **Follow existing code patterns** in the file you're modifying
- **Run tests** to verify changes work
- **Deduplicate** rather than add redundant code/tests
- **Investigate thoroughly** when I report errors
- **Keep it simple** - don't over-engineer
- **Why is more important than what** - don't over comment on code

### Code Intelligence

Prefer LSP over Grep/Glob/Read for code navigation:
- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

Before renaming or changing a function signature, use
`findReferences` to find all call sites first.

Use Grep/Glob only for text/pattern searches (comments,
strings, config values) where LSP doesn't help.

After writing or editing code, check LSP diagnostics before
moving on. Fix any type errors or missing imports immediately.
