# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:07:00.282715
- **finished_at**: 2026-04-05T20:07:08.406252

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 3.80 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.66 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 3.36 | RuntimeError: AuthenticationError: Error code: 401 - {'error': {'code': '', 'message': '无效的令牌 (request id: 202604051207082481470338268d9d6qxoxLQ9d)', 'type': 'new_api_error'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
