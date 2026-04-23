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
  -- Use the standard orthogonality formula for nontrivial group homomorphisms
  -- into an integral domain.
  have hsum : ∑ g : G, (χ g : ℂ) = if (χ : G →* ℂ) = 1 then Fintype.card G else 0 := by
    simpa using (sum_hom_units (f := (χ : G →* ℂ)))
  have hne : ((χ : G →* ℂ) ≠ 1) := by
    exact hχ
  rw [hsum]
  simp [hne]

end T1
end TemTH
