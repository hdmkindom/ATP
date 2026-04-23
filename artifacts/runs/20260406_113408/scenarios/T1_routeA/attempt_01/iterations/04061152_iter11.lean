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
  rcases (MulChar.ne_one_iff.mp hχ) with ⟨u, hu⟩
  let h : G := u
  have hh_ne : χ h ≠ 1 := by
    simpa [h] using hu
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    dsimp [S]
    simpa using
      (Function.Bijective.sum_comp
        (e := fun g : G => h * g)
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
              simp [h, mul_assoc]
      _ = ∑ g : G, (χ h : ℂ) * (χ g : ℂ) := rfl
      _ = (χ h : ℂ) * S := by
            simp [S, Finset.mul_sum]
  have h_eq : S = (χ h : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := h_reindex.symm
      _ = (χ h : ℂ) * S := h_mul
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    intro hcoeeq
    apply hh_ne
    exact Complex.ext (by simpa using hcoeeq) (by simp)
  have h_factor : (1 - (χ h : ℂ)) * S = 0 := by
    have := h_eq
    linarith
  have h1minus_ne : (1 - (χ h : ℂ)) ≠ 0 := by
    intro hz
    apply hχh_ne
    have : (χ h : ℂ) = 1 := by linarith
    simpa using this
  have hS : S = 0 := by
    exact Or.resolve_left (mul_eq_zero.mp h_factor) h1minus_ne
  simpa [S] using hS

end T1
end TemTH
