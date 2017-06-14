function netMatrix = topo_to_matrix(t, bw, delay, cost, type)
netMatrix = Inf(t.getNodeNumber);
edges = t.edges;

if strcmp(type, 'bw_qos')
    for i = 1:size(edges, 1)
        edge = edges(i);
        if edge.bw >= bw
            netMatrix(edge.src, edge.dst) = 1;
            netMatrix(edge.dst, edge.src) = 1;
        end;
    end;
elseif strcmp(type, 'delay_qos')
    for i = 1:size(edges, 1)
        edge = edges(i);
        if edge.bw >= bw
            netMatrix(edge.src, edge.dst) = edge.delay;
            netMatrix(edge.dst, edge.src) = edge.delay;
        end;
    end;
elseif strcmp(type, 'cost_qos')
    for i = 1:size(edges, 1)
        edge = edges(i);
        if edge.bw >= bw
            netMatrix(edge.src, edge.dst) = edge.cost;
            netMatrix(edge.dst, edge.src) = edge.cost;
        end;
    end;
elseif strcmp(type, 'mixed_qos')
    for i = 1:size(edges, 1)
        edge = edges(i);
        if edge.bw >= bw
            mixed_metric = calculateMixedMetric(edge.delay, edge.cost, delay, cost);
            netMatrix(edge.src, edge.dst) = mixed_metric;
            netMatrix(edge.dst, edge.src) = mixed_metric;
        end;
    end;
elseif strcmp(type, 'ospf')
    for i = 1:size(edges, 1)
        edge = edges(i);
        %if edge.bw >= bw
            mixed_metric = 1/edge.bw;
            netMatrix(edge.src, edge.dst) = mixed_metric;
            netMatrix(edge.dst, edge.src) = mixed_metric;
        %end;
    end;
elseif strcmp(type, 'no_qos')
    for i = 1:size(edges, 1)
        edge = edges(i);
        
        netMatrix(edge.src, edge.dst) = 1;
        netMatrix(edge.dst, edge.src) = 1;
    end;
end;
end