/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  -- First use the standard vanishing result in the codomain of `Character`.
  have hsum_units : (∑ g : G, χ g) = 0 := by
    exact MulChar.sum_eq_zero_of_ne_one (χ := χ) hχ
  -- Then coerce the equality to `ℂ`, matching the goal's summand type.
  exact_mod_cast hsum_units

end T1
end TemTH
