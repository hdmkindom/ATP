# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:02:57.578021
- **finished_at**: 2026-04-05T20:03:03.987093

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://api.whatai.cc/v1 |
| lean_repo_build | ok | 3.31 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.68 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 2.11 | RuntimeError: AuthenticationError: Error code: 401 - {'error': {'code': 'invalid_request', 'message': '令牌不合法 (request id: B20260405120303949344867XGXawFZQ)', 'type': 'new_api_error'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
