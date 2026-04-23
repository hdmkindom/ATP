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
  let χ : AddChar (Fin N) ℂ :=
    { toFun := fun a => data.ψ a x
      map_zero_eq_one' := by
        simpa using data.map_zero_eq_one' x
      map_add_eq_mul' := by
        intro a b
        simpa using data.map_add_eq_mul' a b x }
  have hsum : ∑ a : Fin N, χ a = if χ = 0 then (N : ℂ) else 0 := by
    simpa using AddChar.sum_eq_ite (ψ := χ)
  have hx : (χ = 0) ↔ (x = 0) := by
    constructor
    · intro hχ
      by_contra hx0
      have hforall : ∀ ψ : AddChar (Fin N) ℂ, ψ x = 1 := by
        intro ψ
        have hsumApply := AddChar.sum_apply_eq_ite (α := Fin N) (a := x)
        have hzero : ∑ ψ : AddChar (Fin N) ℂ, ψ x = 0 := by
          simp [hx0] at hsumApply
          exact hsumApply
        have hone : χ x = 1 := by
          simp [χ, AddChar.map_zero_eq_one]
        have : False := by
          rw [hχ] at hone
          simpa using hone
        exact False.elim this
      exact (AddChar.forall_apply_eq_zero (α := Fin N) (a := x)).mp hforall |> hx0
    · intro hx0
      ext a
      have h1 : χ x = 1 := by
        simp [χ, hx0, AddChar.map_zero_eq_one]
      have hmul := χ.map_add_eq_mul a x
      rw [hx0, add_zero] at hmul
      rw [h1, mul_one] at hmul
      exact hmul
  rw [hsum, if_congr hx (by intro _; rfl)]

end T4
end TemTH
