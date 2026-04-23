# ATP Ax-Prover Doctor

- **started_at**: 2026-04-05T19:52:57.070635
- **finished_at**: 2026-04-05T19:53:03.945129

| Check | Status | Duration (s) | Message |
| --- | --- | --- | --- |
| ax_prover_import | ok | 0.00 | ax_prover import ok (/Users/hdm/ax-prover-env/lib/python3.11/site-packages/ax_prover/__init__.py) |
| llm_credentials | ok | 0.00 | OPENAI_API_KEY is set for provider openai. |
| llm_base_url | ok | 0.00 | base_url looks syntactically valid but has no explicit API path: https://api.whatai.cc. Many OpenAI-compatible relays expect a `/v1` suffix. |
| lean_repo_build | ok | 3.50 | Lean repository build succeeded. |
| template_smoke_file | ok | 0.54 | Lean can parse ATP/temTH/ testTH/test.lean. |
| llm_ping | error | 2.22 | RuntimeError: AttributeError: 'str' object has no attribute 'model_dump'. The configured OpenAI-compatible `base_url` appears to point at a website root instead of a chat-completions API endpoint: https://api.whatai.cc. If you are using a relay or proxy, configure the full API root such as `https://host/v1`; if you want the official provider endpoint, leave `base_url` empty or null in YAML. |
| smoke_proof | skipped | 0.00 | Skipped by CLI flag. |
