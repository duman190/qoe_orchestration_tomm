%function t = load_topo(nodes_file, edges_file) 
clear all;
clc;

nodes_file='b_n_3.xlsx';
edges_file='b_e_3.xlsx';
nodes_array = xlsread(nodes_file);
edges_array = xlsread(edges_file);

for i=1:size(nodes_array,1)
    nodes(i,1) = node(nodes_array(i,1)+1,nodes_array(i,2), nodes_array(i,3));
end;

for i=1:size(edges_array,1)
    newEdge = edge(edges_array(i,1)+1, edges_array(i,2)+1, edges_array(i,3)+1, edges_array(i,4), edges_array(i,6),rand*8+1);
    edges(i,1) = newEdge;
    
    %init neighbors
    src = nodes(newEdge.src,1);  
    dst = nodes(newEdge.dst,1);  
    src.addNeighbors(dst.id, newEdge.id);
    dst.addNeighbors(src.id, newEdge.id);
end;

t = topology(nodes, edges);

% for i=1:size(nodes,1)
%     t.getNode(i).neighbors
% end;

% arguments: topology, src id, dst id, bw, prop delay (simple just length) (if delay == 0 than l case, if both dleay and bw == 0 provides sp)
%path = neighborhoodMethod(t, 8, 3, 5.0, 10000)
%end