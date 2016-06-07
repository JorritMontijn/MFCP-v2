function MFCP_TestConnection
	%MFCP_TestConnection Function to test the performance of the Matlab
	%FPGA Control Protocol
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	vecRepeats = 1:100;
	boolReadSetOnly = false;
	boolCloseMaster = false;
	
	%init connection
	sMS = MFCP_InitSlave();
	xem = 'AIJOPFnaiZ';
	strPortDefFile = 'portdefinitions.pdm';
	sPortDef = DefinePortsFPGA(strPortDefFile);
	
	if ~boolReadSetOnly
		%check set (pump)
		fprintf('Attempting set...\n');
		intBitNr = sPortDef.ADRES_POMP;
		intValue = 1;
		intPulse = uint32(1000);
		intTriggerMode = sPortDef.PULSE;
		MFCP_SetFPGA(sMS,xem,intBitNr,intValue,intPulse,intTriggerMode);
		fprintf('\b    Done!\n');
		
		%check synchronous read
		fprintf('Attempting synchronous read...\n');
		intBitNr = 10;
		boolReset = 1;
		structVals = MFCP_ReadFPGA(sMS,xem,intBitNr,boolReset);
		fprintf('\b    Done!\n');
		
		%close connection
		fprintf('Closing...\n');
		MFCP_CloseSlave(sMS,boolCloseMaster);
		fprintf('\b    Done!\n');
		
		%repeatedly open and close connection to test system stability
		for i=1:100
			%init connection
			clear sMS;
			sMS = MFCP_InitSlave();
			
			%close connection
			MFCP_CloseSlave(sMS,boolCloseMaster);
			clc
		end
		sMS = MFCP_InitSlave();
	end
	%loop vars
	intBitNr = 10;
	boolReset = 1;
	intValue = 1;
	intPulse = uint32(1000);
	intTriggerMode = sPortDef.PULSE;
	
	vecSynRead=zeros(size(vecRepeats));
	vecAsynRead=zeros(size(vecRepeats));
	vecSet=zeros(size(vecRepeats));
	for numRepeats=vecRepeats
		%test time it takes to sync-read FPGA 100 times
		c=tic;
		nrQ = numRepeats;
		fprintf('\nRunning %d synchronous Read actions in serial...\n',nrQ);
		for x=1:nrQ
			structVals = MFCP_ReadFPGA(sMS,xem,intBitNr,boolReset);
		end
		dur=toc(c);
		fprintf('It took %f seconds to perform %d queries; average of %f ReadFPGA queries per second\n',dur,nrQ,nrQ/dur)
		vecSynRead(numRepeats) = nrQ/dur;
		
		%test time it takes to async-read FPGA 100 times
		car=tic;
		nrAQ = numRepeats;
		fprintf('\nRunning %d asynchronous Read queries in serial; followed by %d asynchronous Read retrievals...\n',nrAQ,nrAQ);
		msgID=zeros(1,nrAQ);
		vecUnretrieved = true(1,nrAQ);
		vecQueries = 1:nrAQ;
		for y=vecQueries
			msgID(y) = MFCP_queryReadFPGA(sMS,xem,intBitNr,boolReset);
		end
		while max(vecUnretrieved)
			for y2=vecQueries(vecUnretrieved)
				structVals = MFCP_getReadFPGA(sMS,msgID(y2));
				if ~isempty(structVals)
					vecUnretrieved(y2) = false;
				end
			end
		end
		durA=toc(car);
		fprintf('It took %f seconds to perform %d queries; average of %f ReadFPGA queries per second\n',durA,nrAQ,nrAQ/durA)
		vecAsynRead(numRepeats) = nrAQ/durA;
		
		%test time it takes to set FPGA 100 times
		cS=tic;
		nrQS = numRepeats;
		fprintf('\nRunning %d Set actions...\n',nrQ);
		for z=1:nrQ
			MFCP_SetFPGA(sMS,xem,intBitNr,intValue,intPulse,intTriggerMode);
		end
		durS=toc(cS);
		fprintf('It took %f seconds to perform %d queries; average of %f SetFPGA queries per second\n',durS,nrQS,nrQS/durS)
		vecSet(numRepeats) = nrQS/durS;
	end
	
	%test sub processes of async read
	%loop vars
	intBitNr = 10;
	boolReset = 1;
	intValue = 1;
	intPulse = uint32(1000);
	intTriggerMode = sPortDef.PULSE;
	
	vecQ=zeros(size(vecRepeats));
	vecG=zeros(size(vecRepeats));
	for numRepeats=vecRepeats
		%test time it takes to async-read FPGA 100 times
		cQ=tic;
		fprintf('\nRunning %d asynchronous Read queries in serial\n',numRepeats);
		msgID=zeros(1,numRepeats);
		vecUnretrieved = true(1,numRepeats);
		vecQueries = 1:numRepeats;
		for y=vecQueries
			msgID(y) = MFCP_queryReadFPGA(sMS,xem,intBitNr,boolReset);
		end
		durQ=toc(cQ);
		QpS=numRepeats/durQ;
		fprintf('It took %f seconds to perform %d queries; average of %f ReadFPGA queries per second\n',durQ,numRepeats,QpS)
		vecQ(numRepeats) = QpS;
		
		%pause
		ps = 1;
		fprintf('Pausing %fs to allow master to process queries\n',ps)
		pause(ps)
		
		%test retrieval
		fprintf('Running %d asynchronous Read retrievals...\n',numRepeats);
		cG=tic;
		while max(vecUnretrieved)
			for y2=vecQueries(vecUnretrieved)
				structVals = MFCP_getReadFPGA(sMS,msgID(y2));
				if ~isempty(structVals)
					vecUnretrieved(y2) = false;
				end
			end
		end
		
		durG=toc(cG);
		GpS=numRepeats/durG;
		fprintf('It took %f seconds to perform %d retrievals; average of %f ReadFPGA retrievals per second\n',durG,numRepeats,GpS)
		vecG(numRepeats) = GpS;
	end
	
	%close connection
	MFCP_CloseSlave(sMS,boolCloseMaster);
	
	
	figure
	plot(vecRepeats,vecSynRead,'b','Tag','Sync Read')
	hold on
	plot(vecRepeats,vecAsynRead,'g','Tag','Async Read')
	plot(vecRepeats,vecSet,'k','Tag','Set')
	legend('Sync Read,','Async Read','Set','Location','Best')
	xlabel('Number of consecutive queries')
	ylabel('Queries per second')
	
	hold on
	plot(vecRepeats,vecQ,'r','Tag','Async qRead')
	plot(vecRepeats,vecG,'m','Tag','Async gRead')
	legend('Sync Read,','Async Read','Set','Async qRead','Async gRead','Location','Best')