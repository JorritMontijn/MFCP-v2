%GetFrameCountFPGA  This function reads frame count of the microscope
%	Use the following command:
%
%		[intFrameCount,structVals] = GetFrameCountFPGA(objCard,sPortDef,structVals,boolReset)
%
%	to read the frame count of the microscope. The input boolReset resets the counter if set to 1
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function [intFrameCount,structVals] = GetFrameCountFPGA(objCard,sPortDef,structVals,boolReset)
	%define boolReset
	if ~exist('boolReset','var') || isempty(boolReset) || boolReset ~= true
		boolReset = false;
	end
	
	%send command to FPGA
	structVals = ReadFPGA(objCard,sPortDef.ADRES_FRAMECOUNTER,boolReset,structVals,sPortDef);
	
	intFrameCount=structVals.COUNTER;
end