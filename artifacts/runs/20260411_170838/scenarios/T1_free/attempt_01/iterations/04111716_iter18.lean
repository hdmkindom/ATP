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
  -- Choose g₀ with χ g₀ ≠ 1.
  have hex : ∃ g0 : G, χ g0 ≠ 1 := by
    by_contra h
    apply hχ
    ext g
    by_contra hg
    exact h ⟨g, hg⟩
  rcases hex with ⟨g0, hg0⟩

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  -- Reindex by left-multiplication by g₀.
  have hperm : ∑ g : G, (χ (g0 * g) : ℂ) = S := by
    simpa [S] using
      (Fintype.sum_bijective
        (fun g : G => g0 * g)
        (fun g _ => g0⁻¹ * g)
        (by intro g _; simp [mul_assoc])
        (by intro g _; simp [mul_assoc]))

  -- Multiplicativity: translated sum is χ(g₀) • S.
  have hmul : ∑ g : G, (χ (g0 * g) : ℂ) = (χ g0 : ℂ) * S := by
    calc
      ∑ g : G, (χ (g0 * g) : ℂ)
          = ∑ g : G, ((χ g0 : ℂ) * (χ g : ℂ)) := by
              simp [map_mul]
      _ = (χ g0 : ℂ) * S := by
            simp [S, Finset.mul_sum]

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
