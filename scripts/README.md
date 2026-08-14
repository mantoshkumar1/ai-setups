# Script notes

## Test setup changes safely

Before changing `setup.sh` or `validate.sh`, run:

```sh
bash scripts/test-setup.sh
```

The test creates a temporary Git repository, a fake PAT, and a temporary home folder. It runs the real setup script there, checks that the fake token was not printed, then deletes the temporary files.

It does not touch `config/.github-pat`, `~/.codex`, or the current checkout. Do not use a real token in this test.

This test currently covers macOS/Linux only. There is no Windows equivalent yet.
