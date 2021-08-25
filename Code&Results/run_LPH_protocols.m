% This is the start point of our simulation where
% all protocols run and save their statistics to be analyzed
% using graphs.

clc;
clear;
clear all;

network = initializeNetwork();    % The network is initialized.

stats = initializeStats(network.numberOfNodes);    	% The statistics variables are initialized

stats = leach(network,stats);	% leach protocol runs on the network and save its stats 

stats = pegasis(network,stats);	% pegasis protocol runs on the network and save its stats 

stats = heed(network,stats);	% heed protocol runs on the network and save its stats 

plotGraphs(network.numberOfNodes,stats);		% Graphs are plotted using the saved stats
