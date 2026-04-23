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
  classical
  let e : Γ ≃ AddChar G ℂ := data.equiv
  have hsum := AddChar.sum_apply_eq_ite (α := G) (a := g)
  simpa [CharacterOrthogonalityData.eval, e] using
    (Fintype.sum_equiv e fun ψ => ψ g).symm.trans hsum

end T2
end TemTH
