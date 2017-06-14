function Dist = calculateAllDistancesNoConstraint(NetMatrix, centers)
N = size(NetMatrix, 1);
M = length(centers);
Dist = Inf(N,M);

%convert centers to dsts
d=[];
for i=1:M
    d = [d centers(i).id]; 
end;

%calculate distances
for i=1:N
    [~, totalCost] = dijkstraBulk(NetMatrix, i, d);
    for j=1:M
        if i==d(j)
            Dist(i,j) = 0;
        else
            Dist(i,j) = totalCost(j);
        end;
    end;
    if rem(i,50) == 0
        fprintf('[KMean] All distances were calculated for node[%d]!\n',i);
    end;
end