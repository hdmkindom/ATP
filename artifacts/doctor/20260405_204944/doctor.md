# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:49:44.502256
- **finished_at**: 2026-04-05T20:49:54.501348

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks syntactically valid but has no explicit API path: https://codeflow.asia. Many OpenAI-compatible relays expect a `/v1` suffix. |
| lean_repo_build | ok | 4.10 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.73 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 4.80 | RuntimeError: AttributeError: 'str' object has no attribute 'error' |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
