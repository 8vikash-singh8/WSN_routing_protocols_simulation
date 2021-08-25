%Implementation of PEGASIS protocol.

function stats = pegasis( network , stats )

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
			network.node(i).energy -= (double(l*packetLength)*aggrEnergy);
			
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
	
	% Creating a single chain of node on the basis of distance , 
	% starting from furthest node from sink to closest node to sink.
	nodes = [1:network.numberOfNodes];
	chain = [];
	i = 1;
	while(!isempty(nodes)) 
		if(i==1)
			[maxDist,indexNum] = max(distanceBS);
		else
			[minDist,indexNum] = min(distanceNodes(chain(i-1),nodes));
		end
		chain(i++) = nodes(indexNum);
		nodes(nodes == nodes(indexNum)) = [];
	end
	
	% Creation of first chain on the network plot for visualization purpose. 
	% The chain plot does not update after node forms clusters or dies. So it only shows the first time the chain forms.
	%for i=1:length(chain)-1
	%	plot([network.node(chain(i)).loc_X,network.node(chain(i+1)).loc_X],... 		
	%			[network.node(chain(i)).loc_Y,network.node(chain(i+1)).loc_Y],'b');
	%end
	
	% stats at the start of protocol
	stats.pegasis.deadNodes(roundNum+1) = deadNodes ;
	stats.pegasis.totalResidualEnergy(roundNum+1) = totalEnergy ;
	stats.pegasis.residualEnergyPerNode(:,roundNum+1) = network.node(1).energy ;
	
	% protocol runs until every node dies.
	turn = 0 ; % it is used in cluster head selection.
	while(deadNodes < network.numberOfNodes)
	
		roundNum += 1;
		
		printf("\nRound Number : %d\n",roundNum);
		
		% cluster head selection
		while(1)
			turn = mod(turn + 1,network.numberOfNodes+1);
			if(turn == 0)
				turn += 1;
			end
			
			if(network.node(turn).isAlive == 1)
				network.node(turn).clusterRound = roundNum ;
				break;
			end
			
		end
		clusterHead = find(chain==turn) ;
		
		% Data transmission and energy dissipation for nodes.
		for i=1:network.numberOfNodes

			if(network.node(i).isAlive == 1)
			
				chainId = find(chain == i);
				
				if(chainId == 1)  % first node in the chain,considering if it is cluster head or not.
					
					if(chainId == clusterHead && length(chain) > 1)
						receiveLoss(i,1);
						aggregateLoss(i,2);
						transmitLoss(i,1,distanceBS(i));
					
					elseif(length(chain)==1)
						transmitLoss(i,1,distanceBS(i));
					else
						transmitLoss(i,1,distanceNodes(i,chain(chainId+1)));
					end
					
				elseif(chainId == length(chain)) % last node in the chain,considering if it is cluster head or not.
					
					if(chainId == clusterHead)
						receiveLoss(i,1);
						aggregateLoss(i,2);
						transmitLoss(i,1,distanceBS(i));
					else
						transmitLoss(i,1,distanceNodes(i,chain(chainId-1)));
					end
				else				% middle node in the chain,considering if it is cluster head or not.
				
					if(chainId == clusterHead)
					
						receiveLoss(i,2);
						aggregateLoss(i,3);
						transmitLoss(i,1,distanceBS(i));
					
					elseif(chainId < clusterHead)
					
						receiveLoss(i,1);
						aggregateLoss(i,2);
						transmitLoss(i,1,distanceNodes(i,chain(chainId+1)));
					else
						receiveLoss(i,1);
						aggregateLoss(i,2);
						transmitLoss(i,1,distanceNodes(i,chain(chainId-1)));
					end
				
				end
				
				stats.pegasis.residualEnergyPerNode(i,roundNum+1) = network.node(i).energy ;
				
				if(network.node(i).isAlive == 0)
					chain(chainId) = [];
				end
			end	
		end
		
		if(deadNodes == network.numberOfNodes)
			stats.pegasis.maxRound = roundNum ; 
		end
		
		if(mod(deadNodes , 0.2*network.numberOfNodes)==0 && deadNodes > 1 && network.needPlot == 1)
			plotNetwork();
		end
		
		deadNodes
		totalEnergy	
		stats.pegasis.deadNodes(roundNum+1) = deadNodes ;
		stats.pegasis.totalResidualEnergy(roundNum+1) = totalEnergy ;
	
	end
	
	return ;
end
