/-
`temTH` 模板：`T4` 路线 B。
-/
import CandidateTheorems.T4.RouteB
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T4

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeB
    (data : AdditiveOrthogonalityData (N := N)) (x : Fin N) :
    ∑ a : Fin N, data.ψ a x = if x = 0 then (N : ℂ) else 0 := by
  let ψx : AddChar (Fin N) ℂ :=
    { toFun := fun a => data.ψ a x
      map_zero' := by
        simpa using data.psi_zero_right x
      map_add' := by
        intro a b
        simpa using data.psi_add_left a b x }
  have hsum : ∑ a : Fin N, ψx a = if ψx = 0 then (Fintype.card (Fin N) : ℂ) else 0 :=
    AddChar.sum_eq_ite ψx
  have hcard : (Fintype.card (Fin N) : ℂ) = (N : ℂ) := by
    simp
  have hzero : ψx = 0 ↔ x = 0 := by
    constructor
    · intro hψ
      by_contra hx
      have hne : ψx ≠ 0 := by
        intro h0
        exact hx ((data.psi_eq_one_iff_right_zero.mp (h0 1)).symm)
      exact hne hψ
    · intro hx
      ext a
      subst hx
      simpa using data.psi_right_zero a
  rw [hsum, hcard]
  congr 1
  exact propext hzero

end T4
end TemTH
