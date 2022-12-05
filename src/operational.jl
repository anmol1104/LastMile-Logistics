include("insertnode.jl")
include("localsearch.jl")

# Operational decision-making
function optopr(rng::AbstractRNG, instance::String, day::Int64, tactical::LRP.Solution)
    instance = "$instance/#3. operational/day $day"
    dir      = "G:/My Drive/Academia/Research/Projects/2022. Last-Mile Logistics/Analysis/instances"

    file     = joinpath(dir, "$instance/customer_nodes.csv")
    csv      = CSV.File(file, types=[Int64, Float64, Float64, Float64, Float64, Float64, Float64])
    df       = DataFrame(csv)
    Iⁿ       = (df[1,1]:df[nrow(df),1])::UnitRange{Int64}
    Tʳ       = Dict{Int64, Float64}(iⁿ => 0. for iⁿ ∈ Iⁿ)
    C′       = OffsetVector{LRP.CustomerNode}(undef, Iⁿ)
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

    file     = joinpath(dir, "$instance/arcs.csv")
    csv      = CSV.File(file, types=[Int64, Int64, Float64, Float64])
    df       = DataFrame(csv)
    A′       = Dict{Tuple{Int64,Int64},LRP.Arc}()
    for k ∈ 1:nrow(df)
        iⁿ = df[k,1]::Int64
        jⁿ = df[k,2]::Int64
        l  = df[k,3]::Float64
        φ  = df[k,4]::Float64
        a  = LRP.Arc(iⁿ, jⁿ, l, φ)
        A′[(iⁿ,jⁿ)] = a
    end

    # Step 1. Simulate daily operations for day-t
    s = deepcopy(tactical)
    D = s.D
    C = s.C
    A = s.A
    N = length(D) + length(C)
    tˢ = Inf
    tᵉ = 0.
    for d ∈ D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end
    τ = 1.
    t = tˢ - τ
    p = Progress(Int64((tᵉ - tˢ)/τ), desc="Computing...", color=:blue, showspeed=true)
    while t ≤ tᵉ
        # Step 1.1. Process delivery requests
        for c ∈ C′
            iⁿ = c.iⁿ
            tʳ = Tʳ[iⁿ]
            tᶜ = tˢ + ceil((tʳ - tˢ)/τ) * τ
            if isequal(tᶜ, t)
                push!(C, c)
                N += 1
                for jⁿ ∈ 1:N
                    A[(iⁿ,jⁿ)] = A′[(iⁿ, jⁿ)]
                    A[(jⁿ,iⁿ)] = A′[(jⁿ, iⁿ)]
                end
            end
        end
        insertnode!(rng, s)
        localsearch!(rng, 1000, s)
        # Step 1.2. Process route commitments
        for d ∈ D
            for v ∈ d.V
                for r ∈ v.R
                    if !LRP.isopt(r) continue end
                    if !LRP.isactive(r) continue end 
                    tᶜ = d.tˢ + floor((r.tⁱ + r.τ - d.tˢ)/τ) * τ
                    if isequal(tᶜ, t)
                        r.φ  = 0 
                        r.tⁱ = tᶜ
                        r.tˢ = r.tⁱ + v.τᶠ * (r.θˢ - r.θⁱ) + v.τᵈ * r.q
                        cˢ = C[r.iˢ]
                        cᵉ = C[r.iᵉ]
                        tᵈ = r.tˢ
                        cᵒ = cˢ
                        while true
                            a = A[(cᵒ.iᵗ,cᵒ.iⁿ)]
                            cᵒ.tᵃ = tᵈ + a.l/(v.s * a.φ)
                            cᵒ.tᵈ = cᵒ.tᵃ + max(0., cᵒ.tᵉ - cᵒ.tᵃ) + v.τᶜ
                            if isequal(cᵒ, cᵉ) break end
                            tᵈ = cᵒ.tᵈ
                            cᵒ = C[cᵒ.iʰ]
                        end
                        a = A[(cᵉ.iⁿ, cᵉ.iʰ)]
                        r.tᵉ = cᵉ.tᵈ + a.l/(v.s * a.φ)
                    end
                end
                (v.tˢ, v.tᵉ) = isempty(v.R) ? (d.tˢ, d.tˢ) : (v.R[1].tⁱ, v.R[length(v.R)].tᵉ)
            end
        end
        t += τ
        next!(p)
    end
    # Step 1.3. Update route slack times
    for d ∈ D
        for v ∈ d.V
            τ = d.tᵉ - v.tᵉ
            for r ∈ reverse(v.R)
                if !LRP.isopt(r) continue end
                cˢ = C[r.iˢ]
                cᵉ = C[r.iᵉ]
                cᵒ = cˢ
                while true
                    τ  = min(τ, cᵒ.tˡ - cᵒ.tᵃ)
                    if isequal(cᵒ, cᵉ) break end
                    cᵒ = C[cᵒ.iʰ]
                end
                r.τ = τ
            end
        end
    end

    # Step 2. Return solution
    return s
end