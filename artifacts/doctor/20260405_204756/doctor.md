# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T20:47:56.661606
- **finished_at**: 2026-04-05T20:48:04.645973

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://codeflow.asia/v1 |
| lean_repo_build | ok | 3.33 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.64 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 3.77 | RuntimeError: InternalServerError: Error code: 503 - {'error': {'code': 'model_not_found', 'message': 'No available channel for model gpt-5.2-codex under group default (distributor) (request id: 202604051248045912188748268d9d6xiYbVTp0)', 'type': 'new_api_error'}} |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
