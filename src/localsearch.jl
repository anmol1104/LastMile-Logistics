# Local Search
function localsearch!(rng::AbstractRNG, k̅::Int64, s::LRP.Solution)  
    move!(rng, k̅, s)
    opt!(rng, k̅, s)
    split!(rng, k̅, s)
    swap!(rng, k̅, s)
    return s
end

# Move
# Iteratively move a randomly seceted customer node in its best position if the move 
# results in reduction in objective function value for k̅ iterations until improvement
function move!(rng::AbstractRNG, k̅::Int64, s::LRP.Solution)
    zᵒ= f(s)
    D = s.D
    C = s.C
    # Step 1: Iterate for k̅ iterations until improvement
    for _ ∈ 1:k̅
        # Step 1.1: Randomly select a node
        i = rand(rng, firstindex(C):lastindex(C))
        c = C[i]
        r = c.r
        if !LRP.isactive(r) continue end
        d = D[r.iᵈ]
        R = [r for v ∈ d.V for r ∈ v.R if LRP.isactive(r)]
        X = fill(Inf, eachindex(R))                # x[j]: insertion cost in route R[j]
        P = fill((0, 0), eachindex(R))             # p[j]: best insertion postion in route R[j]
        # Step 1.2: Remove this node from its position between tail node nᵗ and head node nʰ
        nᵗ = isequal(r.iˢ, c.iⁿ) ? D[c.iᵗ] : C[c.iᵗ]
        nʰ = isequal(r.iᵉ, c.iⁿ) ? D[c.iʰ] : C[c.iʰ] 
        LRP.removenode!(c, nᵗ, nʰ, r, s)
        # Step 1.3: Iterate through all routes
        for (j,r) ∈ pairs(R)
            # Step 1.3.1: Iterate through all possible insertion positions
            d  = s.D[r.iᵈ]
            nˢ = LRP.isopt(r) ? C[r.iˢ] : D[r.iˢ] 
            nᵉ = LRP.isopt(r) ? C[r.iᵉ] : D[r.iᵉ]
            nᵗ = d
            nʰ = nˢ
            while true
                # Step 1.3.1.1: Insert customer node c between tail node nᵗ and head node nʰ
                LRP.insertnode!(c, nᵗ, nʰ, r, s)
                # Step 1.3.1.2: Compute insertion cost
                z′ = f(s)
                Δ  = z′ - zᵒ
                # Step 1.3.1.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
                if Δ < X[j] X[j], P[j] = Δ, (nᵗ.iⁿ, nʰ.iⁿ) end
                # Step 1.3.4: Remove node from its position between tail node nᵗ and head node nʰ
                LRP.removenode!(c, nᵗ, nʰ, r, s)
                if isequal(nᵗ, nᵉ) break end
                nᵗ = nʰ
                nʰ = isequal(r.iᵉ, nᵗ.iⁿ) ? D[nᵗ.iʰ] : C[nᵗ.iʰ]
            end
        end
        # Step 1.4: Move the node to its best position (this could be its original position as well)
        j = argmin(X)
        Δ = X[j]
        r = R[j]
        iᵗ = P[j][1]
        iʰ = P[j][2]
        nᵗ = iᵗ ≤ length(D) ? D[iᵗ] : C[iᵗ]
        nʰ = iʰ ≤ length(D) ? D[iʰ] : C[iʰ]
        LRP.insertnode!(c, nᵗ, nʰ, r, s)
        # Step 1.5: Revise vectors appropriately
        X .= Inf
        P .= ((0, 0), )
    end
    # Step 2: Return solution
    return s
end

# 2-opt
# Iteratively take 2 arcs and reconfigure them (total possible reconfigurations 2²-1 = 3) if the 
# reconfigure results in reduction in objective function value for k̅ iterations until improvement
function opt!(rng::AbstractRNG, k̅::Int64, s::LRP.Solution)
    zᵒ= f(s)
    D = s.D
    C = s.C
    R = [r for d ∈ D for v ∈ d.V for r ∈ v.R]
    # Step 1: Iterate for k̅ iterations until improvement
    for _ ∈ 1:k̅
        # Step 1.1: Iteratively take 2 arcs
        # d² → ... → n¹ → n² → n³ → ... → d² and d⁵ → ... → n⁴ → n⁵ → n⁶ → ... → d⁵
        r², r⁵ = sample(rng, R, 2)
        d², d⁵ = D[r².iᵈ], D[r⁵.iᵈ]
        if !isequal(d², d⁵) continue end
        if !LRP.isopt(r²) continue end
        if !LRP.isopt(r⁵) continue end
        if !LRP.isactive(r²) continue end
        if !LRP.isactive(r⁵) continue end
        if isequal(r², r⁵)
            r = r²
            (i,j) = sample(rng, 1:r.n, 2)
            (i,j) = j < i ? (j,i) : (i,j)  
            k  = 1
            c  = C[r.iˢ]
            n² = c
            n⁵ = c
            while true
                if isequal(k, i) n² = c end
                if isequal(k, j) n⁵ = c end
                if isequal(k, j) break end
                k += 1
                c  = C[c.iʰ]
            end
            n¹ = isequal(r.iˢ, n².iⁿ) ? D[n².iᵗ] : C[n².iᵗ]
            n³ = isequal(r.iᵉ, n².iⁿ) ? D[n².iʰ] : C[n².iʰ]
            n⁴ = isequal(r.iˢ, n⁵.iⁿ) ? D[n⁵.iᵗ] : C[n⁵.iᵗ]
            n⁶ = isequal(r.iᵉ, n⁵.iⁿ) ? D[n⁵.iʰ] : C[n⁵.iʰ] 
            if isequal(n², n⁵) || isequal(n¹, n⁵) continue end 
            # Step 1.2: Reconfigure
            # d → ... → n¹ → n⁵ → n⁴ → ... → n³ → n² → n⁶ → ... → d
            n  = n²
            tᵒ = n¹
            hᵒ = n³
            tⁿ = n⁵
            hⁿ = n⁶
            while true
                LRP.removenode!(n, tᵒ, hᵒ, r, s)
                LRP.insertnode!(n, tⁿ, hⁿ, r, s)
                hⁿ = n
                n  = hᵒ
                hᵒ = LRP.isdepot(hᵒ) ? C[r.iˢ] : (isequal(r.iᵉ, hᵒ.iⁿ) ? D[hᵒ.iʰ] : C[hᵒ.iʰ])
                if isequal(n, n⁵) break end
            end
            # Step 1.3: Compute change in objective function value
            z′ = f(s)
            Δ  = z′ - zᵒ 
            # Step 1.4: If the reconfiguration results in reduction in objective function value then go to step 2, else go to step 1.5
            if Δ < 0 continue end
            # Step 1.5: Reconfigure back to the original state
            # d → ... → n¹ → n² → n³ → ... → n⁴ → n⁵ → n⁶ → ... → d
            n  = n⁵
            tᵒ = n¹
            hᵒ = n⁴
            tⁿ = n²
            hⁿ = n⁶
            while true
                LRP.removenode!(n, tᵒ, hᵒ, r, s)
                LRP.insertnode!(n, tⁿ, hⁿ, r, s)
                hⁿ = n
                n  = hᵒ
                hᵒ = LRP.isdepot(hᵒ) ? C[r.iˢ] : (isequal(r.iᵉ, hᵒ.iⁿ) ? D[hᵒ.iʰ] : C[hᵒ.iʰ])
                if isequal(n, n²) break end
            end
        else
            i  = rand(rng, 1:r².n)
            k  = 1
            c² = C[r².iˢ]
            n² = c²
            while true
                if isequal(k, i) n² = c² end
                if isequal(k, i) break end
                k += 1
                c² = C[c².iʰ]
            end
            n¹ = isequal(r².iˢ, n².iⁿ) ? D[n².iᵗ] : C[n².iᵗ]
            n³ = isequal(r².iᵉ, n².iⁿ) ? D[n².iʰ] : C[n².iʰ]
            j  = rand(rng, 1:r⁵.n)
            k  = 1
            c⁵ = C[r⁵.iˢ]
            n⁵ = c⁵
            while true
                if isequal(k, j) n⁵ = c⁵ end
                if isequal(k, j) break end
                k += 1
                c⁵ = C[c⁵.iʰ]
            end
            n⁴ = isequal(r⁵.iˢ, n⁵.iⁿ) ? D[n⁵.iᵗ] : C[n⁵.iᵗ]
            n⁶ = isequal(r⁵.iᵉ, n⁵.iⁿ) ? D[n⁵.iʰ] : C[n⁵.iʰ]
            # Step 1.2: Reconfigure
            # d² → ... → n¹ → n⁵ → n⁶ → ...  → d² and d⁵ → ... → n⁴ → n² → n³ → ... → d⁵
            c² = n²
            tᵒ = n¹
            hᵒ = n³
            tⁿ = n⁴
            hⁿ = n⁵
            while true
                LRP.removenode!(c², tᵒ, hᵒ, r², s)
                LRP.insertnode!(c², tⁿ, hⁿ, r⁵, s)
                if isequal(hᵒ, d²) break end
                tⁿ = c² 
                c² = C[hᵒ.iⁿ]
                hᵒ = isequal(r².iᵉ, c².iⁿ) ? D[c².iʰ] : C[c².iʰ]
            end
            c⁵ = n⁵
            tᵒ = c²
            hᵒ = n⁶
            tⁿ = n¹
            hⁿ = d²
            while true
                LRP.removenode!(c⁵, tᵒ, hᵒ, r⁵, s)
                LRP.insertnode!(c⁵, tⁿ, hⁿ, r², s)
                if isequal(hᵒ, d⁵) break end
                tⁿ = c⁵
                c⁵ = C[hᵒ.iⁿ]
                hᵒ = isequal(r⁵.iᵉ, c⁵.iⁿ) ? D[c⁵.iʰ] : C[c⁵.iʰ]
            end
            # Step 1.3: Compute change in objective function value
            z′ = f(s)
            Δ  = z′ - zᵒ 
            # Step 1.4: If the reconfiguration results in reduction in objective function value then go to step 2, else go to step 1.5
            if Δ < 0 continue end
            # Step 1.5: Reconfigure back to the original state
            # d² → ... → n¹ → n² → n³ → ... → d² and d⁵ → ... → n⁴ → n⁵ → n⁶ → ... → d⁵
            c² = n⁵
            tᵒ = n¹
            hᵒ = isequal(r².iᵉ, c².iⁿ) ? D[c².iʰ] : C[c².iʰ]
            tⁿ = n⁴
            hⁿ = n²
            while true
                LRP.removenode!(c², tᵒ, hᵒ, r², s)
                LRP.insertnode!(c², tⁿ, hⁿ, r⁵, s)
                if isequal(hᵒ, d²) break end
                tⁿ = c² 
                c² = C[hᵒ.iⁿ]
                hᵒ = isequal(r².iᵉ, c².iⁿ) ? D[c².iʰ] : C[c².iʰ]
            end
            c⁵ = n²
            tᵒ = c²
            hᵒ = isequal(r⁵.iᵉ, c⁵.iⁿ) ? D[c⁵.iʰ] : C[c⁵.iʰ]
            tⁿ = n¹
            hⁿ = d²
            while true
                LRP.removenode!(c⁵, tᵒ, hᵒ, r⁵, s)
                LRP.insertnode!(c⁵, tⁿ, hⁿ, r², s)
                if isequal(hᵒ, d⁵) break end
                tⁿ = c⁵
                c⁵ = C[hᵒ.iⁿ]
                hᵒ = isequal(r⁵.iᵉ, c⁵.iⁿ) ? D[c⁵.iʰ] : C[c⁵.iʰ]
            end
        end
    end
    # Step 2: Return solution
    return s
end

# Split
# Iteratively split routes by moving a randomly selected depot node at best position if the
# split results in reduction in objective function value for k̅ iterations until improvement
function split!(rng::AbstractRNG, k̅::Int64, s::LRP.Solution)
    zᵒ = f(s)
    z′ = zᵒ
    D = s.D
    C = s.C
    # Step 1: Iterate for k̅ iterations until improvement
    for _ ∈ 1:k̅
        # Step 1.1: Select a random depot node d and a route originiating from this depot node
        d = sample(rng, D)
        R = [r for v ∈ d.V for r ∈ v.R]
        if isempty(R) continue end
        r = sample(rng, R)
        if !LRP.isopt(r) continue end
        if !LRP.isactive(r) continue end
        # Step 1.2: Remove depot node d from its position in route r
        cˢ = C[r.iˢ]
        cᵉ = C[r.iᵉ]
        x = 0.
        p = (cᵉ.iⁿ, cˢ.iⁿ)
        LRP.removenode!(d, cᵉ, cˢ, r, s)
        # Step 1.3: Iterate through all possible positions in route r
        cᵗ = cˢ
        cʰ = C[cᵗ.iʰ]
        while true
            # Step 1.3.1: Insert depot node d between tail node nᵗ and head node nʰ
            LRP.insertnode!(d, cᵗ, cʰ, r, s)
            # Step 1.3.2: Compute change in objective function value
            z″ = f(s) 
            Δ  = z″ - z′
            # Step 1.3.3: Revise least insertion cost in route r and the corresponding best insertion position in route r
            if Δ < x x, p = Δ, (cᵗ.iⁿ, cʰ.iⁿ) end
            # Step 1.3.4: Remove depot node d from its position between tail node nᵗ and head node nʰ
            LRP.removenode!(d, cᵗ, cʰ, r, s)
            if isequal(cʰ, cᵉ) break end
            cᵗ = cʰ
            cʰ = C[cᵗ.iʰ]
        end
        # Step 1.4: Move the depot node to its best position in route r (this could be its original position as well)
        iᵗ, iʰ = p
        cᵗ = C[iᵗ]
        cʰ = C[iʰ]
        LRP.insertnode!(d, cᵗ, cʰ, r, s)
        z′ = f(s) 
    end
    # Step 2: Return solution
    return s
end

# Swap customer nodes
# Iteratively swap two randomly selected customer nodes if the swap results
# in reduction in objective function value for k̅ iterations until improvement
function swap!(rng::AbstractRNG, k̅::Int64, s::LRP.Solution)
    zᵒ= f(s)
    D = s.D
    C = s.C
    # Step 1: Iterate for k̅ iterations until improvement
    for _ ∈ 1:k̅
        # Step 1.1: Swap two randomly selected customer nodes
        # n¹ → n² → n³ and n⁴ → n⁵ → n⁶
        n², n⁵ = C[rand(rng, firstindex(C):lastindex(C))], C[rand(rng, firstindex(C):lastindex(C))]
        r², r⁵ = n².r, n⁵.r
        d², d⁵ = D[r².iᵈ], D[r⁵.iᵈ]
        if isequal(n², n⁵) continue end
        if !isequal(d², d⁵) continue end
        if !LRP.isactive(r²) continue end
        if !LRP.isactive(r⁵) continue end
        n¹ = isequal(r².iˢ, n².iⁿ) ? D[n².iᵗ] : C[n².iᵗ]
        n³ = isequal(r².iᵉ, n².iⁿ) ? D[n².iʰ] : C[n².iʰ]
        n⁴ = isequal(r⁵.iˢ, n⁵.iⁿ) ? D[n⁵.iᵗ] : C[n⁵.iᵗ]
        n⁶ = isequal(r⁵.iᵉ, n⁵.iⁿ) ? D[n⁵.iʰ] : C[n⁵.iʰ]
        # n¹ → n² (n⁴) → n³ (n⁵) → n⁶   ⇒   n¹ → n³ (n⁵) → n² (n⁴) → n⁶
        if isequal(n³, n⁵)
            LRP.removenode!(n², n¹, n³, r², s)
            LRP.insertnode!(n², n⁵, n⁶, r⁵, s)
        # n⁴ → n⁵ (n¹) → n² (n⁶) → n³   ⇒   n⁴ → n² (n⁶) → n⁵ (n¹) → n³   
        elseif isequal(n², n⁶)
            LRP.removenode!(n², n¹, n³, r², s)
            LRP.insertnode!(n², n⁴, n⁵, r⁵, s)
        # n¹ → n² → n³ and n⁴ → n⁵ → n⁶ ⇒   n¹ → n⁵ → n³ and n⁴ → n² → n⁶
        else 
            LRP.removenode!(n², n¹, n³, r², s)
            LRP.removenode!(n⁵, n⁴, n⁶, r⁵, s)
            LRP.insertnode!(n⁵, n¹, n³, r², s)
            LRP.insertnode!(n², n⁴, n⁶, r⁵, s)
        end
        # Step 1.2: Compute change in objective function value
        z′ = f(s)
        Δ  = z′ - zᵒ 
        # Step 1.3: If the swap results in reduction in objective function value then go to step 2, else go to step 1.4
        if Δ < 0 continue end
        # Step 1.4: Reswap the two customer nodes and go to step 1.1
        # n¹ → n² (n⁴) → n³ (n⁵) → n⁶   ⇒   n¹ → n³ (n⁵) → n² (n⁴) → n⁶
        if isequal(n³, n⁵)
            LRP.removenode!(n², n⁵, n⁶, r⁵, s)
            LRP.insertnode!(n², n¹, n³, r², s)
        # n⁴ → n⁵ (n¹) → n² (n⁶) → n³   ⇒   n⁴ → n² (n⁶) → n⁵ (n¹) → n³   
        elseif isequal(n², n⁶)
            LRP.removenode!(n², n⁴, n⁵, r⁵, s)
            LRP.insertnode!(n², n¹, n³, r², s)
        # n¹ → n² → n³ and n⁴ → n⁵ → n⁶ ⇒   n¹ → n⁵ → n³ and n⁴ → n² → n⁶
        else 
            LRP.removenode!(n⁵, n¹, n³, r², s)
            LRP.removenode!(n², n⁴, n⁶, r⁵, s)
            LRP.insertnode!(n², n¹, n³, r², s)
            LRP.insertnode!(n⁵, n⁴, n⁶, r⁵, s)
        end
    end
    # Step 2: Return solution
    return s
end