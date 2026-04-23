/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators
import Mathlib/NumberTheory/LegendreSymbol/GaussSum

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  simpa only [Character] using
    (MulChar.sum_eq_zero_of_ne_one (R := G) (R' := ℂ) (χ := χ) hχ)

end T1
end TemTH
