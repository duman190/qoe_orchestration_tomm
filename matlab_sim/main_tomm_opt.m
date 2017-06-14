clc;
clear all;
close all;
names = cell(1,1);
names{1}='topo100';
% names{2}='topo100_2';
% names{3}='topo100_3';
% names{4}='topo100b';
% names{5}='topo100b_2';
% names{6}='topo100b_3';

%% - properties
%BW_QoS = 2.5;%2;%15 %Mbps
%Delay_QoS = sqrt(2)*150; % 75-high 112,5-mid 150-low
%Cost_QoS = 12;          % 9-high  13,5-mid  18-low
M=[2]; % budget 1 2 5 10 25 50

%for custom topo
BW_QoS = 15; %Mbps
Delay_QoS = 50; %Maximum possible delay of an edge
Cost_QoS = -log(0.9995);

for name_i=1:length(names)
    %% - variables to store results
    opt_success = zeros(length(M), 3);
    
    %% - load topo
    %load(names{name_i});   
    t = custom_topo();
    N = t.getNodeNumber;   
    
    %% - different network topos
    netMatrix_Mixed = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'mixed_qos');
    netMatrix_OSPF = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'ospf');
    netMatrix_RIP = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'no_qos');  
    
    %% - main cycle
    tic;
    for m=1:length(M)
        for j=1:1 
            if j==1
                policy='MCP';
                NetMatrix = netMatrix_Mixed;
            elseif j==2
                policy='OSPF';
                NetMatrix = netMatrix_OSPF;
            else
                policy='RIP';
                NetMatrix = netMatrix_RIP;
            end;                
            fprintf(strcat('# of clusters = %d, routing policy:',policy,', topo_name = %s.\n'), M(m), names{name_i});  
            
            % - solve opt problem formulation
            [opt_success(m,j), problem, result] = OptMMF(t, M(m), NetMatrix, BW_QoS, Delay_QoS, Cost_QoS);
            
            % - outline results
            opt_success(m,j) = opt_success(m,j)/N;            
            fprintf(strcat('Success ratio of ',policy,' routing: %g.\n'),opt_success(m,j));
        end;
    end;
end;