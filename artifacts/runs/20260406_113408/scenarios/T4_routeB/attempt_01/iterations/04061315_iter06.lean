/-
`temTH` 模板：`T4` 路线 B。
-/
import CandidateTheorems.T4.RouteB

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
  have hχ_zero_iff : χ = 0 ↔ x = 0 := by
    constructor
    · intro hχ
      by_contra hx
      have hx' : x ≠ 0 := hx
      have hsumχ : ∑ a : Fin N, χ a = 0 := by
        exact AddChar.sum_eq_zero_iff_ne_zero.mpr hχ
      have hsumψ : ∑ a : Fin N, data.ψ a x = 0 := by
        simpa [χ] using hsumχ
      have := data.orthogonality (x := x)
      simp [hx', hsumψ] at this
    · intro hx
      ext a
      subst hx
      simpa using data.map_zero_eq_one' a
  have hsumχ : ∑ a : Fin N, χ a = if χ = 0 then (N : ℂ) else 0 := by
    simpa using AddChar.sum_eq_ite (ψ := χ)
  calc
    ∑ a : Fin N, data.ψ a x
        = ∑ a : Fin N, χ a := by rfl
    _ = if χ = 0 then (N : ℂ) else 0 := hsumχ
    _ = if x = 0 then (N : ℂ) else 0 := by simp [hχ_zero_iff]

end T4
end TemTH
