# Generate instance for strategic decision-making
function genstr(rng::AbstractRNG, env::Dict, path::String)
    mkpath(path)

    p = env["share"]
    
    strategy = env["strategy"]

    # Depot Nodes
    CSV.write("$path/depot_nodes.csv", DataFrame(CSV.File("instances/$strategy/depot nodes.csv")))
    
    # Customer Nodes
    df₁ = DataFrame(CSV.File("instances/$strategy/depot nodes.csv"))
    df₂ = DataFrame(CSV.File("instances/$strategy/census tracts.csv"))
    CSV.write("$path/customer_nodes.csv", DataFrame(in = (1+nrow(df₁)):(nrow(df₁)+nrow(df₂)), x = df₂[:,2], y = df₂[:,3], q = df₂[:,4] * p, te = df₂[:,5], tl = df₂[:,6]))

    # Vehicles
    CSV.write("$path/vehicles.csv", DataFrame(CSV.File("instances/$strategy/vehicles.csv")))    

    return
end

# Generate instance for tactical decision-making (actual)
function genact(rng::AbstractRNG, env::Dict, path::String)
    mkpath(path)

    p = env["share"]
    θ = env["consolidation"]
    δ = env["dynamism"]
    s = env["structure"]

    strategy = env["strategy"]

    # Depot Nodes
    iᵈ = 0
    Dˢ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Float64[], pl = Float64[], pu = Float64[], ts = Float64[], te = Float64[], co = Float64[], cf = Float64[], phi = Int64[])
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        push!(Dˢ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ, 1))
    end
    CSV.write("$path/depot_nodes.csv", Dˢ)
 
    # Customer Nodes
    Cˢ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[])
    df = DataFrame(CSV.File("instances/$strategy/customer nodes.csv"))
    tˢ = Inf
    tᵉ = 0.
    for d ∈ s.D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ s.D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end    
    n  = nrow(df)
    Δn = sum(LRP.isopt.(s.D))
    nᶜ = 0
    nˢ = 0
    nᵈ = 0
    δʰ = δ
    Z  = Dict(df[r,7] => Int64[] for r ∈ 1:n)
    for r ∈ 1:n push!(Z[df[r,7]], df[r,1]) end
    for iᵗ ∈ keys(Z)
        zᶜ = Int64(round(length(Z[iᵗ]) * rand(rng, Uniform(0.8p, 1.2p)) / θ))
        zˢ = Int64(round((1 - δʰ) * zᶜ))
        zᵈ = zᶜ - zˢ
        Iᶜ = sample(rng, Z[iᵗ], zᶜ, replace=false)
        Iˢ = sample(rng, Iᶜ, zˢ, replace=false)
        Iᵈ = filter(x -> x ∉ Iˢ, Iᶜ)
        for iˢ ∈ Iˢ push!(Cˢ, (df[iˢ,1], df[iˢ,2], df[iˢ,3], θ, df[iˢ,5], df[iˢ,6])) end
        for iᵈ ∈ Iᵈ rand(rng, Uniform(tˢ, tˢ + (tᵉ - tˢ)/2)) end
        nᶜ += zᶜ
        nˢ += zˢ
        nᵈ += zᵈ
        δʰ  = min(1.0, max(0.0, (δ * p / θ * n - nᵈ)/(n * p / θ - nᶜ)))
    end
    for n ∈ 1:nˢ Cˢ[n,1] = n + Δn end
    CSV.write("$path/customer_nodes.csv", Cˢ)

    # Vehicles
    Vˢ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Float64[], l = Float64[], s = Float64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Float64[], r = Int64[], cd = Float64[], ct = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        for v ∈ d.V push!(Vˢ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵈ, v.πᵗ, v.πᶠ)) end
    end
    CSV.write("$path/vehicles.csv", Vˢ)

    return
end

# Generate instance for tactical decision-making (counterfactual)
function gencft(rng::AbstractRNG, env::Dict, path::String)
    mkpath(path)

    p = env["share"]
    θ = env["consolidation"]
    δ = env["dynamism"]
    s = env["structure"]

    strategy = env["strategy"]

    # Depot Nodes
    iᵈ = 0
    Dˢ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Float64[], pl = Float64[], pu = Float64[], ts = Float64[], te = Float64[], co = Float64[], cf = Float64[], phi = Int64[])
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        push!(Dˢ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ, 1))
    end
    CSV.write("$path/depot_nodes.csv", Dˢ)
 
    # Customer Nodes
    Cˢ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[])
    Cᵈ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[], tr = Float64[])
    df = DataFrame(CSV.File("instances/$strategy/customer nodes.csv"))
    tˢ = Inf
    tᵉ = 0.
    for d ∈ s.D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ s.D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end    
    n  = nrow(df)
    Δn = sum(LRP.isopt.(s.D))
    nᶜ = 0
    nˢ = 0
    nᵈ = 0
    δʰ = δ
    Z  = Dict(df[r,7] => Int64[] for r ∈ 1:n)
    for r ∈ 1:n push!(Z[df[r,7]], df[r,1]) end
    for iᵗ ∈ keys(Z)
        zᶜ = Int64(round(length(Z[iᵗ]) * rand(rng, Uniform(0.8p, 1.2p)) / θ))
        zˢ = Int64(round((1 - δʰ) * zᶜ))
        zᵈ = zᶜ - zˢ
        Iᶜ = sample(rng, Z[iᵗ], zᶜ, replace=false)
        Iˢ = sample(rng, Iᶜ, zˢ, replace=false)
        Iᵈ = filter(x -> x ∉ Iˢ, Iᶜ)
        for iˢ ∈ Iˢ push!(Cˢ, (df[iˢ,1], df[iˢ,2], df[iˢ,3], θ, df[iˢ,5], df[iˢ,6])) end
        for iᵈ ∈ Iᵈ push!(Cᵈ, (df[iᵈ,1], df[iᵈ,2], df[iᵈ,3], θ, df[iᵈ,5], df[iᵈ,6], rand(rng, Uniform(tˢ, tˢ + (tᵉ - tˢ)/2)))) end
        nᶜ += zᶜ
        nˢ += zˢ
        nᵈ += zᵈ
        δʰ  = min(1.0, max(0.0, (δ * p / θ * n - nᵈ)/(n * p / θ - nᶜ)))
    end
    Cᵈ = Cᵈ[sortperm(Cᵈ[:,:tr]), :]
    for n ∈ 1:nˢ Cˢ[n,1] = n + Δn end
    for n ∈ 1:nᵈ Cᵈ[n,1] = n + nˢ + Δn end
    for n ∈ 1:nᵈ push!(Cˢ, Cᵈ[n, 1:(end-1)]) end
    CSV.write("$path/customer_nodes.csv", Cˢ)

    # Vehicles
    Vˢ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Float64[], l = Float64[], s = Float64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Float64[], r = Int64[], cd = Float64[], ct = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        for v ∈ d.V push!(Vˢ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵈ, v.πᵗ, v.πᶠ)) end
    end
    CSV.write("$path/vehicles.csv", Vˢ)

    return
end

# Generate instance for operational decision-making
function genopt(rng::AbstractRNG, env::Dict, path::String)
    mkpath(path)

    p = env["share"]
    θ = env["consolidation"]
    δ = env["dynamism"]
    s = env["structure"]

    strategy = env["strategy"]
    
    # Depot Nodes
    iᵈ = 0
    Dᵈ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Int64[], pl = Float64[], pu = Float64[], ts = Int64[], te = Int64[], co = Float64[], cf = Float64[], phi = Int64[])
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        push!(Dᵈ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ, 1))
    end
    CSV.write("$path/depot_nodes.csv", Dᵈ)
    
    # Customer Nodes
    Cᵈ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[], tr = Float64[])
    df = DataFrame(CSV.File("instances/$strategy/customer nodes.csv"))
    tˢ = Inf
    tᵉ = 0.
    for d ∈ s.D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ s.D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end
    n  = nrow(df)
    Δn = sum(LRP.isopt.(s.D))
    nᶜ = 0
    nˢ = 0
    nᵈ = 0
    δʰ = δ
    Z  = Dict(df[r,7] => Int64[] for r ∈ 1:n)
    for r ∈ 1:n push!(Z[df[r,7]], df[r,1]) end
    for iᵗ ∈ keys(Z)
        zᶜ = Int64(round(length(Z[iᵗ]) * rand(rng, Uniform(0.8p, 1.2p)) / θ))
        zˢ = Int64(round((1 - δʰ) * zᶜ))
        zᵈ = zᶜ - zˢ
        Iᶜ = sample(rng, Z[iᵗ], zᶜ, replace=false)
        Iˢ = sample(rng, Iᶜ, zˢ, replace=false)
        Iᵈ = filter(x -> x ∉ Iˢ, Iᶜ)
        for iᵈ ∈ Iᵈ push!(Cᵈ, (df[iᵈ,1], df[iᵈ,2], df[iᵈ,3], θ, df[iᵈ,5], df[iᵈ,6], rand(rng, Uniform(tˢ, tˢ + (tᵉ - tˢ)/2)))) end
        nᶜ += zᶜ
        nˢ += zˢ
        nᵈ += zᵈ
        δʰ  = min(1.0, max(0.0, (δ * p / θ * n - nᵈ)/(n * p / θ - nᶜ)))
    end
    Cᵈ = Cᵈ[sortperm(Cᵈ[:,:tr]), :]
    for n ∈ 1:nᵈ Cᵈ[n,1] = n + nˢ + Δn end
    CSV.write("$path/customer_nodes.csv", Cᵈ)
    
    # Vehicles
    Vᵈ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Float64[], l = Float64[], s = Float64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Float64[], r = Int64[], cd = Float64[], ct = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        for v ∈ d.V push!(Vᵈ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵈ, v.πᵗ, v.πᶠ)) end
    end
    CSV.write("$path/vehicles.csv", Vᵈ)
    
    return
end