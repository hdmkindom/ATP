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
  by_cases hx : x = 0
  · subst hx
    simpa using AddChar.sum_apply_eq_ite (α := Fin N) (a := (0 : Fin N))
  · have hsum : ∑ a : Fin N, data.ψ a x = 0 := by
      have hneq : (fun a : Fin N => data.ψ a x) ≠ 1 := by
        intro hfun
        have hzero : data.ψ 0 x = 1 := by simpa using congrArg (fun f : Fin N → ℂ => f 0) hfun
        rw [data.map_zero_eq_one'] at hzero
        exact hx hzero
      have hshift : ∀ b : Fin N, data.ψ b x * (∑ a : Fin N, data.ψ a x) = ∑ a : Fin N, data.ψ a x := by
        intro b
        calc
          data.ψ b x * (∑ a : Fin N, data.ψ a x)
              = ∑ a : Fin N, data.ψ b x * data.ψ a x := by
                  rw [Finset.mul_sum]
          _ = ∑ a : Fin N, data.ψ (b + a) x := by
                  refine Finset.sum_congr rfl ?_
                  intro a ha
                  rw [← data.map_add_eq_mul']
          _ = ∑ a : Fin N, data.ψ a x := by
                  exact Finset.sum_bijective (fun a : Fin N => b + a) (by intro a ha; simp)
      by_contra hne
      obtain ⟨b, hb⟩ : ∃ b : Fin N, data.ψ b x ≠ 1 := by
        by_contra h'
        apply hneq
        funext a
        exact not_exists.mp h' a
      have hbmul := hshift b
      rw [hbmul] at hbmul
      have hfactor : (data.ψ b x - 1) * (∑ a : Fin N, data.ψ a x) = 0 := by
        linarith
      have hunit : data.ψ b x - 1 ≠ 0 := sub_ne_zero.mpr hb
      exact hunit (by
        apply mul_eq_zero.mp hfactor |>.resolve_right hne)
    simp [hx, hsum]

end T4
end TemTH
