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
  -- Use the standard orthogonality statement for nontrivial group homomorphisms.
  -- (`Character G` is a multiplicative character into `ℂˣ`/`ℂ`-valued in this setup.)
  simpa using sum_hom_units_eq_zero χ hχ

end T1
end TemTH
