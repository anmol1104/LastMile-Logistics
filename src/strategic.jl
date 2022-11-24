# Strategic decision-making
function optstr(rng::AbstractRNG, instance::String)
    # Step 1. Visualize instance
    instance = "$instance/#1. strategic"
    dir      = "G:/My Drive/Academia/Research/Projects/2022. Last-Mile Logistics/Analysis/instances"
    display(visualize(instance; root=dir))

    # Step 2. Build strategic solution
    G  = build(instance; root=dir)
    s  = initialsolution(rng, G, :cluster)

    # Step 3. Return solution
    return s
end