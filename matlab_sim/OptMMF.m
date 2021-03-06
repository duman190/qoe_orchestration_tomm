function [success_ratio, problem, result] = OptMMF(t, Budget, NetMatrix, BW_QoS, Delay_QoS, Cost_QoS)
% t - topo
% M - budget (or number )
% NetMatrix - edge weights based on Routing Policy of InPs
% BW_QoS, Delay_QoS, Cost_QoS - link/path SLO constraints

N = t.getNodeNumber; 
M = 999999; %arbitrary large number 
%% objective
f1 = zeros(1,N); % no x mappings in objective
f2 = zeros(1,N^2); % no path mappings in objective
f3 = -1*ones(1,N); % only coverage vars in objective (-1 as we minimizing);
problem.f = [f1 f2 f3];

%% vars
problem.lb = zeros(length(problem.f),1); % lower bound is 0  
problem.ub = ones(length(problem.f),1); % upper bound is 1
problem.intcon = ones(length(problem.f),1); % all vars are integer

%% constraints
%Budget constraint (max number of service instances)
problem.Aineq = [ones(1,length(f1)) zeros(1,length(f2)) zeros(1,length(f3))];
problem.bineq = Budget;

%User assignment constraints
problem.Aeq = zeros(N,length(problem.f));
problem.beq = ones(N,1);
for j=1:N
    problem.Aeq(j,N + j:N:N^2) = 1; %CAN BE WRONG!
end;

%Linking constraints
Alink = zeros(N,length(problem.f));
problem.bineq = [problem.bineq; zeros(N,1)];
for i=1:N
    Alink(i,i) = -N;
    for j=1:N
        f = (i-1)*N + j;
        Alink(i, N + f) = 1;
    end;
end;
problem.Aineq = [problem.Aineq; Alink];

[bw_matrix, delay_matrix, cost_matrix] = computePathMatrices(NetMatrix, t, M);
% BW (Link) SLO constraints
Abw = zeros(N,length(problem.f));
problem.bineq = [problem.bineq; zeros(N,1)];
for j=1:N
    Abw(j,N + N^2 + j) = BW_QoS;
    for i=1:N
        f = (i-1)*N + j;
        Abw(i, N + f) = -bw_matrix(i,j);
    end;
end;
problem.Aineq = [problem.Aineq; Abw];

% Delay (Path) SLO constraints
Adelay = zeros(N,length(problem.f));
problem.bineq = [problem.bineq; Delay_QoS*ones(N,1)];
for j=1:N
    Adelay(j,N + N^2 + j) = -M;
    for i=1:N
        f = (i-1)*N + j;
        Adelay(i, N + f) = delay_matrix(i,j);
    end;
end;
problem.Aineq = [problem.Aineq; Adelay];

% Cost (Path) SLO constraints
Acost = zeros(N,length(problem.f));
problem.bineq = [problem.bineq; Cost_QoS*ones(N,1)];
for j=1:N
    Adelay(j,N + N^2 + j) = -M;
    for i=1:N
        f = (i-1)*N + j;
        Acost(i, N + f) = cost_matrix(i,j);
    end;
end;

%other parameters
problem.Aineq = [problem.Aineq; Acost];
problem.solver = 'intlinprog';
problem.options = optimoptions('intlinprog');

%solve MMF with mixed-integer programming
[result,success_ratio] = intlinprog(problem);
end

function [bw_matrix, delay_matrix, cost_matrix] = computePathMatrices(NetMatrix, t, M)
N = t.getNodeNumber;
bw_matrix = zeros(N);
delay_matrix = zeros(N);
cost_matrix = zeros(N);
for i=1:N    
    bw_matrix(i,i) = M;
    delay_matrix(i,i) = 0;
    cost_matrix(i,i) = 0;
    if i<N %compute paths' bw, delay and cost
        j=i+1:N;
        [paths, ~] = dijkstraBulk(NetMatrix, i, j);
        for l = 1:length(j)
            [bw, delay, cost] = computePathWeights(t, paths{l}, M);
            bw_matrix(i,j(l)) = bw;
            bw_matrix(j(l),i) = bw;
            delay_matrix(i,j(l)) = delay;
            delay_matrix(j(l),i) = delay;
            cost_matrix(i,j(l)) = cost;
            cost_matrix(j(l),i) = cost;
        end;
        if rem(i,25) == 0
            fprintf('[OPTIMAL MMF] All path weights were calculated for node[%d]!\n',i);
        end;
    end;
end;
end

function [bw, delay, cost] = computePathWeights(t, path, M)
if ~isempty(path)
    delay = 0;
    cost = 0;
    bw = M;
    nodes = t.nodes;
    edges = t.edges;    
    N = length(path);
    for i=1:N-1
        src = nodes(path(i));
        dst = nodes(path(i+1));
        edge = edges(src.neighbors.get(dst.id));
        
        delay = delay + edge.delay;
        cost = cost + edge.cost;
        if bw > edge.bw
            bw = edge.bw;
        end;
    end;
else
    bw = 0;
    delay = M;
    cost = M;
end;
end