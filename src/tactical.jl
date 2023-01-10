include("insertnode.jl")
include("localsearch.jl")

# Tactical decision-making (actual)
function optact(rng::AbstractRNG, env::Dict, initsol::LRP.Solution)
    s  = initsol
    n  = 200
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
    display(pltcnv(S; penalty=false))
    s = deepcopy(S[end])
    return s
end

# Tactical decision-making (counterfactual)
function optcft(rng::AbstractRNG, env::Dict, initsol::LRP.Solution)
    s′ = initsol
    D′ = s′.D
    C′ = s′.C
    G  = build(path; root=dir)
    D, C, _ = G
    for iⁿ ∈ eachindex(D′) D[iⁿ] = D′[iⁿ] end
    for iⁿ ∈ eachindex(C′) C[iⁿ] = C′[iⁿ] end
    s  = LRP.Solution(G...) 
    insertnode!(rng, s)
    localsearch!(rng, 5000, s)
    n  = 200
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
    display(pltcnv(S; penalty=false))
    s = deepcopy(S[end])
    return s
end