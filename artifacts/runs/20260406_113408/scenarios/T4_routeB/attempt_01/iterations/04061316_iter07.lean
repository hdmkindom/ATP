/-
`temTH` 模板：`T4` 路线 B。
-/
import CandidateTheorems.T4.RouteB
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T4

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeB
    (data : AdditiveOrthogonalityData (N := N)) (x : Fin N) :
    ∑ a : Fin N, data.ψ a x = if x = 0 then (N : ℂ) else 0 := by
  classical
  let χ : AddChar (Fin N) ℂ :=
    { toFun := fun a => data.ψ a x
      map_zero_eq_one' := by
        simpa using data.map_zero_eq_one' x
      map_add_eq_mul' := by
        intro a b
        simpa using data.map_add_eq_mul' a b x }
  have hχ_zero : χ = 0 ↔ x = 0 := by
    constructor
    · intro h
      by_contra hx
      have hsum0 : (∑ a : Fin N, χ a) = 0 := by
        exact (AddChar.sum_eq_zero_iff_ne_zero (ψ := χ)).2 h
      have hone : χ 0 = 1 := by simpa using χ.map_zero_eq_one'
      have hconst : ∀ a : Fin N, χ a = 1 := by
        intro a
        simpa [h] using (AddChar.zero_apply (A := Fin N) (M := ℂ) a)
      have hsum1 : (∑ a : Fin N, χ a) = (N : ℂ) := by
        simp [hconst]
      exact by simpa [hsum1] using hsum0
    · intro hx
      ext a
      subst hx
      simpa using data.map_zero_eq_one' a
  calc
    ∑ a : Fin N, data.ψ a x = ∑ a : Fin N, χ a := by rfl
    _ = if χ = 0 then (N : ℂ) else 0 := by
      simpa using AddChar.sum_eq_ite (ψ := χ)
    _ = if x = 0 then (N : ℂ) else 0 := by
      simp [hχ_zero]

end T4
end TemTH
