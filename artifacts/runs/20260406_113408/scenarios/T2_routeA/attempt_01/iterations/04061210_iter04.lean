/-
`temTH` 模板：`T2` 路线 A。
-/
import CandidateTheorems.T2.Support

open scoped BigOperators

namespace TemTH
namespace T2

open CandidateTheorems.T2

variable {G Γ : Type*} [Fintype G] [Group G] [DecidableEq G] [Fintype Γ]

theorem candidate_T2_routeA
    (data : CharacterOrthogonalityData (G := G) (Γ := Γ)) (g : G) :
    ∑ χ : Γ, data.eval χ g = if g = 1 then (Fintype.card G : ℂ) else 0 := by
  simpa using data.sum_eq_if g

end T2
end TemTH
