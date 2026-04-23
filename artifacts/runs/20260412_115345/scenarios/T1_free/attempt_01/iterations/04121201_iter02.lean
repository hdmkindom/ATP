/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  let χℂ : G →* ℂ := (Units.coeHom ℂ).comp χ
  have hχℂ_ne_one : χℂ ≠ 1 := by
    intro hχℂ
    apply hχ
    ext g
    have hEval : χℂ g = (1 : G →* ℂ) g := by
      exact congrArg (fun f : G →* ℂ => f g) hχℂ
    simpa [χℂ] using hEval
  have hsum : ∑ g : G, χℂ g = 0 := by
    exact sum_hom_units_eq_zero χℂ hχℂ_ne_one
  simpa [χℂ] using hsum

end T1
end TemTH
