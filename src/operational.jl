include("insertnode.jl")
include("localsearch.jl")

# Operational decision-making
function optopr(rng::AbstractRNG, env::Dict, initsol::LRP.Solution)
    dir = env["dir"] 
    strategy = env["strategy"]
    day = env["day"]
    file = "$dir/$strategy/#3. operational/day $day/customer_nodes.csv"
    df = DataFrame(CSV.File(file))
    Iⁿ = (df[1,1]:df[nrow(df),1])::UnitRange{Int64}
    Tʳ = Dict{Int64, Float64}(iⁿ => 0. for iⁿ ∈ Iⁿ)
    C′ = OffsetVector{LRP.CustomerNode}(undef, Iⁿ)
    for k ∈ 1:nrow(df)
        iⁿ = df[k,1]::Int64
        x  = df[k,2]::Float64
        y  = df[k,3]::Float64
        q  = df[k,4]::Float64
        tᵉ = df[k,5]::Float64
        tˡ = df[k,6]::Float64
        tʳ = df[k,7]::Float64
        iᵗ = 0
        iʰ = 0
        tᵃ = 0
        tᵈ = 0
        c  = LRP.CustomerNode(iⁿ, x, y, q, tᵉ, tˡ, iᵗ, iʰ, tᵃ, tᵈ, LRP.NullRoute)
        C′[iⁿ] = c
        Tʳ[iⁿ] = tʳ
    end
    # Step 1. Simulate daily operations for day-t
    s  = initsol
    N  = length(s.D) + length(s.C)
    tˢ = Inf
    tᵉ = 0.
    for d ∈ s.D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ s.D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end
    τ = 1.
    t = tˢ - τ
    p = Progress(Int64((tᵉ - tˢ)/τ), desc="Computing...", color=:blue, showspeed=true)
    while t ≤ tᵉ
        # Step 1.1. Process delivery commitments
        for c ∈ C′
            iⁿ = c.iⁿ
            tʳ = Tʳ[iⁿ]
            tᶜ = tˢ + ceil((tʳ - tˢ)/τ) * τ
            if isequal(tᶜ, t)
                push!(s.C, c)
                N += 1
                for jⁿ ∈ 1:N
                    n = jⁿ ≤ length(s.D) ? s.D[jⁿ] : s.C[jⁿ]
                    x¹, y¹ = c.x, c.y
                    x², y² = n.x, n.y
                    l = sqrt((x² - x¹)^2 + (y² - y¹)^2)
                    s.A[(iⁿ,jⁿ)] = LRP.Arc(iⁿ, jⁿ, l)
                    s.A[(jⁿ,iⁿ)] = LRP.Arc(jⁿ, iⁿ, l)
                end
                insertnode!(rng, s)
            end
        end
        localsearch!(rng, 5000, s)
        # Step 1.2. Process route commitments
        for d ∈ s.D
            for v ∈ d.V
                for r ∈ v.R
                    if !LRP.isopt(r) continue end
                    if !LRP.isactive(r) continue end 
                    tᶜ = d.tˢ + floor((r.tⁱ + r.τ - d.tˢ)/τ) * τ
                    if isequal(tᶜ, t)
                        r.φ  = 0 
                        r.tⁱ = tᶜ
                        r.tˢ = r.tⁱ + v.τᶠ * (r.θˢ - r.θⁱ) + v.τᵈ * r.q
                        cˢ = s.C[r.iˢ]
                        cᵉ = s.C[r.iᵉ]
                        tᵈ = r.tˢ
                        cᵒ = cˢ
                        while true
                            cᵒ.tᵃ = tᵈ + s.A[(cᵒ.iᵗ,cᵒ.iⁿ)].l/v.s
                            cᵒ.tᵈ = cᵒ.tᵃ + max(0., cᵒ.tᵉ - cᵒ.tᵃ) + v.τᶜ
                            if isequal(cᵒ, cᵉ) break end
                            tᵈ = cᵒ.tᵈ
                            cᵒ = s.C[cᵒ.iʰ]
                        end
                        r.tᵉ = cᵉ.tᵈ + s.A[(cᵉ.iⁿ, cᵉ.iʰ)].l/v.s
                    end
                end
                (v.tˢ, v.tᵉ) = isempty(v.R) ? (d.tˢ, d.tˢ) : (v.R[1].tⁱ, v.R[length(v.R)].tᵉ)
            end
        end
        t += τ
        next!(p)
    end
    # Step 1.3. Update route slack times
    for d ∈ s.D
        for v ∈ d.V
            τ = d.tᵉ - v.tᵉ
            for r ∈ reverse(v.R)
                if !LRP.isopt(r) continue end
                cˢ = s.C[r.iˢ]
                cᵉ = s.C[r.iᵉ]
                cᵒ = cˢ
                while true
                    τ  = min(τ, cᵒ.tˡ - cᵒ.tᵃ)
                    if isequal(cᵒ, cᵉ) break end
                    cᵒ = s.C[cᵒ.iʰ]
                end
                r.τ = τ
            end
        end
    end

    # Step 2. Return solution
    return s
end