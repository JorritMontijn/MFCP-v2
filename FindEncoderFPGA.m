%FindEncoderFPGA  This function reads the speed of the quadrature and
%allows you to find the appropriate ports to read out the running speed
%	Use the following command:
%
%		vecFound = FindEncoderFPGA(objCard,sPortDef,structVals)
%
%	to find the ports.
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function vecFound = FindEncoderFPGA(objCard,sPortDef,structVals)
	
	vecFound = [];
	
	%reset counters
	fprintf('Resetting all counters...\n');
	
	adres_max = 64;
	for ADRES_LOOPBAND = 1:adres_max
		structVals = ReadFPGA(objCard,ADRES_LOOPBAND,true,structVals,sPortDef);
		pauseFor(0.01);
	end
	
	%wait for person to turn encoder
	boolAcceptInput = false;
	while ~boolAcceptInput
		strResp = input(['Did you turn the running band? (Y/N) : '],'s');
		if strcmpi(strResp,'Y')
			boolAcceptInput = true;
		else
			boolAcceptInput = false;
		end
	end
	fprintf('Okay, running encoder detection now...\n');
	
	for ADRES_LOOPBAND = 1:adres_max
		%send command to FPGA
		structVals = ReadFPGA(objCard,ADRES_LOOPBAND,false,structVals,sPortDef);

		if (bitand(uint32(structVals.QUADRATURE),uint32(32768)))
			%positive
			intSpeed = 2 * (structVals.QUADRATURE - 32768); %why * 2? -> calibrated
		else
			%negative
			intSpeed = -2 * structVals.QUADRATURE; %why * 2?
		end

		intSpeedCount = structVals.COUNTER;
		
		if intSpeed ~= 0 || intSpeedCount ~= 0
			fprintf('Port %d seems to contain a non-zero value (speed=%d; counter=%d)...\n',ADRES_LOOPBAND,intSpeed,intSpeedCount)
			vecFound(end+1) = ADRES_LOOPBAND;
		end
	end
	
	fprintf('Now testing actual speed measurement; please keep rotating the running band. We will test each port for 2 seconds...\n');
	strResp = input('Ready?');
	
	for ADRES_LOOPBAND = vecFound
		refPoint = tic;
		fprintf('Max speed port %d: %05d\n',ADRES_LOOPBAND,0);
		maxSpeed = 0;
		while toc(refPoint) < 2
			%send command to FPGA
			structVals = ReadFPGA(objCard,ADRES_LOOPBAND,false,structVals,sPortDef);
			intSpeed = structVals.QUADRATURE;
			maxSpeed = max(maxSpeed,intSpeed);
			fprintf('\b\b\b\b\b\b%05d\n',maxSpeed);
			pauseFor(0.01);
		end
	end
end