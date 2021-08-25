%Implementation of HEED protocol.

function stats = heed( network , stats)

	elecEnergy = 50*(10^-9); % electronics energy loss per bit.
	fsEnergy = 10*(10^-12); % freespace energy loss per bit.
	mpEnergy = 13*(10^-16); % multipath energy loss per bit.
	aggrEnergy = 5*(10^-9); % data aggregation energy loss per bit.
	
	initialEnergy = network.node(1).energy;
	totalEnergy = network.numberOfNodes * network.node(1).energy; % total energy of the network initially.
	
	deadNodes = 0; % To store number of dead nodes.
	roundNum = 0;% To store number of rounds this protocol runs.
	
	packetLength = 2000 ; % Length of a packet in bits.
	clusterRange = network.nodeRange ; % distance upto which a cluster head is reachable to a node.
	iterations = 6 ; % number of iterations in selection of cluster heads.
	Pmin = 5*(10^-4); % minimum probability to be a cluster head.
	Cprob = 0.05; % initial probability of nodes to be cluster head.
	
	crossoverDist = sqrt(fsEnergy/mpEnergy); % crossover distance defined as square root of ratio of freespace to multipath energy
	
	distanceNodes = zeros(network.numberOfNodes,network.numberOfNodes); % To store distance between each node.
	distanceBS = zeros(1,network.numberOfNodes); % To store distance between each node and Base Station.
	
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
				distanceNodes(:,i) = 9999 ;
			end
			totalEnergy -= (lastKnownEnergy - network.node(i).energy);
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
			
			totalEnergy -= (lastKnownEnergy - network.node(i).energy);
		end
	end
	
	% function to reduce energy of node 'i' on aggregation of 'l' packets.
	function aggregateLoss(i,l)
		
		if(network.node(i).isAlive == 1)
			lastKnownEnergy = network.node(i).energy;
			network.node(i).energy -= (double(l*packetLength)*elecEnergy);
			
			if( network.node(i).energy <= 0)
				network.node(i).energy = 0;
				network.node(i).isAlive = 0;
				deadNodes += 1;
				distanceNodes(:,i) = 9999;
			end
			
			totalEnergy -= (lastKnownEnergy - network.node(i).energy);
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
	
	% Calculate Average Minimum Reachable Energy (AMRP) and Node Degree as cost for each node.
	function [AMRP,nodeDegree] = calculateCost(i)
		dist = distanceNodes(i,:);
		dist = dist( dist <= clusterRange);
		AMRP = 0;
		nodeDegree = length(dist);
		for j = 1:nodeDegree
			AMRP += (packetLength*(elecEnergy + (fsEnergy*dist(j)^2)));
		end
		if(nodeDegree != 0)
			AMRP /= nodeDegree;
		end
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
	stats.heed.deadNodes(roundNum+1) = deadNodes ;
	stats.heed.totalResidualEnergy(roundNum+1) = totalEnergy ;
	stats.heed.residualEnergyPerNode(:,roundNum+1) = network.node(1).energy;
	
	% protocol runs until every node dies.
	while(deadNodes < network.numberOfNodes)
	
		roundNum += 1;
		
		printf("\nRound Number : %d\n",roundNum);
		
		setOfTentativeCH = [];
		setOfFinalCH = [];
		nodeUnderCluster = zeros(1,network.numberOfNodes,'int16');
		nodeCountUnderCH = zeros(1,network.numberOfNodes,'int16');
		nodeDegree = zeros(1,network.numberOfNodes,'int16');
		nodeAMRP = zeros(1,network.numberOfNodes);
		clusterHeadProb = zeros(1,network.numberOfNodes);
		
		% Cluster Head Selection.
		
		for i=1:network.numberOfNodes
			if(network.node(i).isAlive == 1)
				[nodeAMRP(i),nodeDegree(i)] = calculateCost(i);
				clusterHeadProb(i) = max(Cprob*network.node(i).energy/initialEnergy,Pmin);
			end
		end
		
		for j=1:iterations
			for i=1:network.numberOfNodes
				if(network.node(i).isAlive == 1)
					
					dist = distanceNodes(i,:);
					dist = find( dist <= clusterRange);
					indexes = [];
					
					for k = 1:length(setOfTentativeCH)
						if(length(find(dist == setOfTentativeCH(k))) != 0)
							indexes = [indexes,setOfTentativeCH(k)];
						elseif( setOfTentativeCH(k) == i)
							indexes = [indexes,setOfTentativeCH(k)];
						end
					end
					
					if(length(indexes) != 0)
						
						minNodeDegree = min(nodeDegree(indexes));
						tempIndex = [];
						for t=1:length(nodeDegree)
							if(length(find(indexes == t)) != 0)
								if(nodeDegree(t) == minNodeDegree)
									tempIndex = [tempIndex,t];
								end
							end
						end
						
						indexes = tempIndex;
						
						minNodeAMRP = min(nodeAMRP(indexes));
						tempIndex = [];
						for t=1:length(nodeAMRP)
							if(length(find(indexes == t)) != 0)
								if(nodeAMRP(t) == minNodeAMRP)
									tempIndex = [tempIndex,t];
								end
							end
						end
						
						indexes = tempIndex;
						
						if(indexes(1) == i)
							if(clusterHeadProb(i) == 1)
								setOfFinalCH = [setOfFinalCH,i];
								network.node(i).clusterRound = roundNum ;
							end
						end
						
					elseif(clusterHeadProb(i) == 1)
						setOfFinalCH = [setOfFinalCH,i];
						network.node(i).clusterRound = roundNum ;
					
					elseif (rand(1,1) <= clusterHeadProb(i))
						setOfTentativeCH = [setOfTentativeCH,i];
					end
					
					clusterHeadProb(i) = min(2*clusterHeadProb(i),1);
				end
			end
		end
		
		for i=1:network.numberOfNodes
			if(network.node(i).clusterRound != roundNum)
				dist = distanceNodes(i,:);
				dist = find( dist <= clusterRange);
				indexes = [];
					
				for k = 1:length(setOfFinalCH)
					if(length(find(dist == setOfFinalCH(k))) != 0)
						indexes = [indexes,setOfFinalCH(k)];
					end
				end
					
				if(length(indexes) != 0)
					
					minNodeDegree = min(nodeDegree(indexes));
					tempIndex = [];
					for t=1:length(nodeDegree)
						if(length(find(indexes == t)) != 0)
							if(nodeDegree(t) == minNodeDegree)
								tempIndex = [tempIndex,t];
							end
						end
					end
					
					indexes = tempIndex;
					
					minNodeAMRP = min(nodeAMRP(indexes));
					tempIndex = [];
					for t=1:length(nodeAMRP)
						if(length(find(indexes == t)) != 0)
							if(nodeAMRP(t) == minNodeAMRP)
								tempIndex = [tempIndex,t];
							end
						end
					end
					
					indexes = tempIndex;
					nodeUnderCluster(i) = indexes(1);
					nodeCountUnderCH(indexes(1)) += 1;
				else
					setOfFinalCH = [setOfFinalCH,i];
					network.node(i).clusterRound = roundNum;
				end
			end
		end
		
		% Data Transmission and Energy Dissipation.
		for i=1:network.numberOfNodes
			if(network.node(i).isAlive == 1)
			
				if(network.node(i).clusterRound == roundNum)
					receiveLoss(i,nodeCountUnderCH(i));
					aggregateLoss(i,nodeCountUnderCH(i));
					transmitLoss(i,1,distanceBS(i));
				
				elseif(network.node(nodeUnderCluster(i)).isAlive == 1)
					transmitLoss(i,1,distanceNodes(i,nodeUnderCluster(i)));
				end
				
				stats.heed.residualEnergyPerNode(i,roundNum+1) = network.node(i).energy;
			end
		end
		
		
		if(deadNodes == network.numberOfNodes)
			stats.heed.maxRound = roundNum ; 
		end
		
		if(mod(deadNodes , 0.2*network.numberOfNodes)==0 && deadNodes > 1 && network.needPlot == 1)
			plotNetwork();
		end
		
		deadNodes
		totalEnergy	
		stats.heed.deadNodes(roundNum+1) = deadNodes ;
		stats.heed.totalResidualEnergy(roundNum+1) = totalEnergy ;
	
	end
	
	return ;
end
