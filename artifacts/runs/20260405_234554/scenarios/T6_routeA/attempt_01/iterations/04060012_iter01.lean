/-
`temTH` 模板：`T6` 路线 A。
-/
import CandidateTheorems.T6.Support

namespace TemTH
namespace T6

open CandidateTheorems.T6

variable {α : Type*} [Fintype α]

theorem candidate_T6_routeA (data : ChangeOfVariablesData (α := α)) :
    gaussSum data.χ data.ψₐ = data.scale * gaussSum data.χ data.ψ₁ := by
  simpa using gaussSum_scale_via_bijective_change (data := data)

end T6
end TemTH
