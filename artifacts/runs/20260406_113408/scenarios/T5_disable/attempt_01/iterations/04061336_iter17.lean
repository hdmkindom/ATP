/-
`temTH` 模板：`T5` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_disable (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  rw [delta0, ← Finset.card_univ]
  simp only [Finset.card_univ, Fintype.card_fin]
  have havg :
      ((↑N : ℂ) : ℂ)⁻¹ * ∑ a : AddChar (Fin N) ℂ, a t = if t = 0 then 1 else 0 := by
    simpa [one_div] using (AddChar.expect_apply_eq_ite (a := t) :
      (⅟(Fintype.card (AddChar (Fin N) ℂ) : ℂ)) • ∑ ψ : AddChar (Fin N) ℂ, ψ t = if t = 0 then 1 else 0)
  have hcard : Fintype.card (AddChar (Fin N) ℂ) = N := by
    simpa using Fintype.card_addChar (Fin N) ℂ
  rw [← hcard] at havg
  let e : Fin N ≃ AddChar (Fin N) ℂ :=
    Fintype.equivOfCardEq (by simpa [hcard])
  have hsum : ∑ a : Fin N, cyclicChar root a t = ∑ ψ : AddChar (Fin N) ℂ, ψ t := by
    classical
    simp [cyclicChar, e, Finset.univ_bijective e.bijective]
  rw [hsum]
  simpa [one_div] using havg

end T5
end TemTH
