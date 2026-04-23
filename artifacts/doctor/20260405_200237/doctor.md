# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:02:37.372778
- **finished_at**: 2026-04-05T20:02:44.290764

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://api.whatai.cc/v1/chat |
| lean_repo_build | ok | 3.80 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.68 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 2.15 | RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/chat/responses), you may need [POST /v1/responses]', 'type': 'invalid_request_error', 'param': '', 'code': ''}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
