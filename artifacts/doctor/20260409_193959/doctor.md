# ATP Ax-Prover Doctor

- **started_at**: 2026-04-09T19:39:59.545667
- **finished_at**: 2026-04-09T19:40:20.718292

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 3.43 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.58 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 17.08 | RuntimeError: APIConnectionError: Connection error. |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
