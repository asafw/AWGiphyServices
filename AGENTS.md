# AWGiphyServices — AI Agent Instructions

## Context file
`.github/CONTEXT.md` is the authoritative project-state document for
AI-assisted development. **Always read it before making any changes.**

## After every session that makes code changes

Before ending the conversation, the AI must:

1. Update `.github/CONTEXT.md`:
   - Latest commit hash + message
   - Updated test counts
   - Any new/changed types, APIs, or invariants
   - Updated commit history block

2. Update `.github/instructions/awgiphyservices.instructions.md` if
   architecture, conventions, or public API descriptions changed.

3. Commit both files together — never separately:
   ```bash
   git add .github/CONTEXT.md .github/instructions/awgiphyservices.instructions.md
   git commit -m "docs(context): update session state"
   git push origin main
   ```

## Build / test quick reference

```bash
cd ~/Desktop/asafw/AWGiphyServices

# Build
swift build

# Unit tests (no network, macOS)
xcodebuild -scheme AWGiphyServices-Package -destination "platform=macOS" \
    -only-testing:AWGiphyServicesTests test

# All tests (integration tests require GIPHY_API_KEY or /tmp/GIPHY_API_KEY)
xcodebuild -scheme AWGiphyServices-Package -destination "platform=macOS" test
```

All unit tests must pass after any change. Integration tests skip automatically
when no API key is available.
