# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:11:25.348870
- **finished_at**: 2026-04-05T20:11:32.004706

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 3.89 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.68 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 1.72 | RuntimeError: AuthenticationError: Error code: 401 - {'error': {'code': '', 'message': '无效的令牌 (request id: 202604051211319586424658268d9d6u438jX7k)', 'type': 'new_api_error'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
