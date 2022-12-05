# Strategic decision-making
function optstr(rng::AbstractRNG, instance::String)
    # Step 1. Visualize instance
    instance = "$instance/#1. strategic"
    dir      = "G:/My Drive/Academia/Research/Projects/2022. Last-Mile Logistics/Analysis/instances"
    display(visualize(instance; root=dir))

    # Step 2. Build strategic solution
    G  = build(instance; root=dir)
    s  = initialsolution(rng, G, :cluster)

    n  = 100
    χ  = ALNSParameters(
        n    =   n ÷ 25                  ,
        k    =   250                     ,
        m    =   2n                      ,
        j    =   125                     ,
        Ψᵣ   =   [
                    :randomnode!    ,
                    :randomroute!   ,
                    :randomvehicle! ,
                    :randomdepot!   ,
                    :relatednode!   ,
                    :relatedroute!  ,
                    :relatedvehicle!,
                    :relateddepot!  ,
                    :worstnode!     ,
                    :worstroute!    ,
                    :worstvehicle!  ,
                    :worstdepot!
                ]                        ,
        Ψᵢ   =  [
                    :bestprecise!   ,
                    :bestperturb!   ,
                    :greedyprecise! ,
                    :greedyperturb! ,
                    :regret2!       ,
                    :regret3!
                ]                        ,
        Ψₗ  =   [
                    :intraopt!       ,
                    :interopt!       ,
                    :movecustomer!   ,
                    :movedepot!      ,
                    :swapcustomers!  ,
                    :swapdepots!
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