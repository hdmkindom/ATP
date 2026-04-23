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
    by_contra hno
    apply hχ
    ext g
    by_contra hg
    exact hno ⟨g, hg⟩
  rcases hexists with ⟨h, hh_ne_one⟩
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    dsimp [S]
    simpa using Function.Bijective.sum_comp (e := fun g : G => h * g) (Group.mulLeft_bijective h)
      (fun g : G => (χ g : ℂ))
  have h_mul_left : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    calc
      ∑ g : G, (χ (h * g) : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g _
              simp
      _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
            rw [mul_sum]
      _ = (χ h : ℂ) * S := by
            simp [S]
  have h_eq : S = (χ h : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := h_reindex.symm
      _ = (χ h : ℂ) * S := h_mul_left
  have hχh_coe_ne_one : (χ h : ℂ) ≠ 1 := by
    intro hcoh
    apply hh_ne_one
    exact_mod_cast hcoh
  have h_one_sub_ne_zero : 1 - (χ h : ℂ) ≠ 0 := by
    intro hz
    apply hχh_coe_ne_one
    have htmp : (χ h : ℂ) = 1 - 0 := by
      rw [← hz]
      ring
    simpa using htmp
  have h_factor : (1 - (χ h : ℂ)) * S = 0 := by
    calc
      (1 - (χ h : ℂ)) * S = S - (χ h : ℂ) * S := by ring
      _ = 0 := by rw [h_eq, sub_self]
  have hS : S = 0 := by
    by_contra hS_ne
    have : 1 - (χ h : ℂ) = 0 := by
      apply mul_eq_zero.mp h_factor |> Or.resolve_right hS_ne
    exact h_one_sub_ne_zero this
  simpa [S] using hS

end T1
end TemTH
