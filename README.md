# Last-Mile Logistics
This work models a last-mile network design problem for an e-retailer with a capacitated two-echelon distribution structure - typical in e-retail last-mile distribution, catering to a market with a stochastic and dynamic daily customer demand requesting delivery within time-windows.

Considering the distribution evnironment, this work formulates last-mile network design problem for this e-retatiler as a dynamic-stochastic two capacited location routing problem with time-windows. In doing so, this work splits the last-mile network design problem into its constituent strategic, tactical, and operational decisions. Here, the strategic decisions undertake long-term planning to develop a distribution structure with appropriate distribution facilities and a suitable delivery fleet to service the expected customer demand in the planning horizon. The tactical decisions pertain to medium-term day-to-day planning of last-mile delivery operations to establish efficient goods flow in this distribution structure to service the daily stochastic customer demand. And finally, operational decisions involve immediate short-term planning to fine-tune this last-mile delivery to service the requests arriving dynamically through the day.

Note, the last-mile network design problem problem formulated as a location routing problem constitutes three subproblems encompassing facility location problem, customer allocation problem, and vehicle routing problem, each of which are NP-hard combinatorial optimization problems. To this end, this work develops an adaptive large neighborhood search meta-heuristic algorithm that searches through the neighborhood by destroying and consequently repairing the solution thereby reconfiguring large portions of the solution with specific operators that are chosen adaptively in each iteration of the algorithm, hence the name adaptive large neighborhood search.

Further, considering the stochastic and dynamic nature of the delivery environment, this work develops a Monte-Carlo framework simulating each day in the planning horizon, with each day divided into 1-hr timeslots, and with each time-slot accepting customer requests for service by the end of the day. In particular, the framework assumes the e-retailer to delay route commitments until the last-feasible time-slot to accumulate customer requests and consequently assign them to an uncommitted delivery route. Note, a delivery route is committed once the e-retailer starts loading packages assigned to this delivery route onto the delivery vehicle assigned for this delivery route. At the end of every time-slot then, this framework assumes the e-retailer to integrate the new customer requests by inserting these customer nodes into such uncommitted delivery routes in a manner that results in least increase in distribution cost keeping the customer-distribution facility allocation fixed. Thus, the framework iterates through the time-slots with the e-retailer processing route commitments, accumulating customer requests, and subsequently integrating them into the delivery operations for the day.