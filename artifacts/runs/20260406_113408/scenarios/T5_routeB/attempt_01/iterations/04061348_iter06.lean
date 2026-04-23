/-
`temTH` 模板：`T5` 路线 B。
-/
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_routeB
    (data : FourierInversionData (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, data.ψ a t := by
  classical
  -- Fourier inversion viewpoint: the average over the full character family is
  -- exactly the expectation identity for additive characters on the finite group `Fin N`.
  rw [delta0]
  rw [AddChar.expect_apply_eq_ite]
  simp [div_eq_mul_inv, mul_comm, mul_left_comm, mul_assoc]

end T5
end TemTH
