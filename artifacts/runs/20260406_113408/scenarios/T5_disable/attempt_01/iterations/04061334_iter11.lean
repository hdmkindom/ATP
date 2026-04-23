/-
`temTH` 模板：`T5` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.RootsOfUnity.Basic

open BigOperators
open CandidateTheorems.T3
open CandidateTheorems.T5
open ComplexConjugate
open scoped

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_disable (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  let Φ : ZMod N → ℂ := fun k => if k = 0 then (1 : ℂ) else 0
  have hfourier : FourierTransformInv.fourierInv (ZMod.dft Φ) = Φ := by
    simpa using FourierPair.fourierInv_fourier_eq (f := Φ)
  have happly := congrFun hfourier t
  dsimp [Φ] at happly
  rw [ZMod.invDFT_apply, ZMod.dft_apply] at happly
  simp only [smul_eq_mul, Pi.zero_apply, Pi.one_apply, Finset.mul_sum] at happly
  have hchar :
      (fun j : ZMod N => if j = 0 then stdAddChar (j * (t : ZMod N)) else 0) =
        fun j : ZMod N => cyclicChar root ⟨j.val, j.is_lt⟩ t := by
    funext j
    by_cases hj : j = 0
    · subst hj
      simp [cyclicChar]
    · simp [hj, cyclicChar]
  simp_rw [if_t_t] at happly
  simpa [delta0, one_div, mul_comm, mul_left_comm, mul_assoc, hchar] using happly

end T5
end TemTH
