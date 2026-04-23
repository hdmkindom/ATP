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
  classical
  let Φ : ZMod N → ℂ := fun x => if x = 0 then (1 : ℂ) else 0
  have hinv := ZMod.invDFT_apply (N := N) (Ψ := ZMod.dft Φ) (k := (t : ZMod N))
  have hpair : (𝓕⁻ (𝓕 Φ)) (t : ZMod N) = Φ (t : ZMod N) := by
    simpa using (FourierTransformInv.fourierInv_fourier_eq (f := Φ) (t : ZMod N))
  rw [ZMod.invDFT_apply'] at hpair
  have hdft : (𝓕 Φ) (-(t : ZMod N)) = ∑ a : Fin N, cyclicChar root a t := by
    simp [Φ, ZMod.dft_apply, cyclicChar]
  have hPhi : Φ (t : ZMod N) = delta0 (N := N) t := by
    by_cases ht : t = 0
    · subst ht
      simp [Φ, delta0]
    · simp [Φ, delta0, ht]
  have hN : (N : ℂ) ≠ 0 := by
    exact_mod_cast (NeZero.ne N)
  rw [hPhi] at hpair
  rw [hdft] at hpair
  have hmul := congrArg (fun z : ℂ => (N : ℂ) * z) hpair
  simp [hN] at hmul
  linarith

end T5
end TemTH
