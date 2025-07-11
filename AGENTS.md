
### Building pdf2htmlEX

This project attempts to create a Homebrew formula for pdf2htmlEX on macOS. The current status is:

- **v1/** - Failed attempt due to DCTStream compilation error when JPEG support is disabled in Poppler
- **v2/** - Planned approach to fix v1 issues by adding jpeg-turbo as vendored dependency

To test the formula:
```bash
# Install from source with verbose output
brew install --build-from-source --verbose v1/Formula/pdf2htmlex.rb

# Check build logs if it fails
brew gist-logs pdf2htmlex

# For development iteration
brew uninstall pdf2htmlex
brew install --build-from-source v1/Formula/pdf2htmlex.rb
```

### Running Tests

After successful installation:
```bash
# Basic functionality test
pdf2htmlEX --version
pdf2htmlEX test.pdf

# Check universal binary
file $(brew --prefix)/bin/pdf2htmlEX
lipo -info $(brew --prefix)/bin/pdf2htmlEX
```

## Architecture

### Core Challenge

pdf2htmlEX requires:
- **Exact versions** of Poppler (24.01.0) and FontForge (20230101) 
- **Static linking** to internal APIs not exposed in standard builds
- **Universal binary** support for Intel and Apple Silicon Macs
- **C++14 compatibility** (modern Poppler uses C++20)

### Solution Architecture

The formula uses a **vendored dependency approach**:

1. **Stage 1**: Build static Poppler with minimal features
2. **Stage 2**: Build static FontForge without GUI
3. **Stage 3**: Patch pdf2htmlEX CMakeLists.txt to use staged libraries
4. **Stage 4**: Build pdf2htmlEX linking against staged dependencies

Key components:
- `v1/Formula/pdf2htmlex.rb` - Main Homebrew formula with vendored deps
- `v1/patches/pdf2htmlEX-poppler24.patch` - Compatibility patch for Poppler 24
- `v2/plan.md` - Strategic plan for v2 implementation to fix DCTStream issue

### Build System Details

pdf2htmlEX expects a specific directory structure:
```
pdf2htmlEX/
   CMakeLists.txt (expects ../poppler/build/libpoppler.a)
   src/
   test/
```

The formula patches these hardcoded paths to point to the staging directory where vendored dependencies are built.


## Development Tips

When modifying the formula:
1. Always test both architectures (x86_64 and arm64)
2. Use `brew gist-logs` to get detailed error logs
3. Check staging directory during build: `/tmp/pdf2htmlex-*/staging/`
4. Ensure static linking with `otool -L` on final binary
5. Test with PDFs containing JPEG images to verify proper support

The pdf2htmlEX source in `v1/pdf2htmlEX-src/` contains the official build scripts in `buildScripts/` which document the exact dependency versions and build flags required.

Read and analyze `PLAN.md` for the key insights. 

---

## 1. Pre-Work Prep

### Before Starting Any Work
- **ALWAYS** read `WORK.md` in the main project folder for work progress.
- Read `README.md` to understand the project.
- STEP BACK and THINK HEAVILY STEP BY STEP about the task.
- Consider alternatives and carefully choose the best option.
- Check for existing solutions in the codebase before starting.

### Project Documentation to Maintain
- `README.md` - purpose and functionality.
- `CHANGELOG.md` - past change release notes (accumulative).
- `PLAN.md` - detailed future goals, clear plan that discusses specifics.
- `TODO.md` - flat simplified itemized `- [ ]`-prefixed representation of `PLAN.md`.
- `WORK.md` - work progress updates.

## 2. General Coding Principles

### Core Development Approach
- Iterate gradually, avoiding major changes.
- Focus on minimal viable increments and ship early.
- Minimize confirmations and checks.
- Preserve existing code/structure unless necessary.
- Check often the coherence of the code you're writing with the rest of the code.
- Analyze code line-by-line.

### Code Quality Standards
- Use constants over magic numbers.
- Write explanatory docstrings/comments that explain what and WHY.
- Explain where and how the code is used/referred to elsewhere.
- Handle failures gracefully with retries, fallbacks, user guidance.
- Address edge cases, validate assumptions, catch errors early.
- Let the computer do the work, minimize user decisions.
- Reduce cognitive load, beautify code.
- Modularize repeated logic into concise, single-purpose functions.
- Favor flat over nested structures.

## 3. Tool Usage (When Available)

### MCP Tools to Consult
- `codex` tool - for additional reasoning, summarization of files and second opinion.
- `context7` tool - for most up-to-date software package documentation.
- `sequentialthinking` tool - to think about the best way to solve tasks.
- `perplexity_ask` - for up-to-date information or context.

### Additional Tools
- Use `tree` CLI app if available to verify file locations.
- Check existing code with `.venv` folder to scan and consult dependency source code.
- Run `DIR="."; uvx codetoprompt --compress --output "$DIR/llms.txt"  --respect-gitignore --cxml --exclude "*.svg,.specstory,*.md,*.txt,ref,testdata,*.lock,*.svg" "$DIR"` to get a condensed snapshot of the codebase into `llms.txt`.

## 4. File Management

### File Path Tracking
- **MANDATORY**: In every source file, maintain a `this_file` record showing the path relative to project root.
- Place `this_file` record near the top:
  - As a comment after shebangs in code files.
  - In YAML frontmatter for Markdown files.
- Update paths when moving files.
- Omit leading `./`.
- Check `this_file` to confirm you're editing the right file.

## 5. Python-Specific Guidelines

### PEP Standards
- PEP 8: Use consistent formatting and naming, clear descriptive names.
- PEP 20: Keep code simple and explicit, prioritize readability over cleverness.
- PEP 257: Write clear, imperative docstrings.
- Use type hints in their simplest form (list, dict, | for unions).

### Modern Python Practices
- Use f-strings and structural pattern matching where appropriate.
- Write modern code with `pathlib`.
- ALWAYS add "verbose" mode loguru-based logging & debug-log.
- Use `uv pip install` instead of `pip install`.
- Prefix Python CLI tools with `python -m` (e.g., `python -m pytest`).

### CLI Scripts Setup
For CLI Python scripts, use `fire` & `rich`, and start with:
```python
#!/usr/bin/env -S uv run -s
# /// script
# dependencies = ["PKG1", "PKG2"]
# ///
# this_file: PATH_TO_CURRENT_FILE
```

### Post-Edit Python Commands
```bash
fd -e py -x uvx autoflake -i {}; fd -e py -x uvx pyupgrade --py312-plus {}; fd -e py -x uvx ruff check --output-format=github --fix --unsafe-fixes {}; fd -e py -x uvx ruff format --respect-gitignore --target-version py312 {}; python -m pytest;
```

## 6. Post-Work Activities

### Critical Reflection
- After completing a step, say "Wait, but" and do additional careful critical reasoning.
- Go back, think & reflect, revise & improve what you've done.
- Don't invent functionality freely.
- Stick to the goal of "minimal viable next version".

### Documentation Updates
- Update `WORK.md` with what you've done and what needs to be done next.
- Document all changes in `CHANGELOG.md`.
- Update `TODO.md` and `PLAN.md` accordingly.

## 7. Work Methodology

### Virtual Team Approach
Be creative, diligent, critical, relentless & funny! Lead two experts:
- **"Ideot"** - for creative, unorthodox ideas.
- **"Critin"** - to critique flawed thinking and moderate for balanced discussions.

Collaborate step-by-step, sharing thoughts and adapting. If errors are found, step back and focus on accuracy and progress.

### Continuous Work Mode
- Treat all items in `PLAN.md` and `TODO.md` as one huge TASK.
- Work on implementing the next item.
- Review, reflect, refine, revise your implementation.
- Periodically check off completed issues.
- Continue to the next item without interruption.

## 9. Additional Guidelines

- Ask before extending/refactoring existing code that may add complexity or break things.
- Work tirelessly without constant updates when in continuous work mode.
- Only notify when you've completed all `PLAN.md` and `TODO.md` items.

## 10. Custom commands: 

When I say "/report", you must: Read all `./TODO.md` and `./PLAN.md` files and analyze recent changes. Document all changes in `./CHANGELOG.md`. From `./TODO.md` and `./PLAN.md` remove things that are done. Make sure that `./PLAN.md` contains a detailed, clear plan that discusses specifics, while `./TODO.md` is its flat simplified itemized `- [ ]`-prefixed representation. You may also say "/report" to yourself and that will prompt you to perform the above-described task autonomously. 

When I say "/work", you must work in iterations like so: Read all `./TODO.md` and `./PLAN.md` files and reflect. Write down the immediate items in this iteration into `./WORK.md` and work on these items. Think, contemplate, research, reflect, refine, revise. Be careful, curious, vigilant, energetic. Verify your changes. Think aloud. Consult, research, reflect. Periodically remove completed items from `./WORK.md` and tick off completed items from `./TODO.md` and `./PLAN.md`. Update `./WORK.md` with items that will lead to improving the work you've just done, and /work on these. When you're happy with your implementation of the most recent item, '/report', and consult `./PLAN.md` and `./TODO.md`, and /work on implementing the next item, and so on and so on. Work tirelessly without informing me. Only let me know when you've completed the task of implementing all `./PLAN.md` and `./TODO.md` items. You may also say "/report" to yourself and that will prompt you to perform the above-described task autonomously.