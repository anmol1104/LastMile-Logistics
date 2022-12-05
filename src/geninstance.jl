# Generate instance for strategic decision-making
function genstr(instance::String, share::Float64)
    mkpath("instances/$instance/#1. strategic")

    # Depot Nodes
    CSV.write("instances/$instance/#1. strategic/depot_nodes.csv", DataFrame(CSV.File("instances/$instance/depot nodes.csv")))
    
    # Customer Nodes
    df₁ = DataFrame(CSV.File("instances/$instance/depot nodes.csv"))
    df₂ = DataFrame(CSV.File("instances/$instance/census tracts.csv"))
    CSV.write("instances/$instance/#1. strategic/customer_nodes.csv", DataFrame(in = (1+nrow(df₁)):(nrow(df₁)+nrow(df₂)), x = df₂[:,4], y = df₂[:,5], q = df₂[:,8] * share, te = df₂[:,6], tl = df₂[:,7]))
    
    # Arcs
    df₁ = DataFrame(CSV.File("instances/$instance/#1. strategic/depot_nodes.csv"))
    df₂ = DataFrame(CSV.File("instances/$instance/#1. strategic/customer_nodes.csv"))
    A   = DataFrame(t = Int64[], h = Int64[], l = Float64[], φ = Float64[])
    for i ∈ 1:nrow(df₁)
        iⁿ = df₁[i,1]
        x₁ = df₁[i,3]
        y₁ = df₁[i,4] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    for i ∈ 1:nrow(df₂)
        iⁿ = df₂[i,1]
        x₁ = df₂[i,2]
        y₁ = df₂[i,3] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 20/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    CSV.write("instances/$instance/#1. strategic/arcs.csv", A)

    # Vehicles
    CSV.write("instances/$instance/#1. strategic/vehicles.csv", DataFrame(CSV.File("instances/$instance/vehicles.csv")))    

    return
end

# Generate instance for tactical decision-making
function gentac(rng::AbstractRNG, instance::String, version::String, share::Float64, consolidation::Int64, dynamism::Float64, day::Int64, strategic::LRP.Solution)
    mkpath("instances/$instance/#2. tactical - $version/day $day")
    p = share
    θ = consolidation
    δ = dynamism
    h = day
    s = strategic

    # Depot Nodes
    Dˢ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Float64[], pl = Float64[], pu = Float64[], ts = Float64[], te = Float64[], co = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        push!(Dˢ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ))
    end
    CSV.write("instances/$instance/#2. tactical - $version/day $h/depot_nodes.csv", Dˢ)
 
    # Customer Nodes
    Cᶜ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[])
    Cˢ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[])
    df = DataFrame(CSV.File("instances/$instance/customer nodes.csv"))
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
    Z  = Dict(df[r,6] => Int64[] for r ∈ 1:n)
    for r ∈ 1:n push!(Z[df[r,6]], df[r,1]) end
    for iᵗ ∈ keys(Z)
        zᶜ = Int64(round(length(Z[iᵗ]) * rand(rng, Uniform(0.8p, 1.2p)) / θ))
        zˢ = Int64(round((1 - δʰ) * zᶜ))
        zᵈ = zᶜ - zˢ
        Iᶜ = sample(rng, Z[iᵗ], zᶜ, replace=false)
        Iˢ = sample(rng, Iᶜ, zˢ, replace=false)
        Iᵈ = filter(x -> x ∉ Iˢ, Iᶜ)
        for iˢ ∈ Iˢ 
            push!(Cᶜ, (df[iˢ,1], df[iˢ,2], df[iˢ,3], θ, df[iˢ,4], df[iˢ,5])) 
            push!(Cˢ, (df[iˢ,1], df[iˢ,2], df[iˢ,3], θ, df[iˢ,4], df[iˢ,5])) 
        end
        for iᵈ ∈ Iᵈ 
            rand(rng, Uniform(tˢ, tˢ + (tᵉ - tˢ)/2))
            push!(Cᶜ, (df[iᵈ,1], df[iᵈ,2], df[iᵈ,3], θ, df[iᵈ,4], df[iᵈ,5]))
        end
        nᶜ += zᶜ
        nˢ += zˢ
        nᵈ += zᵈ
        δʰ  = min(1.0, max(0.0, (δ * p / θ * n - nᵈ)/(n * p / θ - nᶜ)))
    end
    for n ∈ 1:nᶜ Cᶜ[n,1] = n + Δn end
    for n ∈ 1:nˢ Cˢ[n,1] = n + Δn end
    Cᵒ = isequal(version, "counterfactual") ? Cᶜ : Cˢ
    CSV.write("instances/$instance/#2. tactical - $version/day $h/customer_nodes.csv", Cᵒ)

    # Arcs
    df₁ = DataFrame(CSV.File("instances/$instance/#2. tactical - $version/day $h/depot_nodes.csv"))
    df₂ = DataFrame(CSV.File("instances/$instance/#2. tactical - $version/day $h/customer_nodes.csv"))
    A   = DataFrame(t = Int64[], h = Int64[], l = Float64[], φ = Float64[])
    for i ∈ 1:nrow(df₁)
        iⁿ = df₁[i,1]
        x₁ = df₁[i,3]
        y₁ = df₁[i,4] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    for i ∈ 1:nrow(df₂)
        iⁿ = df₂[i,1]
        x₁ = df₂[i,2]
        y₁ = df₂[i,3] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 20/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    CSV.write("instances/$instance/#2. tactical - $version/day $h/arcs.csv", A)

    # Vehicles
    Vˢ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Float64[], l = Float64[], s = Float64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Float64[], r = Int64[], cd = Float64[], ct = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        for v ∈ d.V push!(Vˢ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵈ, v.πᵗ, v.πᶠ)) end
    end
    CSV.write("instances/$instance/#2. tactical - $version/day $h/vehicles.csv", Vˢ)

    return
end

# Generate instance for operational decision-making
function genopt(rng::AbstractRNG, instance::String, share::Float64, consolidation::Int64, dynamism::Float64, day::Int64, strategic::LRP.Solution)
    mkpath("instances/$instance/#3. operational/day $day")
    p = share
    θ = consolidation
    δ = dynamism
    h = day
    s = strategic
    
    # Depot Nodes
    Dᵈ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Int64[], pl = Float64[], pu = Float64[], ts = Int64[], te = Int64[], co = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        push!(Dᵈ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ))
    end
    CSV.write("instances/$instance/#3. operational/day $h/depot_nodes.csv", Dᵈ)
    
    # Customer Nodes
    Cᵈ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Float64[], te = Float64[], tl = Float64[], tr = Float64[])
    df = DataFrame(CSV.File("instances/$instance/customer nodes.csv"))
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
    Z  = Dict(df[r,6] => Int64[] for r ∈ 1:n)
    for r ∈ 1:n push!(Z[df[r,6]], df[r,1]) end
    for iᵗ ∈ keys(Z)
        zᶜ = Int64(round(length(Z[iᵗ]) * rand(rng, Uniform(0.8p, 1.2p)) / θ))
        zˢ = Int64(round((1 - δʰ) * zᶜ))
        zᵈ = zᶜ - zˢ
        Iᶜ = sample(rng, Z[iᵗ], zᶜ, replace=false)
        Iˢ = sample(rng, Iᶜ, zˢ, replace=false)
        Iᵈ = filter(x -> x ∉ Iˢ, Iᶜ)
        for iᵈ ∈ Iᵈ push!(Cᵈ, (df[iᵈ,1], df[iᵈ,2], df[iᵈ,3], θ, df[iᵈ,4], df[iᵈ,5], rand(rng, Uniform(tˢ, tˢ + (tᵉ - tˢ)/2)))) end
        nᶜ += zᶜ
        nˢ += zˢ
        nᵈ += zᵈ
        δʰ  = min(1.0, max(0.0, (δ * p / θ * n - nᵈ)/(n * p / θ - nᶜ)))
    end
    Cᵈ = Cᵈ[sortperm(Cᵈ[:,:tr]), :]
    for n ∈ 1:nᵈ Cᵈ[n,1] = n + nˢ + Δn end
    CSV.write("instances/$instance/#3. operational/day $h/customer_nodes.csv", Cᵈ)
    
    # Arcs
    df₁ = DataFrame(CSV.File("instances/$instance/#3. operational/day $h/depot_nodes.csv"))
    df₂ = DataFrame(CSV.File("instances/$instance/#2. tactical - actual/day $h/customer_nodes.csv"))
    df₃ = DataFrame(CSV.File("instances/$instance/#3. operational/day $h/customer_nodes.csv"))
    A   = DataFrame(t = Int64[], h = Int64[], l = Float64[], φ = Float64[])
    for i ∈ 1:nrow(df₁)
        iⁿ = df₁[i,1]
        x₁ = df₁[i,3]
        y₁ = df₁[i,4] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₃)
            jⁿ = df₃[j,1]
            x₂ = df₃[j,2]
            y₂ = df₃[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    for i ∈ 1:nrow(df₂)
        iⁿ = df₂[i,1]
        x₁ = df₂[i,2]
        y₁ = df₂[i,3] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 20/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₃)
            jⁿ = df₃[j,1]
            x₂ = df₃[j,2]
            y₂ = df₃[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 20/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    for i ∈ 1:nrow(df₃)
        iⁿ = df₃[i,1]
        x₁ = df₃[i,2]
        y₁ = df₃[i,3] 
        for j ∈ 1:nrow(df₁)
            jⁿ = df₁[j,1]
            x₂ = df₁[j,3]
            y₂ = df₁[j,4]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 55/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₂)
            jⁿ = df₂[j,1]
            x₂ = df₂[j,2]
            y₂ = df₂[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 20/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
        for j ∈ 1:nrow(df₃)
            jⁿ = df₃[j,1]
            x₂ = df₃[j,2]
            y₂ = df₃[j,3]
            l  = abs(x₂ - x₁) + abs(y₂ - y₁)
            φ  = 20/60
            push!(A, (iⁿ, jⁿ, l, φ))
        end
    end
    CSV.write("instances/$instance/#3. operational/day $h/arcs.csv", A)

    # Vehicles
    Vᵈ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Float64[], l = Float64[], s = Float64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Float64[], r = Int64[], cd = Float64[], ct = Float64[], cf = Float64[])
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        for v ∈ d.V push!(Vᵈ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵈ, v.πᵗ, v.πᶠ)) end
    end
    CSV.write("instances/$instance/#3. operational/day $h/vehicles.csv", Vᵈ)
    
    return
end