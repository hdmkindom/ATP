/-
`temTH` 模板：`T2` 路线 B。
-/
import CandidateTheorems.T2.Support

open scoped BigOperators

namespace TemTH
namespace T2

open CandidateTheorems.T2

variable {G Γ : Type*} [Fintype G] [Group G] [DecidableEq G] [Fintype Γ]

theorem candidate_T2_routeB
    (data : FourierInversionData (G := G) (Γ := Γ)) (g : G) :
    ∑ χ : Γ, data.eval χ g = if g = 1 then (Fintype.card G : ℂ) else 0 := by
  simpa using fourierInversion_sum_eval (data := data) (g := g)

end T2
end TemTH
