%GetPulseFPGA  This function changes the FPGA's servo position
%	Use the following command:
%
%		SetValueFPGA(objCard,sPortDef,intBit,intVal)
%
%	to set the value on intBit to intVal.
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function SetValueFPGA(objCard,sPortDef,intBit,intVal)
	%send command to FPGA
	SetFPGA(objCard,intBit,intVal,0,sPortDef.WRITE,sPortDef);
end