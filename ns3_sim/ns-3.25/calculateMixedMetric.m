function mixed_metric = calculateMixedMetric(delay, cost, delay_qos, cost_qos)
mixed_metric = 0;
l=2;
e=0.5;
mu = 0.5*((delay/delay_qos)^l + (cost/cost_qos)^l);
delta = ((delay/delay_qos)^l - mu)^2 + ((cost/cost_qos)^l - mu)^2;

mixed_metric = mu*(delta + e);
% mixed_metric=max([delay/delay_qos cost/cost_qos]); %k=inf
end