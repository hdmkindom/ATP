# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:06:35.688709
- **finished_at**: 2026-04-05T20:06:42.443084

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks syntactically valid but has no explicit API path: https://codeflow.asia. Many OpenAI-compatible relays expect a `/v1` suffix. |
| lean_repo_build | ok | 3.81 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.66 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 1.94 | RuntimeError: AttributeError: 'str' object has no attribute 'error' |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
