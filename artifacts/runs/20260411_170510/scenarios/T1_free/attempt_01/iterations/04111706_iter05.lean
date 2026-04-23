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
  by_contra hsum
  have hsum_units : (∑ g : G, χ g : ℂˣ) ≠ 0 := by
    simpa using hsum
  have hmul : (χ (∑ g : G, 1 : G) : ℂˣ) * (∑ g : G, χ g : ℂˣ) = (∑ g : G, χ g : ℂˣ) := by
    let a : G := ∑ g : G, 1
    calc
      (χ a : ℂˣ) * (∑ g : G, χ g : ℂˣ)
          = ∑ g : G, ((χ a : ℂˣ) * χ g) := by
              simpa [mul_sum]
      _ = ∑ g : G, χ (a * g) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simp [map_mul]
      _ = ∑ g : G, χ g := by
            simpa using Finset.sum_bij (fun g _ => a * g)
              (by intro g hg; simp)
              (by intro g hg; simp)
              (by intro g₁ g₂ hg₁ hg₂ h; simpa using mul_left_cancel h)
              (by intro g hg; refine ⟨a⁻¹ * g, by simp, ?_⟩; simp [mul_assoc])
      _ = (∑ g : G, χ g : ℂˣ) := rfl
  have hχa : (χ (∑ g : G, 1 : G) : ℂˣ) = 1 := by
    exact mul_right_cancel₀ hsum_units hmul
  have hpow : (χ (∑ g : G, 1 : G) : ℂˣ) = χ 1 := by
    simpa using congrArg χ (Fintype.sum_one)
  have hχ1 : χ 1 = 1 := by simpa using map_one χ
  have : χ = 1 := by
    ext g
    have hgpow : (χ g : ℂˣ) ^ Fintype.card G = 1 := by
      -- In a finite group, g^(card G) = 1
      have hgcard : g ^ Fintype.card G = (1 : G) := by
        simpa using pow_card_eq_one g
      simpa [map_pow, hgcard] using congrArg χ hgcard
    -- combine with hχa/hpow to force χ g = 1
    -- standard finite-order argument in units
    exact one_eq_of_pow_eq_one hgpow
  exact hχ this

end T1
end TemTH
