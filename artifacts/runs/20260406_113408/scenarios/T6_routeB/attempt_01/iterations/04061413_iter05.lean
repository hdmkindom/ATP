/-
`temTH` 模板：`T6` 路线 B。
-/
import CandidateTheorems.T6.Support

namespace TemTH
namespace T6

open CandidateTheorems.T6

variable {α : Type*} [Fintype α]

theorem candidate_T6_routeB (data : StandardScaleData (α := α)) :
    gaussSum data.χ data.ψₐ = data.scale * gaussSum data.χ data.ψ₁ := by
  simpa [data.scale, data.ψₐ, data.ψ₁] using
    (gaussSum_mulShift data.χ data.baseAddChar data.a).symm

end T6
end TemTH
