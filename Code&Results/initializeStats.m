% Here the statistics variables are initialized so that
% statistics of each protocol is 
% saved to be analyzed later using graphs.

function stats = initializeStats(numberOfNodes)

	stats.leach.maxRound = 0 ;
	stats.leach.deadNodes = zeros(1,10000,'int16');
	stats.leach.totalResidualEnergy = zeros(1,10000);
	stats.leach.residualEnergyPerNode = zeros(numberOfNodes,10000);
	
	stats.pegasis.maxRound = 0 ;
	stats.pegasis.deadNodes = zeros(1,10000,'int16');
	stats.pegasis.totalResidualEnergy = zeros(1,10000);
	stats.pegasis.residualEnergyPerNode = zeros(numberOfNodes,10000);
	
	stats.heed.maxRound = 0 ;
	stats.heed.deadNodes = zeros(1,10000,'int16');
	stats.heed.totalResidualEnergy = zeros(1,10000);
	stats.heed.residualEnergyPerNode = zeros(numberOfNodes,10000);
	
	return ;
end
