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
BW_QoS = 2.5;%2;%15 %Mbps
Delay_QoS = sqrt(2)*150; % 75-high 112,5-mid 150-low
Cost_QoS = 12;          % 9-high  13,5-mid  18-low
M=[1 2 5 10 25 50]; %  
maxIter = 15;

for name_i=1:length(names)
    %% - variables to store results
    PCM_success = zeros(maxIter, length(M), 3);
    KMean_success = zeros(maxIter, length(M), 3);
    KMean_Delay_success = zeros(maxIter, length(M), 3);
    KMean_Cost_success = zeros(maxIter, length(M), 3);
    KMean_Geo_success = zeros(maxIter, length(M), 3);
    Random_success = zeros(maxIter, length(M), 3);
    
    %% - load topo
    load(names{name_i});   
    N = t.getNodeNumber;   
    
    %% - different network topos
    netMatrix_Cost = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'cost_qos');
    netMatrix_Delay = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'delay_qos');
    netMatrix = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'bw_qos');
    netMatrix_Mixed = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'mixed_qos');
    netMatrix_OSPF = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'ospf');
    netMatrix_RIP = topo_to_matrix(t, BW_QoS, Delay_QoS, Cost_QoS, 'no_qos');
    
    
    
    %% - main cycle
    tic;
    for m=1:length(M)
        for iter=1:maxIter
            fprintf('# of clusters = %d, iteration = %d, topo_name = %s.\n', M(m), iter, names{name_i});
            
            %% PCM
            [PCM_U, PCM_centers, ~, ~] = PCM(t, M(m), 2, netMatrix_Delay, netMatrix_Cost, Delay_QoS, Cost_QoS);
            
            %cluster nodes while removing all nodes with 0 probability
            PCM_I = find(sum(PCM_U, 2)>0);
            %length(I)
            PCM_Unew = PCM_U(PCM_I,:);
            %
            [~, PCM_Inew] = max(PCM_Unew,[],2);
            %cluster
            PCM_C=zeros(N,1);
            for i=1:M(m)
                PCM_C(PCM_I(PCM_Inew==i))=i;
            end;
            
            %% K-Mean
            [U, centers] = KMean(t, M(m), netMatrix);
            
            %cluster nodes while removing all nodes with 0 probability
            I = find(sum(U, 2)>0);
            %length(I)
            Unew = U(I,:);
            %
            [~, Inew] = max(Unew,[],2);
            %cluster
            C=zeros(N,1);
            for i=1:M(m)
                C(I(Inew==i))=i;
            end;
            
            %% K-Mean Delay
            [Delay_U, Delay_centers] = KMean(t, M(m), netMatrix_Delay);
            
            %cluster nodes while removing all nodes with 0 probability
            Delay_I = find(sum(Delay_U, 2)>0);
            %length(I)
            Delay_Unew = Delay_U(Delay_I,:);
            %
            [~, Delay_Inew] = max(Delay_Unew,[],2);
            %cluster
            Delay_C=zeros(N,1);
            for i=1:M(m)
                Delay_C(Delay_I(Delay_Inew==i))=i;
            end;
            
            %% K-Mean Cost
            [Cost_U, Cost_centers] = KMean(t, M(m), netMatrix_Cost);
            
            %cluster nodes while removing all nodes with 0 probability
            Cost_I = find(sum(Cost_U, 2)>0);
            %length(I)
            Cost_Unew = Cost_U(Cost_I,:);
            %
            [~, Cost_Inew] = max(Cost_Unew,[],2);
            %cluster
            Cost_C=zeros(N,1);
            for i=1:M(m)
                Cost_C(Cost_I(Cost_Inew==i))=i;
            end;
            
            %% K-Mean Geo
            [Geo_U, Geo_centers] = KMean_Geo(t, M(m));
            
            %cluster nodes while removing all nodes with 0 probability
            Geo_I = find(sum(Geo_U, 2)>0);
            %length(I)
            Geo_Unew = Geo_U(Geo_I,:);
            %
            [~, Geo_Inew] = max(Geo_Unew,[],2);
            %cluster
            Geo_C=zeros(N,1);
            for i=1:M(m)
                Geo_C(Geo_I(Geo_Inew==i))=i;
            end;
            
            %% Random model
            c_centers = t.nodes(randperm(N,M(m)));
            c_cen = [];
            for i=1:M(m)
                c_cen = [c_cen c_centers(i).id];
            end;
            
            %% estimate performance
            fprintf('Clusters were estimated. Routing starts now!\n');
            
            success_ratio = zeros(6,1,3);
            
            
            for i=1:N
                %% - pick PCM model destination based on clusterization results
                dst0 = 0;
                if PCM_C(i) == 0
                    min_dist = Inf;
                    for j=1:M(m)
                        dist = sqrt((t.nodes(i).x - PCM_centers(j).x)^2 + (t.nodes(i).y - PCM_centers(j).y)^2);
                        if dist<min_dist
                            dst0=PCM_centers(j).id;
                            min_dist=dist;
                        end;
                    end;
                else
                    dst0=PCM_centers(PCM_C(i)).id;
                end;
                
                %% - pick K-Mean model destination based on clusterization results
                dst1 = 0;
                if C(i) == 0
                    min_dist = Inf;
                    for j=1:M(m)
                        dist = sqrt((t.nodes(i).x - centers(j).x)^2 + (t.nodes(i).y - centers(j).y)^2);
                        if dist<min_dist
                            dst1=centers(j).id;
                            min_dist=dist;
                        end;
                    end;
                else
                    dst1=centers(C(i)).id;
                end;
                
                %% - pick K-Mean model destination based on delay clusterization results
                dst2 = 0;
                if Delay_C(i) == 0
                    min_dist = Inf;
                    for j=1:M(m)
                        dist = sqrt((t.nodes(i).x - centers(j).x)^2 + (t.nodes(i).y - centers(j).y)^2);
                        if dist<min_dist
                            dst2=Delay_centers(j).id;
                            min_dist=dist;
                        end;
                    end;
                else
                    dst2=Delay_centers(Delay_C(i)).id;
                end;
                
                %% - pick K-Mean model destination based on cost clusterization results
                dst3 = 0;
                if Cost_C(i) == 0
                    min_dist = Inf;
                    for j=1:M(m)
                        dist = sqrt((t.nodes(i).x - centers(j).x)^2 + (t.nodes(i).y - centers(j).y)^2);
                        if dist<min_dist
                            dst3=Cost_centers(j).id;
                            min_dist=dist;
                        end;
                    end;
                else
                    dst3=Cost_centers(Cost_C(i)).id;
                end;
                
                %% - pick K-Mean model destination based on geo-clusterization results
                dst4 = Geo_centers(Geo_C(i)).id;
                
                %% - pick Random model destination based on geographical location
                dst5=0;
                min_dist = Inf;
                for j=1:M(m)
                    dist = sqrt((t.nodes(i).x - c_centers(j).x)^2 + (t.nodes(i).y - c_centers(j).y)^2);
                    if dist<min_dist
                        dst5=c_centers(j).id;
                        min_dist=dist;
                    end;
                end;
                
                %% - estimate paths of different models using MCP path algorithm
                dst = [];
                alg = []; % 1 - means PCM, 2 - K-Mean, etc.
                %PCM
                if i==dst0
                    success_ratio(1,:,:) = success_ratio(1,:,:) + 1;
                else
                    dst = [dst dst0];
                    alg = [alg 1];
%                     [shortestPath0, ~] = dijkstra(netMatrix_Mixed, i, dst0);
%                     success_ratio0 = success_ratio0 + estimatePath(t, shortestPath0, Delay_QoS, Cost_QoS);
                end;
                %K-Mean
                if i==dst1
                    success_ratio(2,:,:) = success_ratio(2,:,:) + 1;
                else
                    dst = [dst dst1];
                    alg = [alg 2];
%                     [shortestPath1, ~] = dijkstra(netMatrix_Mixed, i, dst1);
%                     success_ratio1 = success_ratio1 + estimatePath(t, shortestPath1, Delay_QoS, Cost_QoS);
                end;
                %K-Mean Delay
                if i==dst2
                    success_ratio(3,:,:) = success_ratio(3,:,:) + 1;
                else
                    dst = [dst dst2];
                    alg = [alg 3];
%                     [shortestPath2, ~] = dijkstra(netMatrix_Mixed, i, dst2);
%                     success_ratio2 = success_ratio2 + estimatePath(t, shortestPath2, Delay_QoS, Cost_QoS);
                end;
                %K-Mean Cost
                if i==dst3
                    success_ratio(4,:,:) = success_ratio(4,:,:) + 1;
                else
                    dst = [dst dst3];
                    alg = [alg 4];
%                     [shortestPath2, ~] = dijkstra(netMatrix_Mixed, i, dst2);
%                     success_ratio2 = success_ratio2 + estimatePath(t, shortestPath2, Delay_QoS, Cost_QoS);
                end;
                %K-Mean Cost
                if i==dst4
                    success_ratio(5,:,:) = success_ratio(5,:,:) + 1;
                else
                    dst = [dst dst4];
                    alg = [alg 5];
%                     [shortestPath2, ~] = dijkstra(netMatrix_Mixed, i, dst2);
%                     success_ratio2 = success_ratio2 + estimatePath(t, shortestPath2, Delay_QoS, Cost_QoS);
                end;
                %Random
                if i==dst5
                    success_ratio(6,:,:) = success_ratio(6,:,:) + 1;
                else
                    dst = [dst dst5];
                    alg = [alg 6];
%                     [shortestPath3, ~] = dijkstra(netMatrix_Mixed, i, dst3);
%                     success_ratio3 = success_ratio3 + estimatePath(t, shortestPath3, Delay_QoS, Cost_QoS);
                end;
                
                % routing with PCM
                [shortestPathPCM, ~] = dijkstraBulk(netMatrix_Mixed, i, dst);
                % routing with OSPF
                [shortestPathOSPF, ~] = dijkstraBulk(netMatrix_OSPF, i, dst);
                % routing with RIP
                [shortestPathRIP, ~] = dijkstraBulk(netMatrix_RIP, i, dst);
                % paths estimation
                for p=1:length(shortestPathPCM)
                    success_ratio(alg(p),:,1) = success_ratio(alg(p),:,1) + estimatePath(t, shortestPathPCM{p}, Delay_QoS, Cost_QoS); % estimate PCM
                    success_ratio(alg(p),:,2) = success_ratio(alg(p),:,2) + estimatePath(t, shortestPathOSPF{p}, Delay_QoS, Cost_QoS); % estimate OSPF
                    success_ratio(alg(p),:,3) = success_ratio(alg(p),:,3) + estimatePath(t, shortestPathRIP{p}, Delay_QoS, Cost_QoS); % estimate RIP
                end;
                
                %display progress
                if rem(i,25) == 0
                    fprintf('Routing was done, and all paths are estimated for node[%d]!\n',i);
                end;
            end;
            
            %% - outline results
            success_ratio=success_ratio./N;
%             success_ratio1=success_ratio1/N;
%             success_ratio2=success_ratio2/N;
%             success_ratio3=success_ratio3/N;
            
            fprintf('Success ratio of PCM routing: PCM=%g, KMean=%g, KMeanDelay=%g, KMeanCost=%g, KMeanGeo=%g, Random=%g.\n',success_ratio(:,1,1));
            fprintf('Success ratio of OSPF routing: PCM=%g, KMean=%g, KMeanDelay=%g, KMeanCost=%g, KMeanGeo=%g, Random=%g.\n',success_ratio(:,1,2));
            fprintf('Success ratio of RIP routing: PCM=%g, KMean=%g, KMeanDelay=%g, KMeanCost=%g, KMeanGeo=%g, Random=%g.\n',success_ratio(:,1,3));
            
            PCM_success(iter, m, :) = success_ratio(1,:,:);
            KMean_success(iter, m, :) = success_ratio(2,:,:);
            KMean_Delay_success(iter, m, :) = success_ratio(3,:,:);
            KMean_Cost_success(iter, m, :) = success_ratio(4,:,:);
            KMean_Geo_success(iter, m, :) = success_ratio(5,:,:);
            Random_success(iter, m, :) = success_ratio(6,:,:);
        end;
    end;
    res_filename = strcat('new_res_',names{name_i});    
    fprintf('Clusterization has been finished for topo_name = %s in %g hours. Saving results to %s.\n',names{name_i}, toc/3600, res_filename);
    save(res_filename, 'PCM_success', 'KMean_success','KMean_Delay_success', 'KMean_Cost_success', 'KMean_Geo_success', 'Random_success');
    clear t;
end;