/-
`temTH` 模板：`T2` 自由模式。
-/
import CandidateTheorems.T2.Support

open scoped BigOperators

namespace TemTH
namespace T2

open CandidateTheorems.T2

variable {G Γ : Type*} [Fintype G] [Group G] [DecidableEq G] [Fintype Γ]

theorem candidate_T2_free
    (data : CharacterOrthogonalityData (G := G) (Γ := Γ)) (g : G) :
    ∑ χ : Γ, data.eval χ g = if g = 1 then (Fintype.card G : ℂ) else 0 := by
  classical
  by_cases hg : g = 1
  · simp [hg, data.sum_eval_one]
  · simp [hg, data.sum_eval_zero_of_ne_one hg]

end T2
end TemTH
