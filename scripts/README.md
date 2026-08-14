# Script notes

## Test setup changes safely

Before changing `setup.sh` or `validate.sh`, run:

```sh
bash scripts/test-setup.sh
```

The test creates a temporary Git repository, a fake PAT, and a temporary home folder. It reports each check: setup/validation completion, PAT permissions, Git ignore status, Codex context setup, and no token output. It then deletes the temporary files.

It does not touch `config/.github-pat`, `~/.codex`, or the current checkout. Do not use a real token in this test.

This test currently covers macOS/Linux only. There is no Windows equivalent yet.
