# ATP Ax-Prover Doctor

- **started_at**: 2026-04-16T18:36:26.282695
- **finished_at**: 2026-04-16T18:36:39.855172

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks valid: https://api.tokenfactory.nebius.com/v1 |
| lean_repo_build | ok | 7.73 | Lean repository build succeeded. |
| template_smoke_file | ok | 1.44 | Lean can parse ATP/temTH/testTH/test.lean. |
| llm_ping | error | 2.04 | RuntimeError: AuthenticationError: Error code: 401 - {'detail': "Couldn't authenticate. Reason: Unable authenticate"} |
| smoke_proof | error | 0.03 | RuntimeError: AttributeError: 'NoneType' object has no attribute 'get' |
