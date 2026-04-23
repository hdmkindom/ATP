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
  let χC : G →* ℂ := (Units.coeHom ℂ).comp χ
  have hχC_ne_one : χC ≠ 1 := by
    intro hχC
    apply hχ
    ext g
    apply Units.ext
    have hval : χC g = (1 : G →* ℂ) g := by
      exact congrArg (fun f : G →* ℂ => f g) hχC
    simpa [χC] using hval
  have hsum : ∑ g : G, χC g = (0 : ℂ) := by
    exact sum_hom_units_eq_zero (f := χC) hχC_ne_one
  simpa [χC] using hsum

end T1
end TemTH
