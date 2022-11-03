using LRP

using CSV
using JLD
using Random
using Revise
using StatsBase
using DataFrames
using OffsetArrays
using Distributions
using ElasticArrays

include("strategic.jl");
include("tactical.jl");
include("operational.jl");
include("geninstance.jl");

let
##
    instance      = "sf";
    horizon       = 30  ;
    share         = 0.05;
    consolidation = 3   ;
    dynamism      = 0.2 ;
##
##  Strategic decision-making 
    println("STRATEGIC DECISION-MAKING")
    rng = MersenneTwister(horizon)
    strategic = optstr(rng, instance)
    s = deepcopy(strategic)
    println("Distribution structure")
    println("   First echelon")
    i = 0
    for d ∈ s.D
        if isequal(d.jⁿ, 2) continue end
        if !LRP.isopt(d) continue end
        i += 1
        println("       Depot #$i")
        println("           Location    : ($(d.x), $(d.y))")
        println("           Fleet-size  : $(sum((LRP.isopt).(d.V)))")
    end
    println("   Second echelon")
    i = 0
    for d ∈ s.D
        if isequal(d.jⁿ, 1) continue end
        if !LRP.isopt(d) continue end
        i += 1
        println("       Hub #$i")
        println("           Location    : ($(d.x), $(d.y))")
        println("           Fleet-size  : $(sum((LRP.isopt).(d.V)))")
    end
    save("instances/$instance/#1. strategic/solution.jld", "s", s)
    display(visualize(s))

##
##  Simulate daily operations
    for day ∈ 1:horizon
        println("\nday $day")
        # Step 2.1. Develop instance files for tactical and operational decision-making
        rng = MersenneTwister(day)
        geninstance(rng, instance, share, consolidation, dynamism, day, strategic)

        # Step 2.2. Tactical decision-making
        println("TACTICAL DECISION-MAKING")
        rng = MersenneTwister(day)
        tactical = opttac(rng, instance, day)
        s  = deepcopy(tactical)
        πᶠ = f(s; operational=false, penalty=false)/length(s.C)
        πᵒ = f(s; fixed=false, penalty=false)/length(s.C)
        πᵗ = f(s; penalty=false)/length(s.C)
        println("Distribution cost per package")
        println("   Fixed       : $(round(πᶠ, digits=3))")
        println("   Operational : $(round(πᵒ, digits=3))")
        println("   Total       : $(round(πᵗ, digits=3))")
        save("instances/$instance/#2. tactical/day $day/solution.jld", "s", s)
        display(visualize(s))

        # Step 2.3. Operational decision-making
        println("OPERATIONAL DECISION-MAKING")
        rng = MersenneTwister(day)
        operational = optopr(rng, instance, day, tactical)
        s  = deepcopy(operational)
        Δπᶠ = f(s; operational=false, penalty=false)/length(s.C) - πᶠ
        Δπᵒ = f(s; fixed=false, penalty=false)/length(s.C) - πᵒ
        Δπᵗ = f(s; penalty=false)/length(s.C) - πᵗ
        println("Additional distribution costs due to dynamic arrival of customers")
        println("   Fixed       : $(round(Δπᶠ, digits=3))")
        println("   Operational : $(round(Δπᵒ, digits=3))")
        println("   Total       : $(round(Δπᵗ, digits=3))")
        save("instances/$instance/#3. operational/day $day/solution.jld", "s", s)
        display(visualize(s))
    end
##
end