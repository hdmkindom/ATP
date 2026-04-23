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
  have h_exists : ∃ h : G, χ h ≠ 1 := by
    by_contra h_no
    apply hχ
    ext g
    by_contra hg
    exact h_no ⟨g, hg⟩
  rcases h_exists with ⟨h, hh_ne_one⟩
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    dsimp [S]
    simpa using
      Function.Bijective.sum_comp (f := fun g : G => (χ g : ℂ)) (e := fun g : G => h * g)
        (Group.mulLeft_bijective h)
  have h_mul_left : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    calc
      ∑ g : G, (χ (h * g) : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g _
              simp
      _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
            symm
            simpa [S] using (Finset.mul_sum Finset.univ (fun g : G => (χ g : ℂ)) (χ h : ℂ))
      _ = (χ h : ℂ) * S := by rfl
  have h_eq : S = (χ h : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := h_reindex.symm
      _ = (χ h : ℂ) * S := h_mul_left
  have hchi_h_ne_one_complex : (χ h : ℂ) ≠ 1 := by
    intro hcoeq
    apply hh_ne_one
    ext
    exact hcoeq
  have h_one_sub_ne_zero : 1 - (χ h : ℂ) ≠ 0 := by
    intro hz
    apply hchi_h_ne_one_complex
    linarith
  have h_factor : (1 - (χ h : ℂ)) * S = 0 := by
    have hs' : S - (χ h : ℂ) * S = 0 := by rw [h_eq]
    calc
      (1 - (χ h : ℂ)) * S = S - (χ h : ℂ) * S := by ring
      _ = 0 := hs'
  have hS : S = 0 := by
    by_cases hzero : S = 0
    · exact hzero
    · exfalso
      apply h_one_sub_ne_zero
      exact (mul_eq_zero.mp h_factor).resolve_right hzero
  simpa [S] using hS

end T1
end TemTH
