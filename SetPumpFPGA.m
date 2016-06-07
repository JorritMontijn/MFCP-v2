
%SetPulseFPGA  This function pushes the FPGA's pump
%	Use the following command:
%
%		SetPumpFPGA(objCard,sPortDef,intTime)
%
%	to make the FPGA send a pulse to the pump for intTime.
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function SetPumpFPGA(objCard,sPortDef,dblTime)
	%send command to FPGA
	intTime = uint32(dblTime);
	if intTime ~= dblTime
		warning('SetPumpFPGA:PulseNotInteger','Supplied pulse time was not an integer; %f has been converted to %d',dblTime,intTime);
	end
	SetFPGA(objCard,sPortDef.ADRES_POMP,1,intTime,sPortDef.PULSE,sPortDef);
end