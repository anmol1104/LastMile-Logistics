# Greedy insertion
# Iteratively insert customer nodes with least insertion cost until all open customer nodes have been added to the solution
function insertnode!(rng::AbstractRNG, s::LRP.Solution)
    if all(LRP.isclose, s.C) return s end
    D = s.D
    C = s.C
    # Step 1: Initialize
    LRP.preinsertion!(s)
    R = [r for d ∈ D for v ∈ d.V for r ∈ v.R if LRP.isactive(r)]
    L = [c for c ∈ C if LRP.isopen(c)]
    I = eachindex(L)
    J = eachindex(R)
    X = ElasticMatrix(fill(Inf, (I,J)))     # X[i,j]: insertion cost of customer node L[i] at best position in route R[j]
    P = ElasticMatrix(fill((0, 0), (I,J)))  # P[i,j]: best insertion postion of customer node L[i] in route R[j]
    ϕ = ones(Int64, J)                      # ϕ[j]  : selection weight for route R[j]
    # Step 2: Iterate until all open customer nodes have been inserted into the route
    for _ ∈ I
        # Step 2.1: Iterate through all open customer nodes and every possible insertion position in each route
        zᵒ = f(s)
        for (i,c) ∈ pairs(L)
            if !LRP.isopen(c) continue end
            for (j,r) ∈ pairs(R)
                if iszero(ϕ[j]) continue end
                d  = s.D[r.iᵈ]
                nˢ = LRP.isopt(r) ? C[r.iˢ] : D[r.iˢ]
                nᵉ = LRP.isopt(r) ? C[r.iᵉ] : D[r.iᵉ]
                nᵗ = d
                nʰ = nˢ
                while true
                    # Step 2.1.1: Insert customer node c between tail node nᵗ and head node nʰ in route r
                    LRP.insertnode!(c, nᵗ, nʰ, r, s)
                    # Step 2.1.2: Compute the insertion cost
                    z⁺ = f(s)
                    Δ  = z⁺ - zᵒ
                    # Step 2.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                    if Δ < X[i,j] X[i,j], P[i,j] = Δ, (nᵗ.iⁿ, nʰ.iⁿ) end
                    # Step 2.1.4: Remove customer node c from its position between tail node nᵗ and head node nʰ
                    LRP.removenode!(c, nᵗ, nʰ, r, s)
                    if isequal(nᵗ, nᵉ) break end
                    nᵗ = nʰ
                    nʰ = isequal(r.iᵉ, nᵗ.iⁿ) ? D[nᵗ.iʰ] : C[nᵗ.iʰ]
                end
            end
        end
        # Step 2.2: Insert customer node with least insertion cost at its best position        
        i,j = Tuple(argmin(X))
        c = L[i]
        r = R[j]
        d = s.D[r.iᵈ]
        v = d.V[r.iᵛ]
        iᵗ = P[i,j][1]
        iʰ = P[i,j][2]
        nᵗ = iᵗ ≤ length(D) ? D[iᵗ] : C[iᵗ]
        nʰ = iʰ ≤ length(D) ? D[iʰ] : C[iʰ]
        LRP.insertnode!(c, nᵗ, nʰ, r, s)
        # Step 2.3: Revise vectors appropriately
        X[i,:] .= Inf
        P[i,:] .= ((0, 0), )
        ϕ .= 0
        for (j,r) ∈ pairs(R) 
            if !isequal(r.iᵛ, v.iᵛ) continue end
            X[:,j] .= Inf
            P[:,j] .= ((0, 0), )
            ϕ[j] = 1  
        end
        if LRP.addroute(r, s)
            r = LRP.Route(v, d)
            push!(v.R, r) 
            push!(R, r)
            append!(X, fill(Inf, (I,1)))
            append!(P, fill((0, 0), (I,1)))
            push!(ϕ, 1)
        end
        if LRP.addvehicle(v, s)
            v = LRP.Vehicle(v, d)
            r = LRP.Route(v, d)
            push!(d.V, v)
            push!(v.R, r) 
            push!(R, r)
            append!(X, fill(Inf, (I,1)))
            append!(P, fill((0, 0), (I,1)))
            push!(ϕ, 1)
        end
    end
    LRP.postinsertion!(s)
    # Step 3: Return solution
    return s
end