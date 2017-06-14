function [isUpdated, newCenters, totalDistortion] = estimateNewCenters(U, Dist1, Dist2, NetMatrix_Delay, NetMatrix_Cost, centers)
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
    Distortion1 = sum(Dist1(C{i}, i));
    Distortion2 = sum(Dist2(C{i}, i));
    
    %total normilized distortion
    if Distortion1 + Distortion2 > 0
        totalDistortion(i) = Distortion1/max(Dist1(C{i}, i)) +...
            Distortion2/max(Dist2(C{i}, i));
    end;
end;

%estimate centers
isUpdated=0;
newCenters = d;
for i=1:M
    N = length(C{i});
    minTotalDistortion = totalDistortion(i);
    fprintf('[PCM] Current distortion of cluster[%d]=%g \n',i, minTotalDistortion);
    for j=1:N
        if C{i}(j)~=d(i)
            %find distnaces to all other vertices
            [~, totalCost1] = dijkstraBulk(NetMatrix_Delay, C{i}(j), C{i});
            Distortion1 = sum(totalCost1);
            [~, totalCost2] = dijkstraBulk(NetMatrix_Cost, C{i}(j), C{i});
            Distortion2 = sum(totalCost2);
            
            %new total normilized distortion
            newTotalDistortion = 0;
            if Distortion1 + Distortion2 > 0
                newTotalDistortion = Distortion1/max(Dist1(C{i}, i)) +...
                    Distortion2/max(Dist2(C{i}, i));
            end;
            
            if newTotalDistortion < minTotalDistortion
                minTotalDistortion = newTotalDistortion;
                newCenters(i) = C{i}(j);
                isUpdated=1;
                fprintf('[PCM] Found a min distortion of node[%d]=%g !!!\n',C{i}(j), newTotalDistortion);
%             else
%                 fprintf('Distortion of node[%d]=%g \n',C{i}(j), newTotalDistortion);
            end;
        end;        
    end;
end;