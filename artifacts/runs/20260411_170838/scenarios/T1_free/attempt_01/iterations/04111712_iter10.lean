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
  have hχ' : ∃ g0 : G, χ g0 ≠ (1 : ℂˣ) := by
    by_contra h
    apply hχ
    ext g
    by_contra hg
    exact h ⟨g, hg⟩
  rcases hχ' with ⟨g0, hg0⟩

  have hg0_ne_one_C : ((χ g0 : ℂˣ) : ℂ) ≠ 1 := by
    intro hC
    apply hg0
    exact Units.ext (by simpa using hC)

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hperm :
      ∑ g : G, ((χ (g0 * g) : ℂˣ) : ℂ) = S := by
    classical
    refine Finset.sum_bij (fun g : G => g0 * g) ?hmem ?heq ?hinj ?hsurj
    · intro g hg
      simp
    · intro g hg
      simp [S]
    · intro a ha b hb hab
      exact mul_left_cancel hab
    · intro b hb
      refine ⟨g0⁻¹ * b, by simp, ?_⟩
      simp [S, mul_assoc]

  have hmul :
      ∑ g : G, ((χ (g0 * g) : ℂˣ) : ℂ)
        = ((χ g0 : ℂˣ) : ℂ) * S := by
    calc
      ∑ g : G, ((χ (g0 * g) : ℂˣ) : ℂ)
          = ∑ g : G, (((χ g0 : ℂˣ) * (χ g : ℂˣ) : ℂˣ) : ℂ) := by
              simp [map_mul]
      _ = ∑ g : G, (((χ g0 : ℂˣ) : ℂ) * ((χ g : ℂˣ) : ℂ)) := by
            simp
      _ = ((χ g0 : ℂˣ) : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simp [mul_sum]
      _ = ((χ g0 : ℂˣ) : ℂ) * S := by simp [S]

  have hfixed : ((χ g0 : ℂˣ) : ℂ) * S = S := by
    calc
      ((χ g0 : ℂˣ) : ℂ) * S
          = ∑ g : G, ((χ (g0 * g) : ℂˣ) : ℂ) := hmul.symm
      _ = S := hperm

  have hzero : S = 0 := by
    have hsub : (((χ g0 : ℂˣ) : ℂ) - 1) * S = 0 := by
      calc
        (((χ g0 : ℂˣ) : ℂ) - 1) * S
            = ((χ g0 : ℂˣ) : ℂ) * S - S := by ring
        _ = S - S := by simpa [hfixed]
        _ = 0 := sub_self S
    have hfac_ne : ((χ g0 : ℂˣ) : ℂ) - 1 ≠ 0 := sub_ne_zero.mpr hg0_ne_one_C
    exact (mul_eq_zero.mp hsub).resolve_left hfac_ne

  simpa [S] using hzero

end T1
end TemTH
