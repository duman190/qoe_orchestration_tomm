function isQoSSatisfied = estimatePathBw(t, shortestPath, Delay_QoS, Cost_QoS, Bw_QoS)
isQoSSatisfied = 0;

if ~isempty(shortestPath)
    delay = 0;
    cost = 0;
    
    nodes = t.nodes;
    edges = t.edges;
    
    N = length(shortestPath);
    for i=1:N-1
        src = nodes(shortestPath(i));
        dst = nodes(shortestPath(i+1));
        edge = edges(src.neighbors.get(dst.id));
        
        if (edge.bw < Bw_QoS)
            return;
        end;
        
        delay = delay + edge.delay;
        cost = cost + edge.cost;
    end;
    
    isQoSSatisfied = (delay<=Delay_QoS && cost<=Cost_QoS);
end