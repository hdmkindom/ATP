# ATP Ax-Prover Run Summary

- **repo_root**: /Users/hdm/math/elementary-number-theory
- **repeats**: 1
- **scenario_count**: 41

| Scenario | Success | Valid | Observed Route | Route Check | Iter | Policy | Error |
| --- | --- | --- | --- | --- | --- | --- | --- |
| test.smoke | yes | yes | unknown | n/a | 1 | OK |  |
| T1.free | no | no | unknown | n/a | 6 | OK |  |
| T1.disable | no | no | unknown | n/a | 6 | OK |  |
| T1.routeA | no | no | unknown | n/a | 6 | OK |  |
| T1.routeB | no | no | unknown | n/a | 6 | OK |  |
| T2.free | no | no | routeA | n/a | 6 | OK |  |
| T2.disable | no | no | routeA | no | 6 | Matched forbidden pattern: \bCharacterOrthogonalityData\b |  |
| T2.routeA | no | no | routeA | yes | 6 | OK |  |
| T2.routeB | no | no | routeB | yes | 6 | OK |  |
| T3.free | no | no | routeA | n/a | 6 | OK |  |
| T3.disable | no | no | routeA | no | 6 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T3.routeA | no | no | routeA | yes | 6 | OK |  |
| T3.routeB | no | no | routeB | yes | 6 | Matched forbidden pattern: (?m)^\s*import\s+CandidateTheorems\.T\d+\.(RouteA|RouteB)\b |  |
| T4.free | no | no | routeA | n/a | 6 | OK |  |
| T4.disable | no | no | routeA | no | 6 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T4.routeA | no | no | routeA | yes | 6 | OK |  |
| T4.routeB | no | no | routeB | yes | 6 | Matched forbidden pattern: (?m)^\s*import\s+CandidateTheorems\.T\d+\.(RouteA|RouteB)\b |  |
| T5.free | no | no | routeA | n/a | 6 | OK |  |
| T5.disable | no | no | routeA | no | 6 | Matched forbidden pattern: \bPrimitiveNthRoot\b |  |
| T5.routeA | no | no | routeA | yes | 6 | OK |  |
| T5.routeB | no | no | routeB | yes | 6 | OK |  |
| T6.free | no | no | routeA | n/a | 6 | OK |  |
| T6.disable | no | no | routeA | no | 6 | Matched forbidden pattern: \bChangeOfVariablesData\b |  |
| T6.routeA | no | no | routeA | yes | 6 | OK |  |
| T6.routeB | no | no | routeB | yes | 6 | OK |  |
| T7.free | no | no | routeA | n/a | 6 | OK |  |
| T7.disable | no | no | routeA | no | 6 | OK |  |
| T7.routeA | no | no | routeA | yes | 6 | OK |  |
| T7.routeB | no | no | mixed | n/a | 6 | OK |  |
| T8.free | no | no | routeA | n/a | 6 | OK |  |
| T8.disable | no | no | routeA | no | 6 | Matched forbidden pattern: \bFourierTranslationData\b |  |
| T8.routeA | no | no | routeA | yes | 6 | OK |  |
| T8.routeB | no | no | routeB | yes | 6 | OK |  |
| T9.free | yes | yes | unknown | n/a | 1 | OK |  |
| T9.disable | yes | yes | unknown | n/a | 1 | OK |  |
| T9.routeA | yes | yes | routeA | yes | 3 | OK |  |
| T9.routeB | yes | yes | unknown | n/a | 1 | OK |  |
| T10.free | yes | yes | unknown | n/a | 1 | OK |  |
| T10.disable | yes | yes | unknown | n/a | 1 | OK |  |
| T10.routeA | yes | yes | unknown | n/a | 5 | OK |  |
| T10.routeB | yes | yes | unknown | n/a | 1 | OK |  |
