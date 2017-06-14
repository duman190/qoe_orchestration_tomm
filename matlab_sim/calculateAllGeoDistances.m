function Dist = calculateAllGeoDistances(nodes, centers)
N = size(nodes, 1);
M = length(centers);
Dist = Inf(N,M);

%calculate distances
for i=1:N
    for j=1:M
       Dist(i,j) = sqrt((nodes(i).x - centers(j).x)^2 + (nodes(i).y - centers(j).y)^2);
    end;
    if rem(i,50) == 0
        fprintf('[KMean-Geo] All distances were calculated for node[%d]!\n',i);
    end;
end