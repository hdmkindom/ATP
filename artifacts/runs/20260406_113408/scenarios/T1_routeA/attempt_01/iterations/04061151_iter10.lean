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
    by_contra hno
    apply hχ
    ext g
    by_contra hg
    exact hno ⟨g, hg⟩
  rcases h_exists with ⟨h, hh_ne⟩
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    dsimp [S]
    simpa using
      (Function.Bijective.sum_comp
        (fun g : G => h * g)
        (by
          refine ⟨?_, ?_⟩
          · intro a b hab
            exact mul_left_cancel hab
          · intro g
            refine ⟨h⁻¹ * g, ?_⟩
            simp [mul_assoc] )
        (fun g : G => (χ g : ℂ)))
  have h_mul : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    calc
      ∑ g : G, (χ (h * g) : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              apply congrArg
              ext g
              simp
      _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simp [mul_sum]
      _ = (χ h : ℂ) * S := by rfl
  have h_eq : S = (χ h : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := by simpa [h_reindex]
      _ = (χ h : ℂ) * S := h_mul
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    intro h1
    apply hh_ne
    exact_mod_cast h1
  have h_factor : (1 - (χ h : ℂ)) * S = 0 := by
    calc
      (1 - (χ h : ℂ)) * S = S - (χ h : ℂ) * S := by ring
      _ = 0 := by rw [h_eq]
  have h1minus_ne : (1 - (χ h : ℂ)) ≠ 0 := by
    intro hz
    apply hχh_ne
    linarith
  have hS : S = 0 := by
    rcases mul_eq_zero.mp h_factor with hzero | hS
    · exact (h1minus_ne hzero).elim
    · exact hS
  simpa [S] using hS

end T1
end TemTH
