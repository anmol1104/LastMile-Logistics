# Tactical decision-making
function opttac(rng::AbstractRNG, instance::String, day::Int64)
    # Step 1. Visualize instance
    instance = "$instance/#2. tactical/day $day"
    dir      = "G:/My Drive/Academia/Research related/Projects/2022. Dissertation/Analysis/instances"
    display(visualize(instance; root=dir))
    
    # Step 2. Build operational solution
    G  = build(instance; root=dir)
    s  = initialsolution(rng, G, :cluster)
    n  = 50
    χ  = ALNSParameters(
        k̲    =   n ÷ 25                  ,
        l̲    =   2n                      ,
        l̅    =   5n                      ,
        k̅    =   10n                     ,
        Ψᵣ   =   [
                    :randomnode!    ,
                    :randomroute!   ,
                    :relatednode!   ,
                    :relatedroute!  ,
                    :worstnode!     ,
                    :worstroute!    ,
                ]                        ,
        Ψᵢ   =  [
                    :bestprecise!   ,
                    :bestperturb!   ,
                    :greedyprecise! ,
                    :greedyperturb! ,
                    :regret2!       ,
                    :regret3!
                ]                           ,
        Ψₗ   =  [
                    :move!          ,
                    :opt!           ,
                    :split!         ,
                    :swapcustomers! ,
                ]                        ,
        σ₁   =   15                      ,
        σ₂   =   10                      ,
        σ₃   =   3                       ,
        ω    =   0.05                    ,
        τ    =   0.5                     ,
        𝜃    =   0.9975                  ,
        C̲    =   4                       ,
        C̅    =   60                      ,
        μ̲    =   0.1                     ,
        μ̅    =   0.4                     ,
        ρ    =   0.1
    )
    S = ALNS(rng, χ, s)
    s = deepcopy(S[end])

    # Step 3. Return solution
    return s
end