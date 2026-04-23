# ATP Ax-Prover Run Summary

- **repo_root**: /home/hdm/math/elementary-number-theory
- **repeats**: 1
- **scenario_count**: 40
- **elapsed_seconds**: 13532.154
- **llm_request_count**: 2350
- **llm_failed_request_count**: 0
- **llm_total_tokens**: 13270663
- **estimated_total_seconds**: 3268.803
- **estimate_source**: 历史 EWMA

| Scenario | Success | Valid | Observed Route | Route Check | Iter | Time (s) | Requests | Tokens | Policy | Error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1.free | no | no | unknown | n/a | 20 | 490.59 | 65 | 369113 | OK |  |
| T1.disable | no | no | unknown | n/a | 20 | 331.99 | 66 | 262281 | OK |  |
| T1.routeA | no | no | unknown | n/a | 20 | 609.75 | 68 | 455433 | OK |  |
| T1.routeB | no | no | unknown | n/a | 20 | 346.87 | 59 | 283482 | OK |  |
| T2.free | no | no | routeA | n/a | 20 | 360.44 | 80 | 393793 | OK |  |
| T2.disable | yes | no | routeA | no | 1 | 18.02 | 5 | 18977 | Matched forbidden pattern: \bsum_eval\b<br>Matched forbidden pattern: \bCharacterOrthogonalityData\b |  |
| T2.routeA | no | no | routeA | yes | 20 | 339.46 | 80 | 375581 | OK |  |
| T2.routeB | no | no | routeB | yes | 20 | 353.30 | 79 | 419375 | OK |  |
| T3.free | no | no | routeA | n/a | 20 | 484.52 | 76 | 425833 | OK |  |
| T3.disable | no | no | routeA | no | 20 | 501.75 | 78 | 521508 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T3.routeA | yes | yes | routeA | yes | 13 | 324.71 | 47 | 266154 | OK |  |
| T3.routeB | no | no | routeB | yes | 20 | 353.08 | 65 | 311459 | Matched forbidden pattern: (?m)^\s*import\s+CandidateTheorems\.T\d+\.(RouteA|RouteB)\b |  |
| T4.free | no | no | routeA | n/a | 20 | 522.85 | 79 | 413017 | OK |  |
| T4.disable | no | no | routeA | no | 20 | 406.22 | 74 | 403984 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T4.routeA | no | no | routeA | yes | 20 | 514.66 | 77 | 476608 | OK |  |
| T4.routeB | no | no | routeB | yes | 20 | 484.29 | 80 | 484709 | Matched forbidden pattern: (?m)^\s*import\s+CandidateTheorems\.T\d+\.(RouteA|RouteB)\b |  |
| T5.free | no | no | routeA | n/a | 20 | 520.53 | 77 | 511142 | OK |  |
| T5.disable | no | no | routeA | no | 20 | 502.59 | 76 | 477914 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T5.routeA | no | no | routeA | yes | 20 | 518.78 | 74 | 546709 | OK |  |
| T5.routeB | no | no | routeB | yes | 20 | 440.23 | 79 | 421049 | OK |  |
| T6.free | no | no | routeA | n/a | 20 | 343.05 | 80 | 410554 | OK |  |
| T6.disable | no | no | routeA | no | 20 | 339.05 | 76 | 351862 | Matched forbidden pattern: \bChangeOfVariablesData\b |  |
| T6.routeA | no | no | routeA | yes | 20 | 355.42 | 78 | 390016 | OK |  |
| T6.routeB | no | no | routeB | yes | 20 | 407.37 | 78 | 394943 | OK |  |
| T7.free | no | no | routeA | n/a | 20 | 564.95 | 81 | 665925 | OK |  |
| T7.disable | no | no | routeA | no | 20 | 501.46 | 80 | 526515 | OK |  |
| T7.routeA | no | no | routeA | yes | 20 | 421.28 | 78 | 391512 | OK |  |
| T7.routeB | no | no | mixed | n/a | 20 | 431.53 | 69 | 481866 | OK |  |
| T8.free | no | no | routeA | n/a | 20 | 415.85 | 78 | 457891 | OK |  |
| T8.disable | no | no | routeA | no | 20 | 335.49 | 79 | 419673 | Matched forbidden pattern: \bFourierTranslationData\b |  |
| T8.routeA | no | no | routeA | yes | 20 | 427.49 | 81 | 455550 | OK |  |
| T8.routeB | no | no | routeB | yes | 20 | 416.84 | 76 | 437479 | OK |  |
| T9.free | yes | yes | unknown | n/a | 1 | 9.15 | 3 | 3844 | OK |  |
| T9.disable | yes | yes | unknown | n/a | 1 | 10.14 | 3 | 3926 | OK |  |
| T9.routeA | yes | yes | unknown | n/a | 2 | 28.47 | 5 | 8813 | OK |  |
| T9.routeB | yes | yes | unknown | n/a | 1 | 10.03 | 3 | 3863 | OK |  |
| T10.free | yes | yes | unknown | n/a | 1 | 9.42 | 3 | 3922 | OK |  |
| T10.disable | yes | yes | unknown | n/a | 1 | 11.06 | 3 | 4014 | OK |  |
| T10.routeA | yes | yes | unknown | n/a | 4 | 49.26 | 9 | 16441 | OK |  |
| T10.routeB | yes | yes | unknown | n/a | 1 | 12.59 | 3 | 3933 | OK |  |
