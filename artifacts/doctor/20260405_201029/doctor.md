# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:10:29.292508
- **finished_at**: 2026-04-05T20:10:35.087607

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 3.75 | Lean repository build succeeded. |
| template_smoke_file | error | 0.00 | RuntimeError: File not found: ATP/temTH/ testTH/test.lean |
| llm_ping | error | 1.76 | RuntimeError: AuthenticationError: Error code: 401 - {'error': {'code': '', 'message': '无效的令牌 (request id: 20260405121035474205508268d9d6lKAxJKjQ)', 'type': 'new_api_error'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
