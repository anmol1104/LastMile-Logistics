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

let

##
    dir           = "G:/My Drive/Academia/Research/Projects/2022. Last-Mile Logistics/Analysis/instances"
    strategy      = "LosAngeles/#5. DDMHCP"
    horizon       = 30
    share         = 0.01
    consolidation = 3
    dynamism      = 0.2
    x₀            = 50.0
    y₀            = 0.00
    day           = 0
    structure     = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0)

    env = Dict()
    env["dir"]           = dir
    env["strategy"]      = strategy
    env["horizon"]       = horizon
    env["share"]         = share
    env["consolidation"] = consolidation
    env["dynamism"]      = dynamism
    env["x₀"]            = x₀
    env["y₀"]            = y₀
    env["day"]           = day
    env["structure"]     = structure

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


##  Step 1. Strategic decision-making 
    println("STRATEGIC DECISION-MAKING")
    path          = joinpath(dir, "$strategy/#1. strategic")
    strategic     = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0) 
    try strategic = load("$path/solution.jld")["s"]
    catch
        rng       = MersenneTwister(horizon)
        genstr(rng, env, path)
        initsol   = initialsolution(rng, build(path; root=dir), :cluster)
        strategic = optstr(rng, env, initsol)
        save("$path/solution.jld", "s", strategic)
    end
    s = deepcopy(strategic)
    display(visualize(s))
    k   = 0
    ft₁ = 0.
    ft₂ = 0.
    dt₁ = 0.
    dt₂ = 0.
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        if !isone(d.jⁿ) continue end
        k  = d.iⁿ
        x₁ = d.x
        y₁ = d.y
        ft₁ += 2(abs(x₁-x₀) + abs(y₁-y₀))
        for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
    end
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        if isone(d.jⁿ) continue end
        d₁ = s.D[k]
        x₁ = d₁.x
        y₁ = d₁.y
        x₂ = d.x
        y₂ = d.y
        ft₂ += 2(abs(x₂-x₁) + abs(y₂-y₁))
        for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
    end
    push!(df, (0, "str", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))
    env["structure"] = deepcopy(strategic)
##;


##  Step 2. Simulate daily operations
    for day ∈ 1:horizon
        println("\nday $day")
        env["day"] = day

        # Step 2.1. Tactical decision-making (actual)
        println("TACTICAL DECISION-MAKING - ACTUAL")
        path        = joinpath(dir, "$strategy/#2. tactical - actual/day $day")
        tacact      = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0)         
        try tacact  = load("$path/solution.jld")["s"] 
        catch
            rng     = MersenneTwister(day)
            genact(rng, env, path)
            initsol = initialsolution(rng, build(path; root=dir), :cluster)
            tacact  = optact(rng, env, initsol)
            save("$path/solution.jld", "s", tacact)
        end
        display(visualize(tacact))
        s   = deepcopy(tacact)
        k   = 0
        ft₁ = 0.
        ft₂ = 0.
        dt₁ = 0.
        dt₂ = 0.
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            if !isone(d.jⁿ) continue end
            k   = d.iⁿ
            x₁  = d.x
            y₁  = d.y
            ft₁+= 2(abs(x₁-x₀) + abs(y₁-y₀))
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            if isone(d.jⁿ) continue end
            d₁  = s.D[k]
            x₁  = d₁.x
            y₁  = d₁.y
            x₂  = d.x
            y₂  = d.y
            ft₂+= 2(abs(x₂-x₁) + abs(y₂-y₁))
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
        push!(df, (day, "tac-act", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))

        # Step 2.2. Tactical decision-making (counterfactual)
        println("TACTICAL DECISION-MAKING - COUNTERFACTUAL")
        path        = joinpath(dir, "$strategy/#2. tactical - counterfactual/day $day")
        taccft      = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0) 
        try taccft  = load("$path/solution.jld")["s"] 
        catch
            rng     = MersenneTwister(day)
            gencft(rng, env, path)
            initsol = deepcopy(tacact)
            taccft  = optcft(rng, env, initsol)
            save("$path/solution.jld", "s", taccft)
        end
        display(visualize(taccft))
        s   = deepcopy(taccft)
        k   = 0
        ft₁ = 0.
        ft₂ = 0.
        dt₁ = 0.
        dt₂ = 0.
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            if !isone(d.jⁿ) continue end
            k  = d.iⁿ
            x₁ = d.x
            y₁ = d.y
            ft₁+= 2(abs(x₁-x₀) + abs(y₁-y₀))
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            if isone(d.jⁿ) continue end
            d₁  = s.D[k]
            x₁  = d₁.x
            y₁  = d₁.y
            x₂  = d.x
            y₂  = d.y
            ft₂+= 2(abs(x₂-x₁) + abs(y₂-y₁))
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
        push!(df, (day, "tac-cft", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))
        
        # Step 2.3. Operational decision-making
        println("OPERATIONAL DECISION-MAKING")
        path        = joinpath(dir, "$strategy/#3. operational/day $day")
        operational = LRP.Solution(LRP.DepotNode[], LRP.CustomerNode[], Dict{Tuple{Int64, Int64}, LRP.Arc}(), 0) 
        try operational = load("$path/solution.jld")["s"] 
        catch
            rng         = MersenneTwister(day)
            genopt(rng, env, path)
            initsol     = deepcopy(tacact)
            operational = optopr(rng, env, initsol)
            save("$path/solution.jld", "s", operational)
        end
        display(visualize(operational))
        s   = deepcopy(operational)
        k   = 0
        ft₁ = 0.
        ft₂ = 0.
        dt₁ = 0.
        dt₂ = 0.
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            if !isone(d.jⁿ) continue end
            k  = d.iⁿ
            x₁ = d.x
            y₁ = d.y
            ft₁ += 2(abs(x₁-x₀) + abs(y₁-y₀))
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            if isone(d.jⁿ) continue end
            d₁ = s.D[k]
            x₁ = d₁.x
            y₁ = d₁.y
            x₂ = d.x
            y₂ = d.y
            ft₂ += 2(abs(x₂-x₁) + abs(y₂-y₁))
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
        push!(df, (day, "opt", length(s.C), ft₁, ft₂, dt₁, dt₂, f(s; fixed=true, operational=false, penalty=false), f(s; fixed=false, operational=true, penalty=false), isfeasible(s)))  
        println(df[(end-2:end), :])
    end
##;

CSV.write("instances/$strategy/analysis.csv", df)

end