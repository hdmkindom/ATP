/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_disable (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  let ψ : AddChar (ZMod N) ℂ :=
    stdAddChar (N := N) ^ (a : ZMod N)
  have hψ_prim : ψ.IsPrimitive := by
    simpa [ψ] using (ZMod.isPrimitive_stdAddChar (N := N)).pow (a := (a : ZMod N)) ha
  have hsum : ∑ x : ZMod N, ψ x = 0 := by
    exact AddChar.sum_eq_zero_of_ne_one (by
      intro h1
      have hEq := AddChar.IsPrimitive.zmod_char_eq_one_iff (n := N) hψ_prim (a : ZMod N)
      have hψa : ψ (a : ZMod N) = 1 := by simpa [h1]
      have : (a : ZMod N) = 0 := (hEq.mp hψa)
      exact ha (Fin.ext this))
  simpa [ψ, cyclicChar] using hsum

end T3
end TemTH
