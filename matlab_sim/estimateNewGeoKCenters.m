function [isUpdated, newCenters, totalDistortion] = estimateNewGeoKCenters(U, Dist, nodes, centers)
%No of clusters
M = length(centers);
%convert centers to dsts
d=[];
for i=1:M
    d = [d centers(i).id];
end;

%cluster nodes while removing all nodes with 0 probability
I = find(sum(U, 2)>0);
%length(I)
Unew = U(I,:);
%
[~, Inew] = max(Unew,[],2);

%cluster and calculate total distortion
C=cell(M,1);
totalDistortion = zeros(M,1);
for i=1:M
    C{i} = I(Inew==i);
    Distortion = sum(Dist(C{i}, i));
        
    %total normilized distortion
    if Distortion > 0
        totalDistortion(i) = Distortion/max(Dist(C{i}, i));
    end;
end;

%estimate centers
isUpdated=0;
newCenters = d;
for i=1:M
    N = length(C{i});
    minTotalDistortion = totalDistortion(i);
    fprintf('[KMean-Geo] Current distortion of cluster[%d]=%g \n',i, minTotalDistortion);
    for j=1:N
        if C{i}(j)~=d(i)
            %find distnaces to all other vertices
            totalCost = calculateAllGeoDistances(nodes(C{i}(j)), nodes(C{i}));
            Distortion = sum(totalCost);
            
            %new total normilized distortion
            newTotalDistortion = 0;
            if Distortion > 0
                newTotalDistortion = Distortion/max(Dist(C{i}, i));
            end;
            
            if newTotalDistortion < minTotalDistortion
                minTotalDistortion = newTotalDistortion;
                newCenters(i) = C{i}(j);
                isUpdated=1;
                fprintf('[KMean-Geo] Found a min distortion of node[%d]=%g !!!\n',C{i}(j), newTotalDistortion);
%             else
%                 fprintf('Distortion of node[%d]=%g \n',C{i}(j), newTotalDistortion);
            end;
        end;        
    end;
end;