using LRP

using CSV
using JLD
using Random
using Revise
using StatsBase
using DataFrames
using OffsetArrays
using ProgressMeter
using Distributions
using ElasticArrays

include("strategic.jl");
include("tactical.jl");
include("operational.jl");
include("geninstance.jl");

isopt = LRP.isopt;

let
##
    df = DataFrame(
            day               = Int64[]  , 
            decision          = String[] , 
            customers         = Int64[]  ,
            fulfillmentTripE1 = Float64[], 
            fulfillmentTripE2 = Float64[], 
            deliveryTourE1    = Float64[], 
            deliveryTourE2    = Float64[],
            fixed             = Float64[],
            operational       = Float64[],
            feasible          = Bool[]
        )                          
##;


##
    instance      = "LosAngeles/#3. MH"
    horizon       = 30          
    share         = 0.007695    
    consolidation = 3           
    dynamism      = 0.2
    x₀            = 60.0
    y₀            = 26.0
##;


##  Step 1. Strategic decision-making 
    println("STRATEGIC DECISION-MAKING")
    strategic = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0, 0) 
    solution = "instances/$instance/#1. strategic/solution.jld"
    try strategic = load(solution)["s"]
    catch
        rng = MersenneTwister(horizon)
        genstr(instance, share)
        strategic = optstr(rng, instance)
        save(solution, "s", strategic)
    end
    s = deepcopy(strategic)
    display(visualize(s))
    k   = 0
    ft₁ = 0.
    ft₂ = 0.
    dt₁ = 0.
    dt₂ = 0.
    for d ∈ s.D
        if !isopt(d) continue end
        if !isone(d.jⁿ) continue end
        k  = d.iⁿ
        x₁ = d.x
        y₁ = d.y
        ft₁ += abs(x₁-x₀) + abs(y₁-y₀)
        for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
    end
    for d ∈ s.D
        if !isopt(d) continue end
        if isone(d.jⁿ) continue end
        d₁ = s.D[k]
        x₁ = d₁.x
        y₁ = d₁.y
        x₂ = d.x
        y₂ = d.y
        ft₂ += abs(x₂-x₁) + abs(y₂-y₁)
        for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
    end
    push!(df, (0, "str", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))
##;


##  Simulate daily operations
    for day ∈ 1:horizon
        println("\nday $day")

        # Step 2.1. Tactical decision-making (counterfactual)
        println("TACTICAL DECISION-MAKING - COUNTERFACTUAL")
        version  = "counterfactual" 
        tactical = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0, 0) 
        solution = "instances/$instance/#2. tactical - $version/day $day/solution.jld"
        try tactical = load(solution)["s"] 
        catch
            rng = MersenneTwister(day)
            gentac(rng, instance, version, share, consolidation, dynamism, day, strategic)
            tactical = opttac(rng, instance, version, day)
            save(solution, "s", tactical)
        end
        s = deepcopy(tactical)
        display(visualize(s))
        k   = 0
        ft₁ = 0.
        ft₂ = 0.
        dt₁ = 0.
        dt₂ = 0.
        for d ∈ s.D
            if !isopt(d) continue end
            if !isone(d.jⁿ) continue end
            k  = d.iⁿ
            x₁ = d.x
            y₁ = d.y
            ft₁ += abs(x₁-x₀) + abs(y₁-y₀)
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        for d ∈ s.D
            if !isopt(d) continue end
            if isone(d.jⁿ) continue end
            d₁ = s.D[k]
            x₁ = d₁.x
            y₁ = d₁.y
            x₂ = d.x
            y₂ = d.y
            ft₂ += abs(x₂-x₁) + abs(y₂-y₁)
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
        push!(df, (day, "tac-cft", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))

        # Step 2.2. Tactical decision-making (actual)
        println("TACTICAL DECISION-MAKING - ACTUAL")
        version  = "actual" 
        tactical = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0, 0) 
        solution = "instances/$instance/#2. tactical - $version/day $day/solution.jld"
        try tactical = load(solution)["s"] 
        catch
            rng = MersenneTwister(day)
            gentac(rng, instance, version, share, consolidation, dynamism, day, strategic)
            tactical = opttac(rng, instance, version, day)
            save(solution, "s", tactical)
        end
        s = deepcopy(tactical)
        display(visualize(s))
        k   = 0
        ft₁ = 0.
        ft₂ = 0.
        dt₁ = 0.
        dt₂ = 0.
        for d ∈ s.D
            if !isopt(d) continue end
            if !isone(d.jⁿ) continue end
            k  = d.iⁿ
            x₁ = d.x
            y₁ = d.y
            ft₁ += abs(x₁-x₀) + abs(y₁-y₀)
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        for d ∈ s.D
            if !isopt(d) continue end
            if isone(d.jⁿ) continue end
            d₁ = s.D[k]
            x₁ = d₁.x
            y₁ = d₁.y
            x₂ = d.x
            y₂ = d.y
            ft₂ += abs(x₂-x₁) + abs(y₂-y₁)
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
        push!(df, (day, "tac-act", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))
        
        # Step 2.3. Operational decision-making
        println("OPERATIONAL DECISION-MAKING")
        operational = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0, 0) 
        solution = "instances/$instance/#3. operational/day $day/solution.jld"
        try operational = load(solution)["s"] 
        catch
            rng = MersenneTwister(day)
            genopt(rng, instance, share, consolidation, dynamism, day, strategic)
            operational = optopr(rng, instance, day, tactical)
            save(solution, "s", operational)
        end
        s = deepcopy(operational)
        display(visualize(s))
        k   = 0
        ft₁ = 0.
        ft₂ = 0.
        dt₁ = 0.
        dt₂ = 0.
        for d ∈ s.D
            if !isopt(d) continue end
            if !isone(d.jⁿ) continue end
            k  = d.iⁿ
            x₁ = d.x
            y₁ = d.y
            ft₁ += abs(x₁-x₀) + abs(y₁-y₀)
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        for d ∈ s.D
            if !isopt(d) continue end
            if isone(d.jⁿ) continue end
            d₁ = s.D[k]
            x₁ = d₁.x
            y₁ = d₁.y
            x₂ = d.x
            y₂ = d.y
            ft₂ += abs(x₂-x₁) + abs(y₂-y₁)
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
        push!(df, (day, "opt", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))  
    end
##;
##
    CSV.write("instances/$instance/analysis.csv", df)
##;
end