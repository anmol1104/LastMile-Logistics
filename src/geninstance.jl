# Generate instance for tactical and operational decision-making
function geninstance(rng::AbstractRNG, instance::String, share::Float64, consolidation::Int64, dynamism::Float64, day::Int64, strategic::LRP.Solution)
    p = share
    θ = consolidation
    δ = dynamism
    h = day
    s = strategic
    tˢ = Inf
    tᵉ = 0.
    for d ∈ s.D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ s.D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end
    mkpath("instances/$instance/#2. tactical/day $h")
    mkpath("instances/$instance/#3. operational/day $h")
    Cˢ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Int64[], te = Float64[], tl = Float64[])
    Cᵈ = DataFrame(in = Int64[], x = Float64[], y = Float64[], q = Int64[], te = Float64[], tl = Float64[], tr = Float64[])
    Dˢ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Int64[], pl = Float64[], pu = Float64[], ts = Int64[], te = Int64[], co = Float64[], cf = Float64[])
    Dᵈ = DataFrame(in = Int64[], jn = Int64[], x = Float64[], y = Float64[], q = Int64[], pl = Float64[], pu = Float64[], ts = Int64[], te = Int64[], co = Float64[], cf = Float64[])
    Vˢ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Int64[], l = Int64[], s = Int64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Int64[], r = Int64[], co = Float64[], cf = Float64[])
    Vᵈ = DataFrame(iv = Int64[], jv = Int64[], id = Int64[], q = Int64[], l = Int64[], s = Int64[], tf = Float64[], td = Float64[], tc = Float64[], tw = Int64[], r = Int64[], co = Float64[], cf = Float64[])
    df = DataFrame(CSV.File("instances/$instance/customer nodes.csv"))
    Z  = Dict(df[r,6] => Int64[] for r ∈ 1:nrow(df))
    for r ∈ 1:nrow(df) push!(Z[df[r,6]], df[r,1]) end
    n  = nrow(df)
    nᶜ = 0
    nˢ = 0
    nᵈ = 0
    δʰ = δ
    for iᵗ ∈ keys(Z)
        zᶜ = Int64(round(length(Z[iᵗ]) * rand(rng, Uniform(0.8p, 1.2p)) / θ))
        zˢ = Int64(round((1 - δʰ) * zᶜ))
        zᵈ = zᶜ - zˢ
        Iᶜ = sample(rng, Z[iᵗ], zᶜ, replace=false)
        Iˢ = sample(rng, Iᶜ, zˢ, replace=false)
        Iᵈ = filter(x -> x ∉ Iˢ, Iᶜ)
        for iˢ ∈ Iˢ push!(Cˢ, (df[iˢ,1], df[iˢ,2], df[iˢ,3], θ, df[iˢ,4], df[iˢ,5])) end
        for iᵈ ∈ Iᵈ push!(Cᵈ, (df[iᵈ,1], df[iᵈ,2], df[iᵈ,3], θ, df[iᵈ,4], df[iᵈ,5], rand(rng, Uniform(tˢ, tˢ + (tᵉ - tˢ)/2)))) end
        nᶜ += zᶜ
        nˢ += zˢ
        nᵈ += zᵈ
        δʰ  = min(1.0, max(0.0, (δ * p / θ * n - nᵈ)/(n * p / θ - nᶜ)))
    end
    Δn = sum(LRP.isopt.(s.D))
    Cᵈ = Cᵈ[sortperm(Cᵈ[:,:tr]), :]
    for n ∈ 1:nˢ Cˢ[n,1] = n + Δn end
    for n ∈ 1:nᵈ Cᵈ[n,1] = n + nˢ + Δn end
    iᵈ = 0
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        iᵈ += 1
        push!(Dˢ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ))
        push!(Dᵈ, (iᵈ, d.jⁿ, d.x, d.y, d.q, d.pˡ, d.pᵘ, d.tˢ, d.tᵉ, d.πᵒ, d.πᶠ))
        for v ∈ d.V push!(Vˢ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵒ, v.πᶠ)) end
        for v ∈ d.V push!(Vᵈ, (v.iᵛ, v.jᵛ, iᵈ, v.q, v.l, v.s, v.τᶠ, v.τᵈ, v.τᶜ, v.τʷ, v.r̅, v.πᵒ, v.πᶠ)) end
    end
    CSV.write("instances/$instance/#2. tactical/day $h/customer_nodes.csv", Cˢ)
    CSV.write("instances/$instance/#2. tactical/day $h/depot_nodes.csv", Dˢ)
    CSV.write("instances/$instance/#2. tactical/day $h/vehicles.csv", Vˢ)
    CSV.write("instances/$instance/#3. operational/day $h/customer_nodes.csv", Cᵈ)
    CSV.write("instances/$instance/#3. operational/day $h/depot_nodes.csv", Dᵈ)
    CSV.write("instances/$instance/#3. operational/day $h/vehicles.csv", Vᵈ)
    return
end