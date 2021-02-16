import prelim.size prelim.induction prelim.collections prelim.minmax 
import .rankfun .indep 

local attribute [instance] classical.prop_decidable
noncomputable theory 

variables {U : Type}[fintype U]

open set 

namespace clfun

lemma monotone (M : clfun U){X Y : set U} :
  X ⊆ Y → M.cl X ⊆ M.cl Y :=
  λ h, M.cl3 _ _ h

lemma subset_union (M : clfun U)(X Y : set U) :
  M.cl X ∪ M.cl Y ⊆ M.cl (X ∪ Y) :=
  union_of_subsets (M.cl3 _ _ (subset_union_left X Y)) (M.cl3 _ _ (subset_union_right X Y))
  

lemma cl_union_both (M : clfun U)(X Y : set U) :
  M.cl (X ∪ Y) = M.cl(M.cl X ∪ M.cl Y) :=
  begin
    apply subset.antisymm, 
    from monotone M (union_subset_union (M.cl1 X) (M.cl1 Y)),
    have := monotone M (subset_union M X Y),
    rw M.cl2 at this, assumption
  end


lemma union_pair {M : clfun U}{X Y : set U} (Z: set U): 
  M.cl X = M.cl Y → M.cl (X ∪ Z) = M.cl (Y ∪ Z) :=
  λ h, by rw [cl_union_both _ X, cl_union_both _ Y, h]

lemma cl_union_left (M : clfun U)(X Y : set U) :
  M.cl (M.cl X ∪ Y) = M.cl (X ∪ Y)  :=
  clfun.union_pair Y (M.cl2 X)

def is_indep (M : clfun U) : set U → Prop := 
  λ I, ∀ (e:U), e ∈ I → M.cl (I \ {e}) ≠ M.cl I 

/-- all sets spanning X -/
def spans (M : clfun U)(X : set U) : Type := 
  {A : set U // X ⊆ M.cl A} 

instance spans_fin (M : clfun U)(X : set U): fintype (M.spans X) :=
  by {unfold spans, apply_instance}

instance spans_nonempty (M : clfun U)(X : set U) : nonempty (M.spans X) := 
  by {apply nonempty_subtype.mpr, from ⟨X, M.cl1 X⟩}

def r (M : clfun U) : set U → ℤ := 
  λ X, min_val (λ (A : M.spans X), size A.val) 

lemma R1 (M : clfun U):
  satisfies_R1 M.r := 
begin
  intros X, unfold clfun.r, 
  rcases min_spec (λ (A : M.spans X), size A.val) with ⟨⟨B,hB⟩, ⟨hB₁, hB₂⟩⟩, 
  rw ←hB₁, from hB₂ ⟨X, M.cl1 X⟩,
end

lemma R2 (M : clfun U):
  satisfies_R2 M.r := 
begin
  intros X Y hXY, 
  rcases min_spec (λ (A : M.spans Y), size A.val) with ⟨⟨BY,hBY⟩, ⟨hBY₁, hBY₂⟩⟩,
  unfold clfun.r, rw [←hBY₁],
  from min_is_lb (λ (A : M.spans X), size A.val) ⟨BY,trans hXY hBY⟩, 
end

lemma R3 (M : clfun U):
  satisfies_R3 M.r :=
begin
  intros X Y, 
  sorry 
end

lemma satisfies_I1 (M : clfun U) : 
  satisfies_I1 M.is_indep :=
  λ e h, false.elim (not_mem_empty e h)
  
lemma satisfies_I2 (M : clfun U) : 
  satisfies_I2 M.is_indep :=
begin
  apply indep_family.weak_I2_to_I2 (λ X, M.is_indep X), 
  intros I e heI hIe,
  by_contra h, unfold is_indep at h, push_neg at h, 
  rcases h with ⟨f, ⟨hfI, hIfcl⟩⟩, 
  have := union_pair (e: set U) hIfcl, 
  rw exchange_comm hfI heI at this, 
  from hIe f (mem_of_mem_of_subset hfI (subset_union_left I e)) this, 
end 

lemma satisfies_I3 (M : clfun U) : 
  satisfies_I3 M.is_indep :=
begin
  sorry 
end

end clfun 

def indep_family.of_clfun (M : clfun U) : indep_family U := 
⟨M.is_indep, M.satisfies_I1, M.satisfies_I2, M.satisfies_I3⟩

namespace matroid 

def of_clfun (M : clfun U) : matroid U := 
  of_indep_family (indep_family.of_clfun M)

lemma cl_of_clfun (M : clfun U) : 
  (of_clfun M).cl = M.cl :=
begin
  funext X, rw [of_clfun], ext f,
  rw mem_cl_iff_i, dsimp only [ftype.ftype_coe], 
  erw [matroid.indep_of_indep_family, indep_family.of_clfun], dsimp only, 
  rw [clfun.is_indep], dsimp only, 

  refine ⟨λ h, _, λ h, _⟩, 
  rcases h with ⟨I, hIX, ⟨hIe₁, hIe₂⟩⟩,
  specialize hIe₂ _ (subset_refl _),  
  have : f ∉ I := λ hf, by 
  {
    have := hIe₁ f hf, 
    sorry -- working with the closure axioms is annoying 
  } ,
  sorry, 
  sorry, 
end 

end matroid 

