/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  obtain ⟨g0, hg0⟩ : ∃ g0 : G, χ g0 ≠ 1 := by
    by_contra h
    apply hχ
    ext g
    by_contra hg
    exact h ⟨g, hg⟩

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hperm : ∑ g : G, (χ (g0 * g) : ℂ) = S := by
    let e : G ≃ G :=
      { toFun := fun g => g0 * g
        invFun := fun g => g0⁻¹ * g
        left_inv := by
          intro g
          simp [mul_assoc]
        right_inv := by
          intro g
          simp [mul_assoc] }
    calc
      ∑ g : G, (χ (g0 * g) : ℂ)
          = ∑ g : G, (χ (e g) : ℂ) := by rfl
      _ = ∑ g : G, (χ g : ℂ) := by simpa using (Fintype.sum_equiv e (fun g : G => (χ g : ℂ)))
      _ = S := by rfl

  have hmul : ∑ g : G, (χ (g0 * g) : ℂ) = (χ g0 : ℂ) * S := by
    calc
      ∑ g : G, (χ (g0 * g) : ℂ)
          = ∑ g : G, ((χ g0 : ℂ) * (χ g : ℂ)) := by
              simp [map_mul]
      _ = (χ g0 : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simpa [Finset.mul_sum]
      _ = (χ g0 : ℂ) * S := by rfl

  have hfixed : (χ g0 : ℂ) * S = S := by
    calc
      (χ g0 : ℂ) * S = ∑ g : G, (χ (g0 * g) : ℂ) := hmul.symm
      _ = S := hperm

  have hg0_ne_one_C : (χ g0 : ℂ) ≠ 1 := by
    intro hC
    apply hg0
    exact Units.ext (by simpa using hC)

  have hzero : S = 0 := by
    have hsub : ((χ g0 : ℂ) - 1) * S = 0 := by
      calc
        ((χ g0 : ℂ) - 1) * S = (χ g0 : ℂ) * S - S := by ring
        _ = S - S := by simpa [hfixed]
        _ = 0 := sub_self S
    have hfac_ne : (χ g0 : ℂ) - 1 ≠ 0 := sub_ne_zero.mpr hg0_ne_one_C
    exact (mul_eq_zero.mp hsub).resolve_left hfac_ne

  simpa [S] using hzero

end T1
end TemTH
