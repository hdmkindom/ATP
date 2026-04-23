# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:09:41.410785
- **finished_at**: 2026-04-05T20:09:50.992306

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 3.75 | Lean repository build succeeded. |
| template_smoke_file | error | 0.00 | RuntimeError: File not found: ATP/temTH/ testTH/test.lean |
| llm_ping | error | 5.50 | RuntimeError: AuthenticationError: Error code: 401 - {'error': {'code': '', 'message': '无效的令牌 (request id: 202604051209508960690358268d9d6emO6hqoA)', 'type': 'new_api_error'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
