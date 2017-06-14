function [U, centers] = KMean(t, M, NetMatrix)
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
    Dist = calculateAllDistancesNoConstraint(NetMatrix, centers);   
    U = zeros(N,M);
    [maxC, minC] = min(Dist,[],2);    
    for i=1:length(minC)
        if(maxC(i)~=Inf)
        U(i,minC(i)) = 1;
        end;
    end;
       
         
    %Update cluster centers
    [isUpdated, newCenters, totalDistortion] = estimateNewKCenters(U, Dist, NetMatrix, centers);
    
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


