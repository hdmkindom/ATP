/-
`temTH` 模板：`T1` 路线 B。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeB (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  simpa using (MulChar.sum_eq_zero_of_ne_one (R := G) (R' := ℂ) hχ)

end T1
end TemTH
