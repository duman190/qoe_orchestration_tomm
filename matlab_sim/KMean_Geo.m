function [U, centers] = KMean_Geo(t, M)
%X is the input data, Each row is a data point
%M is the number of clusters
%m - fuzzyfier
nodes = t.nodes;
%Parameters
MaxIter = 50;

N = t.getNodeNumber;    %number of data points

centers = nodes(randperm(N,M)); %rewrite for general case

iter = 0;

%Choose eta = distance at which u=0.5
needIteration = 1;
while(iter < MaxIter && needIteration)
    d=[];
    for i=1:M
        d = [d centers(i).id];
    end;

    %update membership values   
    Dist = calculateAllGeoDistances(nodes, centers);   
    U = zeros(N,M);
    [~, minC] = min(Dist,[],2);    
    for i=1:length(minC)
        U(i,minC(i)) = 1;
    end;
       
         
    %Update cluster centers
    [isUpdated, newCenters, totalDistortion] = estimateNewGeoKCenters(U, Dist, nodes, centers);
    
    if isUpdated     
        centers = nodes(newCenters);        
    else
        needIteration = 0;
    end;

    %total distortion
    distortion = sum(totalDistortion);
%     
    iter = iter+1;
end;


