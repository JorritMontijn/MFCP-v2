%SetPulseFPGA  This function changes the FPGA's servo position
%	Use the following command:
%
%		SetPulseFPGA(objCard,sPortDef,intBit,intTime)
%
%	to make the FPGA send a pulse on intBit for intTime.
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function SetPulseFPGA(objCard,sPortDef,intBit,intTime)
	%send command to FPGA
	SetFPGA(objCard,intBit,1,intTime,sPortDef.PULSE,sPortDef)
end