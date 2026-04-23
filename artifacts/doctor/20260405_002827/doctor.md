# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T00:28:27.262813
- **finished_at**: 2026-04-05T00:28:34.897841

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | No base_url configured; provider default endpoint will be used. |
| lean_repo_build | ok | 3.38 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.59 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 3.44 | RateLimitError: Error code: 429 - {'error': {'message': 'You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.', 'type': 'insufficient_quota', 'param': None, 'code': 'insufficient_quota'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
