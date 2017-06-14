function plots()
clear all;

%close all;

clc;

% waxman topo
load('res_topo100');
pcm_w = [PCM_success];
kmean_w = [KMean_success];
random_w = [Random_success];
clear PCM_success KMean_success Random_success;

load('res_topo100_2');
pcm_w = [pcm_w; PCM_success];
kmean_w = [kmean_w; KMean_success];
random_w = [random_w; Random_success];
clear PCM_success KMean_success Random_success;

load('res_topo100_3');
pcm_w = [pcm_w; PCM_success];
kmean_w = [kmean_w; KMean_success];
random_w = [random_w; Random_success];
clear PCM_success KMean_success Random_success;

% barabasi topo
load('res_topo100b');
pcm_b = [PCM_success];
kmean_b = [KMean_success];
random_b = [Random_success];
clear PCM_success KMean_success Random_success;

load('res_topo100b_2');
pcm_b = [pcm_b; PCM_success];
kmean_b = [kmean_b; KMean_success];
random_b = [random_b; Random_success];
clear PCM_success KMean_success Random_success;

load('res_topo100b_3');
pcm_b = [pcm_b; PCM_success];
kmean_b = [kmean_b; KMean_success];
random_b = [random_b; Random_success];
clear PCM_success KMean_success Random_success;

M = size(pcm_w,1);

pcm_w = [pcm_w ones(M,1)];
kmean_w = [kmean_w ones(M,1)];
random_w = [random_w ones(M,1)];
pcm_b = [pcm_b ones(M,1)];
kmean_b = [kmean_b ones(M,1)];
random_b = [random_b ones(M,1)];

N = size(pcm_w,2);

[pcm_w_avg, pcm_w_ci] = avg_ci(pcm_w);
[kmean_w_avg, kmean_w_ci] = avg_ci(kmean_w);
[random_w_avg, random_w_ci] = avg_ci(random_w);

[pcm_b_avg, pcm_b_ci] = avg_ci(pcm_b);
[kmean_b_avg, kmean_b_ci] = avg_ci(kmean_b);
[random_b_avg, random_b_ci] = avg_ci(random_b);


fsize=36;
fsize_legend = 36;
fsize_axis = 36;
fname = 'Times New Roman';

figure;
hold on;

h1=errorbar(1:N,1.001-pcm_w_avg, pcm_w_ci, 'color',[0,0,0]+0,'LineWidth',4,'LineStyle','-','Marker','^','MarkerSize',15, 'MarkerFaceColor', 'w');
h2=errorbar(1:N,1.001-pcm_b_avg, pcm_b_ci, 'color',[0,0,0]+0.5,'LineWidth',4,'LineStyle','-','Marker','^','MarkerSize',15, 'MarkerFaceColor', [0,0,0]+0.5);
h3=errorbar(1:N,1.001-kmean_w_avg, kmean_w_ci, 'color',[0,0,0]+0,'LineWidth',4,'LineStyle','-.','Marker','s','MarkerSize',15, 'MarkerFaceColor', 'w');
h4=errorbar(1:N,1.001-kmean_b_avg, kmean_b_ci, 'color',[0,0,0]+0.5,'LineWidth',4,'LineStyle','-.','Marker','s','MarkerSize',15, 'MarkerFaceColor', [0,0,0]+0.5);
h5=errorbar(1:N,1.001-random_w_avg, random_w_ci, 'color',[0,0,0]+0,'LineWidth',4,'LineStyle','--','Marker','o','MarkerSize',15, 'MarkerFaceColor', 'w');
h6=errorbar(1:N,1.001-random_b_avg, random_b_ci, 'color',[0,0,0]+0.5,'LineWidth',4,'LineStyle','--','Marker','o','MarkerSize',15, 'MarkerFaceColor', [0,0,0]+0.5);

xlim([0.85 N+0.25])
ylim([0 1.05])

set(gca,'Xtick',linspace(1,N,N))
set(gca,'Ytick',[0.001 0.011 0.101 0.501 1.001])

set(gca,'XTickLabel', {'1','2', '5', '10', '25', '50', '100'});
set(gca,'YtickLabel', {'1','0.99','0.9','0.5', '0'})

set(gca,'Ydir','reverse','Yscale','log')

%grid on;

xlabel(sprintf('# of clusters'),'fontname',fname,'fontsize',fsize);
ylabel(sprintf('success ratio'),'fontname','Times New Roman','fontsize',fsize);





legend('PCM, W','PCM, B','K-Means, W','K-Means, B', 'Blind, W', 'Blind, B');
set(legend,'Location','southeast');
% set(legend,'Orientation','horizontal');
%legend boxoff;

set(gca,'fontname',fname);
set(gca,'fontsize',fsize_axis);

set(legend,'fontname',fname);
set(legend,'fontsize',fsize_legend);
return

function [myavg, CI] = avg_ci(X)
myavg = sum(X)/size(X, 1);
CI = 1.96.*(std(X)./sqrt(size(X, 1)));

%1.96 - 95%
%2.33 - 98%
%2.58 - 99%
return