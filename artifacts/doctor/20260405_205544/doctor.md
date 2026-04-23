# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:55:44.477538
- **finished_at**: 2026-04-05T20:55:51.185080

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | error | 0.00 | RuntimeError: For OpenAI-compatible providers, `base_url` must be the API root rather than the final `/chat/completions` endpoint. Use something like `https://codeflow.asia/v1` instead of `https://codeflow.asia/v1/chat/completions`. |
| lean_repo_build | ok | 3.97 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.64 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 1.76 | RuntimeError: NotFoundError: Error code: 404 - {'error': {'message': 'Invalid URL (POST /v1/chat/completions/responses)', 'type': 'invalid_request_error', 'param': '', 'code': ''}}. The configured OpenAI-compatible `base_url` points to the final `/chat/completions` endpoint instead of the API root: https://codeflow.asia/v1/chat/completions. The SDK appends resource paths itself, so you should configure the API root such as `https://host/v1`, not `https://host/v1/chat/completions`. |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
