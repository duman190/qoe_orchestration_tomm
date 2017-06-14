function netMatrix = topologyToMatrix(t, bw, delay)
netMatrix = Inf(t.getNodeNumber);
edges = t.edges;

if delay == 0
    for i = 1:size(edges, 1)
        edge = edges(i);
        if(edge.bw >= bw)
            netMatrix(edge.src, edge.dst) = 1;
            netMatrix(edge.dst, edge.src) = 1;
        end;
    end;
else
    for i = 1:size(edges, 1)
        edge = edges(i);
        if(edge.bw >= bw)
            netMatrix(edge.src, edge.dst) = edge.delay;
            netMatrix(edge.dst, edge.src) = edge.delay;
        end;
    end;
end;

end