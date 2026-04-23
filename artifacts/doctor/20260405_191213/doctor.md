# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T19:12:13.578039
- **finished_at**: 2026-04-05T19:12:19.946512

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://api.whatai.cc |
| lean_repo_build | ok | 3.30 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.51 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 2.26 | AttributeError: 'str' object has no attribute 'model_dump' |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
