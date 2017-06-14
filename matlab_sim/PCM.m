function [U, centers, Dist1, Dist2] = PCM(t, M, m, NetMatrix_Delay, NetMatrix_Cost, Delay_QoS, Cost_QoS)
%X is the input data, Each row is a data point
%M is the number of clusters
%m - fuzzyfier
nodes = t.nodes;
%Parameters
MaxIter = 50;


%Initialize Cluster Centers by drawing Randomly from Data (can use other
%methods for initialization...)
N = t.getNodeNumber;    %number of data points

%assign centers randomly
centers = nodes(randperm(N,M)); %rewrite for general case

iter = 0;

%Choose eta = distance at which u=0.5
eta1= (sqrt(0.5)*Delay_QoS)^2;
eta2= (sqrt(0.5)*Cost_QoS)^2;
needIteration = 1;
while(iter < MaxIter && needIteration)
    d=[];
    for i=1:M
        d = [d centers(i).id];
    end;

    %update membership values   
    Dist1 = calculateAllDistances(NetMatrix_Delay, centers, Delay_QoS);   
    D1 = Dist1.^2 + eta1;
    U1 = (eta1./D1).^(1/(m-1));
    
    Dist2 = calculateAllDistances(NetMatrix_Cost, centers, Cost_QoS);    
    D2 = Dist2.^2 + eta2;
    U2 = (eta2./D2).^(1/(m-1));
    
    %avoid NaN in U
    for i=1:M
        U1(centers(i).id,i) = 1;
        U2(centers(i).id,i) = 1;
    end;
   
    U = U1.*U2;        
       
    %Update cluster centers
    [isUpdated, newCenters, totalDistortion] = estimateNewCenters(U, Dist1, Dist2, NetMatrix_Delay, NetMatrix_Cost, centers);
    
    if isUpdated     
        centers = nodes(newCenters);        
    else
        needIteration = 0;
    end;

    %total distortion
    distortion = sum(totalDistortion);
    
    if distortion == 0 %all centers are disconnected from other nodes - try to choose different nodes randomly
        fprintf('Need to reinitialize nodes!\n');
        centers = nodes(randperm(N,M));
        needIteration = 1;
    end;
%     
    iter = iter+1;
end;


