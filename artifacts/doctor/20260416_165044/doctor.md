# ATP Ax-Prover Doctor

- **started_at**: 2026-04-16T16:50:44.270592
- **finished_at**: 2026-04-16T16:50:59.213423

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | ANTHROPIC_API_KEY is set for provider anthropic. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 8.86 | Lean repository build succeeded. |
| template_smoke_file | ok | 1.59 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 0.66 | RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/v1/messages)', 'type': 'invalid_request_error', 'param': '', 'code': ''}} |
| smoke_proof | error | 0.83 | RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/v1/messages)', 'type': 'invalid_request_error', 'param': '', 'code': ''}} |
