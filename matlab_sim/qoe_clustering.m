function [U,C] = qoe_clustering (M, topo)

nodes_file='_nodes.csv';
edges_file='_edges.csv';
nodes_array = csvread(strcat(topo,nodes_file);
edges_array = csvread(edges_file);

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

BW_QoS = 2; %Mbps
Delay_QoS = sqrt(2)*100; %Maximum possible delay of an edge

%% - different network topos
netMatrix_Cost = topo_to_matrix(t, BW_QoS, Delay_QoS, Inf, 'cost_qos');
netMatrix_Delay = topo_to_matrix(t, BW_QoS, Delay_QoS, Inf, 'delay_qos');
netMatrix = topo_to_matrix(t, BW_QoS, Delay_QoS, Inf, 'bw_qos');
netMatrix_Mixed = topo_to_matrix(t, BW_QoS, Delay_QoS, Inf, 'mixed_qos');
netMatrix_OSPF = topo_to_matrix(t, BW_QoS, Delay_QoS, Inf, 'ospf');
netMatrix_RIP = topo_to_matrix(t, BW_QoS, Delay_QoS, Inf, 'no_qos');


success_ratio=0;
%% PCM
[PCM_U, PCM_centers, ~, ~] = PCM(t, M, 2, netMatrix_Delay, netMatrix_Cost, Delay_QoS, 10000000);

%% prepare final output
U = PCM_U;
C=[];
for j=1:M
    C=[C PCM_centers(j).id];
end;
end




