/-
`temTH` 模板：`T1` 路线 A。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeA (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hexists : ∃ h : G, χ h ≠ 1 := by
    rcases (MulChar.ne_one_iff.mp hχ) with ⟨u, hu⟩
    exact ⟨u, hu⟩
  rcases hexists with ⟨h, hh_ne_one⟩
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    dsimp [S]
    simpa using
      Function.Bijective.sum_comp (e := fun g : G => h * g) (Group.mulLeft_bijective h)
        (fun g : G => (χ g : ℂ))
  have h_mul_left : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    calc
      ∑ g : G, (χ (h * g) : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g _
              simp
      _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simp [Finset.mul_sum]
      _ = (χ h : ℂ) * S := by
            rfl
  have h_eq : S = (χ h : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := h_reindex.symm
      _ = (χ h : ℂ) * S := h_mul_left
  have hχh_coe_ne_one : (χ h : ℂ) ≠ 1 := by
    intro hcoh
    apply hh_ne_one
    exact Circle.coe_injective hcoh
  have h_factor : (1 - (χ h : ℂ)) * S = 0 := by
    rw [h_eq]
    ring
  have h_one_sub_ne_zero : 1 - (χ h : ℂ) ≠ 0 := by
    intro hz
    apply hχh_coe_ne_one
    have : (χ h : ℂ) = 1 := by linarith
    exact this
  have hS : S = 0 := by
    apply Or.resolve_left (mul_eq_zero.mp h_factor) h_one_sub_ne_zero
  exact hS

end T1
end TemTH
