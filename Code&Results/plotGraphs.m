% Plotting Graphs on the acquired statistcs.

function plotGraphs(numberOfNodes,stats)

	A = [0,(1:stats.leach.maxRound)];
	P = [0,(1:stats.pegasis.maxRound)];
	X = [0,(1:stats.heed.maxRound)];
	
	figure(1);
	hold('on');
	grid('on');
	
	deadB = [stats.leach.deadNodes(1:(stats.leach.maxRound+1))];
	deadQ = [stats.pegasis.deadNodes(1:(stats.pegasis.maxRound+1))];
	deadY = [stats.heed.deadNodes(1:(stats.heed.maxRound+1))];
	
	%Printing round number of FIRST NODE, HALF NODE and LAST NODE dies.
	printf("\nLEACH\n");
	FND = min(find(deadB >= 1))-1
	HND = min(find(deadB >= (numberOfNodes/2)))-1
	LND = stats.leach.maxRound
	
	printf("\nPEGASIS\n");
	FND = min(find(deadQ >= 1))-1
	HND = min(find(deadQ >= (numberOfNodes/2)))-1
	LND = stats.pegasis.maxRound
	
	printf("\nHEED\n");
	FND = min(find(deadY >= 1))-1
	HND = min(find(deadY >= (numberOfNodes/2)))-1
	LND = stats.heed.maxRound
	
	
	plot(A,deadB,'LineWidth',1,'Color','r',P,deadQ,'LineWidth',1,'Color','b',X,deadY,'LineWidth',1,'Color','g');	
	xlabel('Round','FontWeight','bold','FontSize',11,'FontName','Cambria');
	ylabel('Dead Nodes','FontWeight','bold','FontSize',11,'FontName','Cambria')
	title('Dead Nodes vs. Round','FontWeight','bold','FontSize',12,'FontName','Cambria');
	[leg,icons,plots,legend_text] = legend('LEACH','PEGASIS','HEED');
	set(leg,'Location','northwest');
	
	figure(2);
	hold('on');
	grid('on');
	
	totalB = [stats.leach.totalResidualEnergy(1:(stats.leach.maxRound+1))];
	totalQ = [stats.pegasis.totalResidualEnergy(1:(stats.pegasis.maxRound+1))];
	totalY = [stats.heed.totalResidualEnergy(1:(stats.heed.maxRound+1))];
	
	plot(A,totalB,'LineWidth',1,'Color','r',P,totalQ,'LineWidth',1,'Color','b',X,totalY,'LineWidth',1,'Color','g');
	xlabel('Round','FontWeight','bold','FontSize',11,'FontName','Cambria');
	ylabel('Total Residual Energy','FontWeight','bold','FontSize',11,'FontName','Cambria');
	title(' Total Residual Energy of network vs. round','FontWeight','bold','FontSize',12,'FontName','Cambria');
	legend('LEACH','PEGASIS','HEED');
	[leg,icons,plots,legend_text] = legend('LEACH','PEGASIS','HEED');
	set(leg,'Location','northeast');

	figure(3);
	hold('on');
	grid('on');
	
	avgB = [stats.leach.totalResidualEnergy(1:(stats.leach.maxRound+1))];
	avgQ = [stats.pegasis.totalResidualEnergy(1:(stats.pegasis.maxRound+1))];
	avgY = [stats.heed.totalResidualEnergy(1:(stats.heed.maxRound+1))];

	for i=1:length(A)-1
		avgB(i) = avgB(i)/double(numberOfNodes - deadB(i));
	end
	
	for i=1:length(P)-1
		avgQ(i) = avgQ(i)/double(numberOfNodes - deadQ(i));
	end
	
	for i=1:length(X)-1
		avgY(i) = avgY(i)/double(numberOfNodes - deadY(i));
	end
	
	plot(A,avgB,'LineWidth',1,'Color','r',P,avgQ,'LineWidth',1,'Color','b',X,avgY,'LineWidth',1,'Color','g');
	xlabel('Round','FontWeight','bold','FontSize',11,'FontName','Cambria');
	ylabel('Average Residual Energy','FontWeight','bold','FontSize',11,'FontName','Cambria');
	title(' Average Residual Energy of node vs. round','FontWeight','bold','FontSize',12,'FontName','Cambria');
	legend('LEACH','PEGASIS','HEED');
	[leg,icons,plots,legend_text] = legend('LEACH','PEGASIS','HEED');
	set(leg,'Location','northeast');
	
	figure(4);
	hold('on');
	grid('on');
	
	varB = [];
	varQ = [];
	varY = [];
	
	for i=1:length(A)-1
		varB(i) = 0;
		for j=1:numberOfNodes
			if(stats.leach.residualEnergyPerNode(j,i) != 0)
				varB(i) += (stats.leach.residualEnergyPerNode(j,i) - avgB(i))^2 ;
			end
		end
		varB(i) /= double(numberOfNodes - deadB(i)) ;
	end
	
	varB = [varB,0];
	
	for i=1:length(P)-1
		varQ(i) = 0;
		for j=1:numberOfNodes
			if(stats.pegasis.residualEnergyPerNode(j,i) != 0)
				varQ(i) += (stats.pegasis.residualEnergyPerNode(j,i) - avgQ(i))^2 ;
			end
		end
		varQ(i) /= double(numberOfNodes - deadQ(i)) ;
	end
	
	varQ = [varQ,0];
	
	for i=1:length(X)-1
		varY(i) = 0;
		for j=1:numberOfNodes
			if(stats.heed.residualEnergyPerNode(j,i) != 0)
				varY(i) += (stats.heed.residualEnergyPerNode(j,i) - avgY(i))^2 ;
			end
		end
		varY(i) /= double(numberOfNodes - deadY(i)) ;
	end
	
	varY = [varY,0];
	
	plot(A,varB,'LineWidth',1,'Color','r',P,varQ,'LineWidth',1,'Color','b',X,varY,'LineWidth',1,'Color','g');
	xlabel('Round','FontWeight','bold','FontSize',11,'FontName','Cambria');
	ylabel('Variance','FontWeight','bold','FontSize',11,'FontName','Cambria');
	title(' Variance of Residual Energy of node vs. round','FontWeight','bold','FontSize',12,'FontName','Cambria');
	legend('LEACH','PEGASIS','HEED');
	[leg,icons,plots,legend_text] = legend('LEACH','PEGASIS','HEED');
	set(leg,'Location','northeast');
	
	return ;
end
