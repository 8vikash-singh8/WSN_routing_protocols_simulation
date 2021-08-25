% Here the nodes are initialized with
% initial energy , random network locations
% and other node specific properties.

function network = initializeNetwork()

network.numberOfNodes = 100;
network.nodeRange = 25 ;
network.needPlot = 0 ;

% Length in metres. sensor nodes lies in between (0,0) & (max_Length_X , max_Length_Y).
maxLength_X = 100;
maxLength_Y = 100;

% sink or BS is located outside the area of sensor nodes.
network.sink_X = 50;
network.sink_Y = 200;

	% initializing sensor nodes properties.
	for i = 1:network.numberOfNodes

		network.node(i).loc_X = rand(1,1) * maxLength_X ;
		network.node(i).loc_Y = rand(1,1) * maxLength_Y ;
		network.node(i).energy = 0.5;
		network.node(i).isAlive = 1;
		network.node(i).wasClusterHead = 0;
		network.node(i).clusterRound = 0;
	end
	
	return ;
end
