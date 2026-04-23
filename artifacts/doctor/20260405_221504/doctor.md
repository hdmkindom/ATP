# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T22:15:04.768833
- **finished_at**: 2026-04-05T22:15:11.058823

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1/chat |
| lean_repo_build | ok | 3.51 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.68 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 1.76 | RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/chat/chat/completions)', 'type': 'invalid_request_error', 'param': '', 'code': ''}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
