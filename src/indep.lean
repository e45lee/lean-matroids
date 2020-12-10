/-
Goal: state and prove the relationship between deletion, contraction, and duality.

Existence of a normal form:
  expressions of the form M/C\D are closed under deletion and contraction,
  and together with M*/C\D they are closed under duality.

Current idea: define restriction and corestriction from U to subalg E
Then deletion and contraction are instances of these maps
And a sequence of deletions and contractions with disjoint arguments can be composed
-/

import rankfun boolalg boolalg_induction 
open boolalg 
--open boolalg_induction 

local attribute [instance] classical.prop_decidable

----------------------------------------------------------------

-- For this file, we'll define matroids as living inside a common universe U.
def matroid_on {U : boolalg} (E : U) : Type :=
  rankfun (subalg E)

----------------------------------------------------------------

section matroid_heq
variables
  {U : boolalg}
  {E₁ E₂ E₃ : U}
  {M₁ : matroid_on E₁}
  {M₂ : matroid_on E₂}
  {M₃ : matroid_on E₃}

-- Since we have a common universe, we can talk about matroid equality.
def matroid_heq (M₁ : matroid_on E₁) (M₂ : matroid_on E₂) : Prop :=
  (E₁ = E₂) ∧ forall (X : U) (h₁ : X ⊆ E₁) (h₂ : X ⊆ E₂),
  M₁.r ⟨X, h₁⟩ = M₂.r ⟨X, h₂⟩
notation M₁ ` ≅ ` M₂ := matroid_heq M₁ M₂

-- This is an equivalence relation, unsurprisingly: reflexive, symmetric, transitive.
lemma matroid_heq.refl {E : U} (M : matroid_on E) :
  (M ≅ M) :=
⟨rfl, fun _ _ _, rfl⟩

lemma matroid_heq.symm :
  (M₁ ≅ M₂) → (M₂ ≅ M₁) :=
fun ⟨hE, hr⟩, ⟨hE.symm, fun X h₂ h₁, (hr X h₁ h₂).symm⟩

lemma matroid_heq.trans :
  (M₁ ≅ M₂) → (M₂ ≅ M₃) → (M₁ ≅ M₃) :=
fun ⟨hE₁₂, hr₁₂⟩ ⟨hE₂₃, hr₂₃⟩, ⟨hE₁₂.trans hE₂₃, fun X h₁ h₃, let h₂ : X ⊆ E₂ := eq.rec h₁ hE₁₂ in (hr₁₂ X h₁ h₂).trans (hr₂₃ X h₂ h₃)⟩

-- If the ground sets are defeq, we can upgrade matroid_heq to an eq of rankfun.
lemma matroid_heq.to_eq {E : U} {M₁ M₂ : matroid_on E} :
  (M₁ ≅ M₂) → (M₁ = M₂) :=
fun ⟨_, hr⟩, rankfun.ext _ _ (funext (@subtype.rec _ _ (fun X, M₁.r X = M₂.r X) (fun X h, hr X h h)))

lemma eq_to_matroid_heq {E : U} {M₁ M₂ : matroid_on E} : 
  (M₁ = M₂) → (M₁ ≅ M₂) := 
  λ h, by {rw h, apply matroid_heq.refl}

end /-section-/ matroid_heq

----------------------------------------------------------------

section dual
variables {U : boolalg}

-- Every matroid has a dual.
def dual :
  rankfun U → rankfun U :=
fun M, {
  r := (fun X, size X + M.r Xᶜ - M.r ⊤),
  R0 := (fun X,
    calc 0 ≤ M.r X  + M.r Xᶜ - M.r (X ∪ Xᶜ) - M.r (X ∩ Xᶜ) : by linarith [M.R3 X Xᶜ]
    ...    = M.r X  + M.r Xᶜ - M.r ⊤        - M.r ⊥        : by rw [union_compl X, inter_compl X]
    ...    ≤ size X + M.r Xᶜ - M.r ⊤                       : by linarith [M.R1 X, rank_bot M]),
  R1 := (fun X, by linarith [M.R2 _ _ (subset_top Xᶜ)]),
  R2 := (fun X Y h, let
    Z := Xᶜ ∩ Y,
    h₁ :=
      calc Yᶜ ∪ Z = (Xᶜ ∩ Y) ∪ Yᶜ        : by apply union_comm
      ...         = (Xᶜ ∪ Yᶜ) ∩ (Y ∪ Yᶜ) : by apply union_distrib_right
      ...         = (X ∩ Y)ᶜ ∩ ⊤         : by rw [compl_inter X Y, union_compl Y]
      ...         = (X ∩ Y)ᶜ             : by apply inter_top
      ...         = Xᶜ                   : by rw [inter_subset_mp h],
    h₂ :=
      calc Yᶜ ∩ Z = (Xᶜ ∩ Y) ∩ Yᶜ : by apply inter_comm
      ...         = Xᶜ ∩ (Y ∩ Yᶜ) : by apply inter_assoc
      ...         = Xᶜ ∩ ⊥        : by rw [inter_compl Y]
      ...         = ⊥             : by apply inter_bot,
    h₃ :=
      calc M.r Xᶜ = M.r Xᶜ + M.r ⊥              : by linarith [rank_bot M]
      ...         = M.r (Yᶜ ∪ Z) + M.r (Yᶜ ∩ Z) : by rw [h₁, h₂]
      ...         ≤ M.r Yᶜ + M.r Z              : by apply M.R3
      ...         ≤ M.r Yᶜ + size Z             : by linarith [M.R1 Z]
      ...         = M.r Yᶜ + size (Xᶜ ∩ Y)      : by refl
      ...         = M.r Yᶜ + size Y - size X    : by linarith [compl_inter_size_subset h]
    in by linarith),
  R3 := (fun X Y,
    calc  size (X ∪ Y) + M.r (X ∪ Y)ᶜ  - M.r ⊤ + (size (X ∩ Y) + M.r (X ∩ Y)ᶜ  - M.r ⊤)
        = size (X ∪ Y) + M.r (Xᶜ ∩ Yᶜ) - M.r ⊤ + (size (X ∩ Y) + M.r (Xᶜ ∪ Yᶜ) - M.r ⊤) : by rw [compl_union X Y, compl_inter X Y]
    ... ≤ size X       + M.r Xᶜ        - M.r ⊤ + (size Y       + M.r Yᶜ        - M.r ⊤) : by linarith [size_modular X Y, M.R3 Xᶜ Yᶜ]),
}

-- The double dual of a matroid is itself.
lemma dual_dual (M : rankfun U) :
  dual (dual M) = M :=
begin
  apply rankfun.ext, apply funext, intro X, calc
  (dual (dual M)).r X = size X + (size Xᶜ + M.r Xᶜᶜ - M.r ⊤) - (size (⊤ : U) + M.r ⊤ᶜ - M.r ⊤) : rfl
  ...                 = size X + (size Xᶜ + M.r X   - M.r ⊤) - (size (⊤ : U) + M.r ⊥  - M.r ⊤) : by rw [compl_compl, boolalg.compl_top]
  ...                 = M.r X                                                                  : by linarith [size_compl X, rank_bot M]
end

lemma dual_r (M : rankfun U)(X : U):
   (dual M).r X = size X + M.r Xᶜ - M.r ⊤ := 
   rfl 

end /-section-/ dual

----------------------------------------------------------------

section minor 

variables {U : boolalg}

inductive minor_expression  : U → Type
| self                       : minor_expression ⊤
| restrict   (X : U) {E : U} : (X ⊆ E) → minor_expression E → minor_expression X
| corestrict (X : U) {E : U} : (X ⊆ E) → minor_expression E → minor_expression X
open minor_expression



def to_minor : Π {E : U}, minor_expression E → rankfun U → matroid_on E
| _ self r := restrict_subset _ r
| _ (restrict _ hE' expr) r := restrict_nested_pair hE' (to_minor expr r)
| _ (corestrict _ hE' expr) r := corestrict_nested_pair hE' (to_minor expr r)


lemma to_minor.delete_delete {D₁ D₂ : U} (h : D₁ ∩ D₂ = ⊥) :
let
  h₁ : (D₁ ∪ D₂)ᶜ ⊆ D₁ᶜ := sorry,
  h₂ :  D₁ᶜ       ⊆ ⊤   := sorry,
  h₃ : (D₁ ∪ D₂)ᶜ ⊆ ⊤   := sorry
in
  to_minor (restrict (D₁ ∪ D₂)ᶜ h₁
           (restrict  D₁ᶜ       h₂ self)) =
  to_minor (restrict (D₁ ∪ D₂)ᶜ h₃ self) :=
begin
  intros,
  delta to_minor,
  refl,
end



@[simp] def contract_delete  (C D : U) :
  (C ∩ D = ⊥) → minor_expression (C ∪ D)ᶜ :=
fun h, restrict (C ∪ D)ᶜ (calc (C ∪ D)ᶜ = Cᶜ ∩ Dᶜ : compl_union _ _ ... ⊆ Cᶜ : inter_subset_left _ _ ) (corestrict Cᶜ (subset_top _) self)

--simplified minor expression - corestrict to Z, then restrict to A 



lemma switch_restrict_corestrict {M : rankfun U} (A Z : U) (hAZ : A ⊆ Z) : 
  to_minor (restrict A hAZ ((corestrict Z (subset_top Z)) self)) M = to_minor (corestrict A (subset_union_left A Zᶜ) ((restrict (A ∪ Zᶜ) (subset_top (A ∪ Zᶜ))) self)) M :=
  let f := (embed.from_subset A).f, hAZc := subset_union_left A Zᶜ, hAZc_top := subset_top (A ∪ Zᶜ) in 
  begin
    ext X, 
    have set_eq : A ∪ Zᶜ - A = ⊤ - Z := by {simp, unfold has_sub.sub, rw [inter_distrib_right, inter_compl,bot_union, ←compl_union, union_comm, union_subset_mp hAZ]}, 
    have RHS : (to_minor (corestrict A hAZc (restrict (A ∪ Zᶜ) hAZc_top self)) M).r X = M.r (f X ∪ (A ∪ Zᶜ - A)) - M.r (A ∪ Zᶜ - A) := rfl, 
    rw set_eq at RHS, 
    exact RHS.symm, 
  end


lemma dual_restrict_corestrict {M : rankfun U} (A Z : U) (hAZ : A ⊆ Z) : 
  dual (to_minor (restrict A hAZ (corestrict Z (subset_top Z) self)) M) = to_minor (corestrict A hAZ (restrict Z (subset_top Z) self)) (dual M) := 
  let emb := embed.from_subset A in 
  begin
    rw switch_restrict_corestrict, ext X, apply eq.symm, 
    have hJ : ∀ (J : U) (hJ : J ⊆ A), (J ∪ (Z-A))ᶜ = (A - J) ∪ (⊤ - Z) := 
      λ J hJ, by rw [compl_union, top_diff, compl_diff, diff_def, inter_distrib_left, ←compl_union, union_subset_mp (subset_trans hJ hAZ), inter_comm, union_comm], 
    have hset : size ((X:U) ∩ (Z - A)) = 0 := 
      by {suffices : ((X:U) ∩ (Z-A)) = ⊥, rw this, exact size_bot U, apply subset_bot, refine subset_trans (subset_inter_subset_left (X :U ) A (Z-A) X.2) _, rw inter_diff, apply subset_refl},
    have hbot : (Z-A)ᶜ = A ∪ (⊤ - Z) := 
      by {rw [←bot_union (Z-A), hJ ⊥ (bot_subset _), diff_bot]},

    calc _ = (size ((X:U) ∪ (Z-A)) + M.r ((X ∪ (Z-A))ᶜ) - M.r ⊤) - (size (Z-A) + M.r (Z-A)ᶜ - M.r ⊤ )       : rfl 
       ... = size (X:U) + M.r ((X ∪ (Z-A))ᶜ) - M.r  (Z-A)ᶜ                                                   : by linarith [size_modular (X :U) (Z -A), hset, emb.on_size X]
       ... = size (X:U) + M.r ((A- X) ∪ (⊤ - Z)) - M.r (A ∪ (⊤ - Z))                                        : by rw [(hJ X X.2 : ((X:U) ∪ (Z-A))ᶜ = (A- X) ∪ (⊤ - Z)), hbot]
       ... = size (X:U) + (M.r ((A- X) ∪ (⊤ - Z)) - M.r (⊤ - Z)) - (M.r (A ∪ (⊤ - Z)) - M.r (⊤ - Z))        : by linarith 
       ... = (dual (to_minor (restrict A hAZ (corestrict Z (subset_top Z) self)) M)).r X                     : rfl 
       ... = _ : by rw switch_restrict_corestrict,             
  end

lemma dual_corestrict_restrict {M : rankfun U} (A Z : U) (hAZ : A ⊆ Z) : 
  dual (to_minor (corestrict A hAZ (restrict Z (subset_top Z) self)) M) = to_minor (restrict A hAZ (corestrict Z (subset_top Z) self)) (dual M) := 
  by {nth_rewrite 0 ←(dual_dual M), rw [←dual_restrict_corestrict, dual_dual]}


lemma restrict_top {M : rankfun U}{A : U} (expr: minor_expression A) : 
  to_minor (restrict A (subset_refl A) expr) M = to_minor expr M := 
  by {ext X,cases X,refl}

lemma corestrict_top {M : rankfun U}{A : U} (expr: minor_expression A) : 
  to_minor (corestrict A (subset_refl A) expr) M = to_minor expr M :=
begin
  simp [to_minor],
  set M' := to_minor expr M,
  apply rankfun.ext, ext X, 
  simp only,
  set f := (embed.from_nested_pair (subset_refl A)).f,
  have : (embed.to_subalg A A _) = ⊤ := rfl,
  rw [this,  boolalg.compl_top, union_bot, rank_bot M'],
  rw [(by cases X; refl: f X = X)],
  linarith,
end

lemma dual_restrict {M: rankfun U} (A : U) : 
  dual (to_minor (restrict A (subset_top A) self) M) = to_minor (corestrict A (subset_top A) self) (dual M) := 
    by rw [←(corestrict_top (restrict A (subset_top A) self)), dual_corestrict_restrict, restrict_top]
    
lemma dual_corestrict {M: rankfun U} (A : U) : 
  dual (to_minor (corestrict A (subset_top A) self) M) = to_minor (restrict A (subset_top A) self) (dual M) := 
    by rw [←(restrict_top (corestrict A (subset_top A) self)), dual_restrict_corestrict, corestrict_top]

lemma switch_corestrict_restrict {M : rankfun U} (A Z : U) (hAZ : A ⊆ Z) : 
  to_minor (corestrict A hAZ ((restrict Z (subset_top Z)) self)) M = to_minor (restrict A (subset_union_left A Zᶜ) ((corestrict (A ∪ Zᶜ) (subset_top (A ∪ Zᶜ))) self)) M :=
  by {nth_rewrite 0 ←(dual_dual M), rw [←dual_restrict_corestrict, switch_restrict_corestrict, dual_corestrict_restrict, dual_dual]}


lemma restrict_restrict {M : rankfun U} (A Z : U) (hAZ : A ⊆ Z) : 
  to_minor (restrict A hAZ (restrict Z (subset_top Z) self)) M = to_minor (restrict A (subset_top A) self) M :=
  let f := (embed.from_subset A).f in 
  by {ext X,calc _ = M.r (f X) : rfl ...= _ : rfl}
     
lemma corestrict_corestrict {M : rankfun U} (A Z : U) (hAZ : A ⊆ Z) : 
  to_minor (corestrict A hAZ (corestrict Z (subset_top Z) self)) M = to_minor (corestrict A (subset_top A) self) M :=   
  begin
    let M₀ := to_minor (corestrict Z (subset_top Z) self) M,  
    --nth_rewrite 0 ←(dual_dual M),
    
    
    --have := 
    --calc  
    sorry, 
  end

@[simp] def reduced_expr  (A Z : U) (hAZ : A ⊆ Z) : minor_expression A := 
  restrict A hAZ ((corestrict Z (subset_top Z)) self)

lemma restriction_of_reduced  {M : rankfun U} (A Z A' : U) (hA'A : A' ⊆ A) (hAZ : A ⊆ Z) : 
  to_minor (restrict A' hA'A (reduced_expr A Z hAZ)) M = to_minor (reduced_expr A' Z (subset_trans hA'A hAZ)) M := rfl

lemma corestriction_of_reduced' {M : rankfun U} (A Z Z' : U) (hZ'A : Z' ⊆ A) (hAZ : A ⊆ Z) : 
  to_minor (corestrict Z' hZ'A (reduced_expr A Z hAZ) ) M = to_minor (reduced_expr Z' (Z' ∪ (Z - A)) (subset_union_left Z' _)) M := 
  begin
    unfold reduced_expr, 

    calc to_minor (corestrict Z' hZ'A (reduced_expr A Z hAZ) ) M = to_minor (corestrict Z' hZ'A (reduced_expr A Z hAZ) ) M : rfl 
                                                             ... = to_minor (reduced_expr Z' (Z' ∪ (Z - A)) (subset_union_left Z' _)) M :sorry, 
  end 

lemma corestriction_of_reduced {M : rankfun U} (A Z Z' : U) (hZ'A : Z' ⊆ A) (hAZ : A ⊆ Z) : 
  to_minor (corestrict Z' hZ'A (reduced_expr A Z hAZ) ) M = to_minor (reduced_expr Z' (Z' ∪ (Z - A)) (subset_union_left Z' _)) M := 
  let  J  := Z' ∪ (Z - A),
       M' := to_minor (reduced_expr A Z hAZ) M, 
       N  := (to_minor (reduced_expr Z' J (subset_union_left _ _)) M) in 
  begin
    ext, rename x X, 
    have equiv : (A - Z') ∪ (⊤ - Z) = (⊤ - J) := by 
    {
      simp only [J], unfold has_sub.sub, 
      rw [top_inter, top_inter, compl_union, compl_inter, compl_compl, union_distrib_right, 
            ←compl_inter, inter_subset_mp (subset_trans hZ'A hAZ : Z' ⊆ Z), inter_comm, union_comm],
    }, 
    have LHS := 
    calc     (to_minor (corestrict Z' hZ'A (reduced_expr A Z hAZ)) M).r X
           = (corestrict_nested_pair hZ'A M').r X                                                 : rfl 
      ...  = M.r (X ∪ (A - Z') ∪ (⊤-Z)) - M.r (⊤ - Z)  - (M.r ((A - Z') ∪ (⊤ - Z)) - M.r (⊤ -Z)) : rfl  
      ...  = M.r (X ∪ (A - Z') ∪ (⊤-Z)) - M.r ((A - Z') ∪ (⊤ - Z))                               : by linarith
      ...  = M.r (X ∪ (⊤ - J)) - M.r (⊤ - J)                                                     : by rw [union_assoc, equiv],

    rw LHS, apply eq.symm, clear LHS, calc N.r X = _ : rfl, 
  end


-- Every minor expression is equivalent to a reduced one. 

lemma has_reduced_expr {M : rankfun U} {E : U} (expr : minor_expression E) :
  ∃ (Z : U) (hZ : E ⊆ Z), 
  to_minor (reduced_expr E Z hZ) M = to_minor expr M := 
begin
  induction expr with X₁ E₁ hX₁E₁ minor_expr IH 
                    X₁ A₁ hX₁A₁ minor_expr IH,
  /- self -/                  
  { use ⊤,  use subset_refl ⊤, simp [reduced_expr], rw [restrict_top, corestrict_top] },
  /-restrict-/
  {
    rcases IH with ⟨Z, ⟨hE₁Z, h⟩⟩,
    use Z, use subset_trans hX₁E₁ hE₁Z, 
    rw ← restriction_of_reduced,
    dunfold to_minor,
    rw h,
  },
  /-corestrict-/
  {
    rcases IH with ⟨Z, ⟨hA₁Z, h⟩⟩,
    use X₁ ∪ (Z - A₁), use subset_union_left X₁ _,
    rw ←corestriction_of_reduced _ _ _ hX₁A₁ hA₁Z,
    dunfold to_minor,
    rw h, 
  }
end

lemma has_representation {M : rankfun U} {E : U} (expr : minor_expression E) :
  (∃ (C D : U) (hCD : C ∩ D = ⊥),  
    (C ∪ D)ᶜ = E 
    ∧ ((to_minor (contract_delete C D hCD) M) ≅ (to_minor expr M))) :=
begin
  sorry, 
end


/-lemma has_good_representation {M : rankfun U} {E : U} (expr : minor_expression E) :
  (∃ (C D : U) (hCD : C ∩ D = ⊥),  
    (C ∪ D)ᶜ = E ∧
    is_indep M C ∧ is_coindep M D 
    ∧ ((to_minor (contract_delete C D hCD) M) ≅ (to_minor expr M))) := sorry-/
  
end minor 

section /- rank -/ rank
variables {U : boolalg}
-- Loops 


-- Sets containing only loops have rank zero. 


lemma loopy_rank_zero (M : rankfun U) (X : U) : (∀ e : boolalg.singleton U, (e : U) ⊆ X → M.r e = 0) → (M.r X = 0) :=
begin
  revert X, refine strong_induction _ _,
  intros X hX hSing,  
  by_cases hSize : (size X > 1),
  rcases (union_ssubsets X hSize) with ⟨Y, ⟨Z, ⟨hY, hZ, hI, hU⟩⟩⟩, 
  have := M.R3 Y Z,
  rw [hU,hI,rank_bot] at this, 
  have := hX Y hY (λ (e : boolalg.singleton U) (he : (e:U) ⊆ Y), hSing e (subset_trans he hY.1)), 
  have := hX Z hZ (λ (e : boolalg.singleton U) (he : (e:U) ⊆ Z), hSing e (subset_trans he hZ.1)), 
  linarith [M.R0 X], 
  by_cases (size X = 0), rw size_zero_bot h, exact rank_bot M, 
  exact hSing ⟨X, by linarith [int.add_one_le_of_lt (lt_of_le_of_ne (size_nonneg X) (ne.symm h))]⟩ (subset_refl X),    
end 

--set_option pp.proofs true
open minor_expression

-- A larger-rank set can be used to augment a smaller-rank one. 
lemma rank_augment (M : rankfun U) (X Z : U) : (M.r X < M.r Z) → 
  ∃ z: boolalg.singleton U, (z:U) ⊆ Z ∧ M.r X < M.r (X ∪ z) := 
let 
    hcr    : Z-X ⊆ X ∪ Z         := subset_trans (diff_subset Z X) (subset_union_right X Z),
    hr     : X ∪ Z ⊆ ⊤           :=  subset_top (X ∪ Z),  
    hdiff  : (X ∪ Z) - (Z-X) = X := union_diff_diff _ _,
    hunion : (Z-X) ∪ X = X ∪ Z   := by rw [union_comm _ X, union_diff] 
in 
begin
  intros hrXrZ, by_contradiction h, push_neg at h, 
  --pertinent minor M' : restrict to X ∪ Z then corestrict to Z-X
  let M' := to_minor (corestrict (Z - X) hcr (restrict (X ∪ Z) hr self)) M, 
  -- simplified rank function of M' 
  have hrM' : ∀ (J : subalg (Z-X)), M'.r J = M.r (J ∪ X) - M.r (X) := 
    by {intros J, calc _  = M.r (J ∪ ((X ∪ Z) - (Z-X))) - M.r ((X ∪ Z) - (Z-X)) : rfl ... = _ : by rw hdiff}, 

  have hr'top := hrM' ⊤, 
  rw [coe_top (Z-X), hunion] at hr'top, 

  have : M'.r ⊤ ≠ 0 := by linarith [by calc M'.r ⊤ = _ : hr'top ... ≥ M.r Z - M.r X : by linarith [M.R2 Z (X ∪ Z) (subset_union_right X Z)]],

  apply this, apply loopy_rank_zero, intros e he,
  specialize h e (subset_trans ((e: subalg (Z-X)).property) (diff_subset _ _ )), 
  rw coe_singleton_subalg_compose at h, 
  rw [hrM' e, union_comm, coe_subalg_singleton_compose],
  linarith [M.R2 _ _ (subset_union_left X e)],
end

lemma rank_le_top (M : rankfun U)(X : U) : 
  M.r X ≤ M.r ⊤ := 
  M.R2 _ _ (subset_top X)

lemma rank_subadditive (M : rankfun U)(X Y : U) : 
  M.r (X ∪ Y) ≤ M.r X + M.r Y :=
  by linarith [M.R3 X Y, M.R0 (X ∩ Y)]

lemma rank_diff_le_size_diff (M : rankfun U)(X Y : U)(hXY : X ⊆ Y) :
  M.r Y - M.r X ≤ size Y - size X := 
  begin
    have h := (dual M).R2 _ _ (subset_to_compl hXY), 
    rw [dual_r M Xᶜ, dual_r M Yᶜ, compl_compl,compl_compl,compl_size,compl_size] at h, linarith, 
  end 

end rank 

-- Independence 

section indep
variables {U : boolalg}

def is_indep (M : rankfun U) : U → Prop :=
  λ X, M.r X = size X

def is_dep (M : rankfun U) : U → Prop := 
   λ X, ¬(is_indep M X)

lemma indep_iff_r {M : rankfun U} (X : U): 
  is_indep M X ↔ M.r X = size X := 
  by refl 

lemma dep_iff_r {M : rankfun U} (X : U):
  is_dep M X ↔ M.r X < size X := 
  by {unfold is_dep, rw indep_iff_r, exact ⟨λ h, (ne.le_iff_lt h).mp (M.R1 X), λ h, by linarith⟩}

def is_coindep (M : rankfun U) : U → Prop :=
  is_indep (dual M)

def is_codep (M : rankfun U) : U → Prop := 
  is_dep (dual M)

lemma indep_or_dep (M : rankfun U) (X : U): 
  is_indep M X ∨ is_dep M X := 
  by {rw [dep_iff_r, indep_iff_r], exact eq_or_lt_of_le (M.R1 X)}

lemma dep_iff_not_indep {M : rankfun U} (X : U): 
  is_dep M X ↔ ¬is_indep M X := 
  by {rw [indep_iff_r, dep_iff_r], exact ⟨λ h, by linarith, λ h, (ne.le_iff_lt h).mp (M.R1 X)⟩}

lemma indep_iff_not_dep {M : rankfun U} (X : U): 
  is_indep M X ↔ ¬is_dep M X := 
  by {rw dep_iff_not_indep, simp}

lemma coindep_iff_r {M : rankfun U} (X : U) :
  is_indep (dual M) X ↔ (M.r Xᶜ = M.r ⊤) := 
  by {unfold is_coindep is_indep dual, simp only [], split; {intros h, linarith}}

lemma codep_iff_r {M : rankfun U} (X : U) : 
  is_dep (dual M) X ↔ (M.r Xᶜ < M.r ⊤) := 
  by {rw [dep_iff_not_indep, coindep_iff_r], exact ⟨λ h, (ne.le_iff_lt h).mp (rank_le_top M Xᶜ), λ h, by linarith⟩}
    
lemma bot_indep {M : rankfun U} :
  is_indep M ⊥ :=  
  by rw [indep_iff_r, size_bot, rank_bot]

lemma dep_nonbot {M : rankfun U} {X : U} (hdep : is_dep M X ):
  X ≠ ⊥ := 
  λ h, by {have := @bot_indep _ M, rw ←h at this, exact hdep this}

lemma I1 (M : rankfun U) : is_indep M ⊥ := 
  calc M.r (⊥ : U) = 0 : rank_bot M ... = size (⊥ : U) : (@size_bot U).symm

lemma I2 (M : rankfun U) (X Y : U) : is_indep M Y → (X ⊆ Y) → is_indep M X := 
begin
    intros hY hXY,
    have h0 : M.r Y ≤ M.r X + M.r (Y - X) := sorry, 
    have h1 : size X  + size (Y - X) = size Y := sorry, 
    have h2 : M.r (Y-X)  ≤ size (Y-X) := sorry, 
    have h3 : M.r X ≤ size X := sorry,
    have h4 : size Y = M.r Y := sorry, 
    have h5 : size X = M.r X := by linarith, 
    exact h5.symm,   
end

lemma I3 (M : rankfun U) (X Y : U) : is_indep M X → is_indep M Y → size X < size Y → 
  (∃ e : boolalg.singleton U, (e : U) ⊆ Y ∧ ¬((e: U) ⊆ X) ∧ is_indep M (X ∪ e)) := 
begin
  intros hIX,
  set P : U → Prop := λ Z, ((X ∩ Z = ⊥) → (M.r (X ∪ Z) > M.r X) → ∃ z : boolalg.singleton U, (z.val ⊆ Z) ∧ (M.r (X ∪ z.val) > M.r X)) with hP,  
  suffices h : ∀ Z, P Z, 
  sorry, 
  --specialize h (Y-X) (sorry : X ∩ (Y - X) = ⊥), 

  --apply strong_induction, 
  sorry, 
end

lemma I3' (M : rankfun U) (X Y : U) : is_indep M X → is_indep M Y → size X < size Y → 
  (∃ X': U, X ⊆ X' ∧ X' ⊆ X ∪ Y ∧ is_indep M X' ∧ size X' = size X +1 ) := sorry 




end indep 



section /-Circuits-/ circuit
variables {U : boolalg}

def is_circuit (M : rankfun U) : U → Prop := 
  λ X, (is_dep M X ∧  ∀ Y: U, Y ⊂ X → is_indep M Y)

def is_cocircuit (M : rankfun U) : U → Prop := 
  is_circuit (dual M)

lemma circuit_iff_r {M : rankfun U} (X : U) :
  is_circuit M X ↔ (M.r X = size X-1) ∧ (∀ Y:U, Y ⊂ X → M.r Y = size Y) := 
  begin
    unfold is_circuit,
    simp_rw indep_iff_r, 
    split, rintros ⟨hr, hmin⟩,
    split, rcases nonbot_single_removal (dep_nonbot hr) with ⟨Y, ⟨hY₁, hY₂⟩⟩, specialize hmin Y hY₁,
    rw dep_iff_r at hr, linarith [M.R2 _ _ hY₁.1],  
    intros Y hY, exact hmin _ hY, 
    rintros ⟨h₁, h₂⟩, rw dep_iff_r, refine ⟨by linarith, λ Y hY, _ ⟩,  exact h₂ _ hY, 
  end 
  
lemma cocircuit_iff_r {M : rankfun U} (X : U):
  is_cocircuit M X ↔ (M.r Xᶜ = M.r ⊤ - 1) ∧ (∀ Y: U, Y ⊂ X → M.r Yᶜ = M.r ⊤) := 
  by 
  {
    unfold is_cocircuit is_circuit, simp_rw [codep_iff_r, coindep_iff_r],
    split, rintros ⟨h₁, h₂⟩, split, 
    have h_nonbot : X ≠ ⊥ := by {intros h, rw [h,boolalg.compl_bot] at h₁, exact int.lt_irrefl _ h₁}, 
    rcases (nonbot_single_removal h_nonbot) with ⟨Y,⟨hY₁, hY₂⟩⟩ ,
    specialize h₂ _ hY₁,  
    rw [←compl_compl Y, ←compl_compl X, compl_size, compl_size Xᶜ] at hY₂, 
    linarith[rank_diff_le_size_diff M _ _ (subset_to_compl hY₁.1)], 
    exact h₂, rintros ⟨h₁, h₂⟩, exact ⟨by linarith, h₂⟩, 
  }

end circuit 

section /-Flats-/ flat
variables {U : boolalg} 

def is_flat (M : rankfun U) : U → Prop := 
  λ F, ∀ (X : U), F ⊂ X → M.r F < M.r X

def is_hyperplane (M : rankfun U) : U → Prop := 
  λ H, (is_flat M H) ∧ M.r H = M.r ⊤ - 1

def is_rank_k_flat (M : rankfun U) (k : ℤ) : U → Prop := 
  λ F, is_flat M F ∧ M.r F = 1 

def is_loops (M : rankfun U) : U → Prop := 
  λ F, is_rank_k_flat M 0 F

def is_point (M : rankfun U) : U → Prop := 
  λ F, is_rank_k_flat M 1 F

def is_line (M : rankfun U) : U → Prop := 
  λ F, is_rank_k_flat M 2 F

def is_plane (M : rankfun U) : U → Prop := 
  λ F, is_rank_k_flat M 3 F

@[simp] def is_spanning (M : rankfun U) : U → Prop := 
  λ X, M.r X = M.r ⊤ 

@[simp] def is_nonspanning (M : rankfun U) : U → Prop := 
  λ X, M.r X < M.r ⊤ 


lemma flat_iff_r {M : rankfun U} (X : U) :
  is_flat M X ↔ ∀ Y, X ⊂ Y → M.r X < M.r Y := 
  by refl 

lemma hyperplane_iff_r {M : rankfun U} (X : U) :
  is_hyperplane M X ↔ M.r X = M.r ⊤ -1 ∧ ∀ Y, X ⊂ Y → M.r Y = M.r ⊤ := 
  begin
    unfold is_hyperplane, rw flat_iff_r, 
    refine ⟨λ h, ⟨h.2, λ Y hXY, _ ⟩, λ h, ⟨λ Y hXY, _, h.1⟩ ⟩,
    have := h.1 Y hXY, rw h.2 at this, linarith [rank_le_top M Y],  
    rw [h.1,h.2 Y hXY], exact sub_one_lt _,   
  end

lemma spanning_or_nonspanning (M : rankfun U) (X : U) :
  is_spanning M X ∨ is_nonspanning M X := 
  by { sorry }

lemma hyperplane_iff_maximal_nonspanning {M : rankfun U} (X : U): 
  is_hyperplane M X ↔ is_nonspanning M X ∧ ∀ (Y: U), X ⊂ Y → is_spanning M Y :=
  begin
    split, 
    intro h, simp, split, linarith [h.2],
    intros Y hXY, linarith [h.1 Y hXY, h.2, rank_le_top M Y],
    rintros ⟨h1,h2⟩, simp at h1 h2, split, 
    intros Z hZ, specialize h2 Z hZ, linarith [rank_le_top M Z], 
    by_cases X = ⊤, rw h at h1, linarith, 
    rcases nonbot_contains_singleton Xᶜ ((λ hX, h (top_of_compl_bot hX)) : Xᶜ ≠ ⊥) with ⟨e, he⟩,
    specialize h2 (X ∪ e) (augment_singleton_ssubset _ _ he), 
    linarith [rank_subadditive M X e, M.R1 e, (by {cases e, assumption} : size (e:U) = 1)],
  end 

lemma cocircuit_iff_compl_hyperplane {M : rankfun U} (X : U): 
  is_cocircuit M X ↔ is_hyperplane M Xᶜ := 
  begin
    rw [cocircuit_iff_r, hyperplane_iff_r], 
    refine ⟨λ h, ⟨h.1,λ Y hXY, _⟩ , λ h, ⟨h.1,λ Y hXY, h.2 _ (ssubset_to_compl hXY)⟩⟩, 
    rw [←(h.2 _ (ssubset_compl_left hXY)), compl_compl], 
  end


end flat

section /- Series and Parallel -/ series_parallel 

variables {U : boolalg}
notation `single` := boolalg.singleton 

def is_loop (M : rankfun U) : single U → Prop := 
  λ e, M.r e = 0 

def is_nonloop (M : rankfun U) : single U → Prop := 
  λ e, M.r e = 1 

def is_coloop (M : rankfun U) : single U → Prop := 
  λ e, is_loop (dual M) e  

def is_noncoloop (M : rankfun U) : single U → Prop := 
  λ e, is_coloop (dual M) e

lemma nonloop_iff_not_loop {M : rankfun U} (e : single U) : 
  is_nonloop M e ↔ ¬ is_loop M e := 
  begin 
    unfold is_loop is_nonloop, refine ⟨λ h, _ ,λ h, _⟩,rw h ,
    simp only [not_false_iff, one_ne_zero], 
    have := M.R1 e, rw size_coe_singleton at this,       
    linarith [(ne.le_iff_lt (ne.symm h)).mp (M.R0 e)],  
  end

lemma coloop_iff_r {M : rankfun U} (e : single U) :
  is_coloop M e ↔ M.r eᶜ = M.r ⊤ - 1 := 
  begin
    unfold is_coloop is_loop, rw [dual_r,size_coe_singleton],
    exact ⟨λh,by linarith,λ h, by linarith⟩,   
  end

lemma coloop_iff_r_less {M : rankfun U} (e : single U) :
  is_coloop M e ↔ M.r eᶜ < M.r ⊤ := 
  begin
    unfold is_coloop is_loop, rw [dual_r,size_coe_singleton],
    refine ⟨λh,by linarith,λ h,_⟩, 
    sorry -- this is a bit annoying, and it's almost midnight. 
  end



def nonloop (M : rankfun U) : Type := { e : single U // is_nonloop M e}
def noncoloop (M : rankfun U) : Type := { e : single U // is_noncoloop M e}

def parallel (M : rankfun U) : single U → single U → Prop := 
  λ e f, (is_nonloop M e ∧ is_nonloop M f) ∧ M.r (e ∪ f) = 1 

def series (M : rankfun U) : single U → single U → Prop := 
  λ e f, parallel (dual M) e f 


-- parallel pairs (and series pairs) are equivalence relations, but only on the set of non(co)loops
-- of the matroid. I don't know if it's worth defining new types for these objects with the appropriate
-- coercions, or not. 


end series_parallel