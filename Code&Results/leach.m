% Implementation of LEACH protocol.

function stats = leach( network , stats )

	elecEnergy = 50*(10^-9); % electronics energy loss per bit.
	fsEnergy = 10*(10^-12); % freespace energy loss per bit.
	mpEnergy = 13*(10^-16); % multipath energy loss per bit.
	aggrEnergy = 5*(10^-9); % data aggregation energy loss per bit.
	
	totalEnergy = network.numberOfNodes * network.node(1).energy; % total energy of the network initially.
	
	deadNodes = 0; % To store number of dead nodes.
	roundNum = 0;% To store number of rounds this protocol runs.
	
	packetLength = 2000; % Length of a packet in bits.
	
	crossoverDist = sqrt(fsEnergy/mpEnergy); % crossover distance defined as square root of ratio of freespace to multipath energy
	
	distanceNodes = zeros(network.numberOfNodes,network.numberOfNodes); % To store distance between each node.
	distanceBS = zeros(1,network.numberOfNodes); % To store distance between each node and Base Station.
	
	p = 0.05; % Desired percentage of cluster heads to be formed in each round
	clusterRound = round(1/p) ; % Number of rounds after which a node can again become cluster head.
	
	% Plotting initial network for visualization of nodes and sink.
	if(network.needPlot == 1)
		h = figure(5);
		hold("on");
		grid("on");
		plot(network.sink_X,network.sink_Y,'o','MarkerSize',8,'MarkerFaceColor','b');
		for i=1:network.numberOfNodes
			plot(network.node(i).loc_X,network.node(i).loc_Y,'o','MarkerSize',8,'MarkerFaceColor','r');
		end
	end
	
	% function to reduce energy of node 'i' on transmission of 'l' packets for a distance 'd'.
	function transmitLoss(i,l,d)
		
		if(network.node(i).isAlive == 1)
			lastKnownEnergy = network.node(i).energy;
			
			if(d < crossoverDist)
				network.node(i).energy -= (l*packetLength*(elecEnergy + (fsEnergy*d^2)));
			else
				network.node(i).energy -= (l*packetLength*(elecEnergy + (mpEnergy*d^4)));
			end
			
			if( network.node(i).energy <= 0)
				network.node(i).energy = 0;
				network.node(i).isAlive = 0;
				deadNodes += 1;
				distanceNodes(:,i) = 9999;
			end
			
			totalEnergy -= (lastKnownEnergy - network.node(i).energy) ;
		end
	end
	
	% function to reduce energy of node 'i' on receiving 'l' packets.
	function receiveLoss(i,l)
		
		if(network.node(i).isAlive == 1)
			lastKnownEnergy = network.node(i).energy;
			network.node(i).energy -= (double(l*packetLength)*elecEnergy);
		
			if( network.node(i).energy <= 0)
				network.node(i).energy = 0;
				network.node(i).isAlive = 0;
				deadNodes += 1;
				distanceNodes(:,i) = 9999;
			end
			
			totalEnergy -= (lastKnownEnergy - network.node(i).energy) ;
		end
	end
	
	% function to reduce energy of node 'i' on aggregation of 'l' packets.
	function aggregateLoss(i,l)
		
		if(network.node(i).isAlive == 1)
			lastKnownEnergy = network.node(i).energy;
			network.node(i).energy -= (double(l*packetLength)*aggrEnergy);
			
			if( network.node(i).energy <= 0)
				network.node(i).energy = 0;
				network.node(i).isAlive = 0;
				deadNodes += 1;
				distanceNodes(:,i) = 9999;
			end
			
			totalEnergy -= (lastKnownEnergy - network.node(i).energy) ;
		end			
	end
	
	% Plot the network with active nodes,sink,cluster heads and dead nodes.
	function plotNetwork()
		for i=1:network.numberOfNodes
			if(network.node(i).isAlive == 1)
				if(network.node(i).clusterRound == roundNum)
					plot(network.node(i).loc_X,network.node(i).loc_Y,'o','MarkerSize',8,'MarkerFaceColor','g');
				else
					plot(network.node(i).loc_X,network.node(i).loc_Y,'o','MarkerSize',8,'MarkerFaceColor','r');
				end
			else
				plot(network.node(i).loc_X,network.node(i).loc_Y,'o','MarkerSize',8,'MarkerFaceColor','k');
			end
		end	
		refresh(h);
	end
	
	% Calculating and storing distances from each node to other node and base station.
	for i=1:network.numberOfNodes
		
		distanceBS(i) = sqrt((network.node(i).loc_X - network.sink_X)^2 + (network.node(i).loc_Y - network.sink_Y)^2);
		
		for j=i:network.numberOfNodes
			if(i==j)
				distanceNodes(i,j) = 9999;
			else
				distanceNodes(i,j) = sqrt((network.node(i).loc_X - network.node(j).loc_X)^2 + ...
				 				(network.node(i).loc_Y - network.node(j).loc_Y)^2);
				distanceNodes(j,i) = distanceNodes(i,j);
			end
		end
	end
	
	% stats at the start of protocol
	stats.leach.deadNodes(roundNum+1) = deadNodes ;
	stats.leach.totalResidualEnergy(roundNum+1) = totalEnergy ;
	stats.leach.residualEnergyPerNode(:,roundNum+1) = network.node(1).energy ;
	
	% protocol runs until every node dies.
	while(deadNodes < network.numberOfNodes)
	
		roundNum += 1;
		
		printf("\nRound Number : %d\n",roundNum);
		
		% threshold value for this round below which a cluster head can be formed.
		thresholdValue = p/(1-(p*mod(roundNum-1 , clusterRound)))
		
		% making every node eligible for being a cluster head after every " clusterRound's ".
		if(mod(roundNum-1 , clusterRound)==0)
			for i=1:network.numberOfNodes
				network.node(i).wasClusterHead = 0;
			end
		end
		
		% creating cluster heads for this round.
		clusterHead.id = [];
		clusterHead.nodeCounts = [];
		clusterHeadIndex = 1 ;
		
		while(1)
			flag1 = 0;
			flag2 = 0;
			for i=1:network.numberOfNodes
			
				if(network.node(i).isAlive == 1 && network.node(i).wasClusterHead == 0)
					flag1 = 1 ;
					temp = rand(1,1);
					if(temp <= thresholdValue)
						flag2 = 1;
						clusterHead.id(clusterHeadIndex) = i;
						clusterHead.nodeCounts(clusterHeadIndex++) = 0 ;
						network.node(i).wasClusterHead = 1;
						network.node(i).clusterRound = roundNum;
					end
				end
			end
			
			if(flag2 == 1)
				break;
			end
			if(flag1 == 0)
				for i=1:network.numberOfNodes
					network.node(i).wasClusterHead = 0;
				end
			end
		end
		
		% Data transmission and dissipation of energy for non Cluster Heads.
		for i=1:network.numberOfNodes
		
			if(network.node(i).isAlive==1 && network.node(i).clusterRound != roundNum )
				[minDist,loc] = min(distanceNodes(i,clusterHead.id(:)));
				clusterHead.nodeCounts(loc) += 1;
				transmitLoss(i,1,minDist);
			end
			stats.leach.residualEnergyPerNode(i,roundNum+1) = network.node(i).energy ;
		end
				
		% Data transmission and dissipation of energy for Cluster Heads.
		for i=1:length(clusterHead.id)
			receiveLoss(clusterHead.id(i),clusterHead.nodeCounts(i));
			aggregateLoss(clusterHead.id(i),clusterHead.nodeCounts(i));
			transmitLoss(clusterHead.id(i),1,distanceBS(clusterHead.id(i)));
			stats.leach.residualEnergyPerNode(clusterHead.id(i),roundNum+1) = network.node(i).energy ;
		end
		
		if(deadNodes == network.numberOfNodes)
			stats.leach.maxRound = roundNum ; 
		end
		
		if(mod(deadNodes , 0.2*network.numberOfNodes)==0 && deadNodes > 1 && network.needPlot == 1)
			plotNetwork();
		end
		
		deadNodes
		totalEnergy	
		stats.leach.deadNodes(roundNum+1) = deadNodes ;
		stats.leach.totalResidualEnergy(roundNum+1) = totalEnergy ;
	end
	
	return ;
end
