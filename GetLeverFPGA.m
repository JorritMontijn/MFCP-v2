%GetLeverFPGA  This function reads the status of the lever
%	Use the following command:
%
%		[intPressed,intPressCount,structVals] = GetLeverFPGA(objCard,sPortDef,structVals,[boolReset])
%
%	to read the status of the lever. Output intPressed gives the instantaneous
%	status, while intCount gives the number of presses since the last
%	reset. The input boolReset resets the counter if set to 1
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function [intPressed,intPressCount,structVals] = GetLeverFPGA(objCard,sPortDef,structVals,boolReset)
	%define boolReset
	if ~exist('boolReset','var') || isempty(boolReset) || boolReset ~= true
		boolReset = false;
	end
	
	%send command to FPGA
	structVals = ReadFPGA(objCard,sPortDef.ADRES_LEVER,boolReset,structVals,sPortDef);
	
	intActiveBits = structVals.SENSOR0;
	intPressed = ~bitget(intActiveBits,sPortDef.ADRES_LEVER+1);
	intPressCount=structVals.COUNTER;
end