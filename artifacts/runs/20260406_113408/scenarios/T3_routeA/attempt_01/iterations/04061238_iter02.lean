/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_routeA (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  rcases root with ⟨ζ, hprim⟩
  simpa [cyclicChar] using hprim.pow_of_coprime a.isCoprime'.symm.geom_sum_eq_zero (by
    have hNpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
    have hNe1 : N ≠ 1 := by
      intro h1
      apply ha
      ext
      simpa [h1] using Fin.eq_iff_veq.mpr rfl
    omega)

end T3
end TemTH
