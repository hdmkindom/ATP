# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:52:09.347544
- **finished_at**: 2026-04-05T20:52:17.170350

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | error | 0.00 | RuntimeError: For OpenAI-compatible providers, `base_url` must be the API root rather than the final `/responses` endpoint. Use something like `https://codeflow.asia/v1` instead of `https://codeflow.asia/v1/responses`. |
| lean_repo_build | ok | 4.07 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.77 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 2.62 | RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/responses/responses)', 'type': 'invalid_request_error', 'param': '', 'code': ''}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
