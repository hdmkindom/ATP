# ATP Ax-Prover Run Summary

- **repo_root**: /Users/hdm/math/elementary-number-theory
- **repeats**: 1
- **scenario_count**: 40
- **elapsed_seconds**: 2043.677
- **llm_request_count**: 389
- **llm_failed_request_count**: 0
- **llm_total_tokens**: 679111
- **estimated_total_seconds**: 3931.756
- **estimate_source**: 历史 EWMA

| Scenario | Success | Valid | Observed Route | Route Check | Iter | Time (s) | Requests | Tokens | Policy | Error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1.free | no | no | unknown | n/a | 5 | 71.95 | 11 | 21412 | OK |  |
| T1.disable | no | no | unknown | n/a | 5 | 61.25 | 11 | 17856 | OK |  |
| T1.routeA | no | no | unknown | n/a | 5 | 116.46 | 11 | 31840 | OK |  |
| T1.routeB | no | no | unknown | n/a | 5 | 54.54 | 11 | 18268 | OK |  |
| T2.free | no | no | routeA | n/a | 5 | 42.18 | 11 | 17929 | OK |  |
| T2.disable | no | no | routeA | no | 5 | 70.55 | 11 | 18504 | Matched forbidden pattern: \bCharacterOrthogonalityData\b |  |
| T2.routeA | no | no | routeA | yes | 5 | 44.36 | 11 | 17796 | OK |  |
| T2.routeB | no | no | routeB | yes | 5 | 56.98 | 11 | 18008 | OK |  |
| T3.free | no | no | routeA | n/a | 5 | 54.49 | 11 | 18701 | OK |  |
| T3.disable | no | no | routeA | no | 5 | 47.01 | 11 | 19520 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T3.routeA | no | no | routeA | yes | 5 | 54.92 | 11 | 18576 | OK |  |
| T3.routeB | no | no | routeB | yes | 5 | 53.24 | 11 | 19481 | Matched forbidden pattern: (?m)^\s*import\s+CandidateTheorems\.T\d+\.(RouteA|RouteB)\b |  |
| T4.free | no | no | routeA | n/a | 5 | 46.66 | 11 | 18813 | OK |  |
| T4.disable | no | no | routeA | no | 5 | 55.30 | 11 | 19351 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T4.routeA | no | no | routeA | yes | 5 | 50.07 | 11 | 19119 | OK |  |
| T4.routeB | no | no | routeB | yes | 5 | 57.75 | 11 | 19232 | Matched forbidden pattern: (?m)^\s*import\s+CandidateTheorems\.T\d+\.(RouteA|RouteB)\b |  |
| T5.free | no | no | routeA | n/a | 5 | 50.14 | 11 | 18886 | OK |  |
| T5.disable | no | no | routeA | no | 5 | 54.41 | 11 | 19381 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T5.routeA | no | no | routeA | yes | 5 | 48.13 | 11 | 18999 | OK |  |
| T5.routeB | no | no | routeB | yes | 5 | 53.96 | 11 | 18739 | OK |  |
| T6.free | no | no | routeA | n/a | 5 | 47.43 | 11 | 17855 | OK |  |
| T6.disable | no | no | routeA | no | 5 | 46.67 | 11 | 17805 | Matched forbidden pattern: \bChangeOfVariablesData\b |  |
| T6.routeA | no | no | routeA | yes | 5 | 48.13 | 11 | 18156 | OK |  |
| T6.routeB | no | no | routeB | yes | 5 | 49.57 | 11 | 17838 | OK |  |
| T7.free | no | no | routeA | n/a | 5 | 55.90 | 11 | 20020 | OK |  |
| T7.disable | no | no | routeA | no | 5 | 61.69 | 11 | 19912 | OK |  |
| T7.routeA | no | no | routeA | yes | 5 | 51.25 | 11 | 19924 | OK |  |
| T7.routeB | no | no | mixed | n/a | 5 | 63.28 | 11 | 20487 | OK |  |
| T8.free | no | no | routeA | n/a | 5 | 84.14 | 11 | 19158 | OK |  |
| T8.disable | no | no | routeA | no | 5 | 60.27 | 11 | 20054 | Matched forbidden pattern: \bFourierTranslationData\b |  |
| T8.routeA | no | no | routeA | yes | 5 | 82.58 | 11 | 19636 | OK |  |
| T8.routeB | no | no | routeB | yes | 5 | 62.42 | 11 | 20051 | OK |  |
| T9.free | yes | yes | unknown | n/a | 1 | 13.61 | 3 | 3857 | OK |  |
| T9.disable | yes | yes | unknown | n/a | 1 | 10.79 | 3 | 3962 | OK |  |
| T9.routeA | yes | yes | unknown | n/a | 3 | 38.20 | 7 | 12552 | OK |  |
| T9.routeB | yes | yes | unknown | n/a | 1 | 11.05 | 3 | 3876 | OK |  |
| T10.free | yes | yes | unknown | n/a | 1 | 13.52 | 3 | 3981 | OK |  |
| T10.disable | yes | yes | unknown | n/a | 1 | 12.25 | 3 | 4112 | OK |  |
| T10.routeA | yes | yes | unknown | n/a | 5 | 68.57 | 12 | 21511 | OK |  |
| T10.routeB | yes | yes | unknown | n/a | 1 | 11.93 | 3 | 3953 | OK |  |
