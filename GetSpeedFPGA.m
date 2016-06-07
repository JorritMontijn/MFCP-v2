%GetSpeedFPGA  This function reads the speed of the quadrature
%	Use the following command:
%
%		[intSpeed,intSpeedCount,structVals] = GetSpeedFPGA(objCard,sPortDef,structVals,boolReset)
%
%	to read the speed of the quadrature.
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function [intSpeed,intSpeedCount,structVals] = GetSpeedFPGA(objCard,sPortDef,structVals,boolReset)
	%define boolReset
	if ~exist('boolReset','var') || isempty(boolReset) || boolReset ~= true
		boolReset = false;
	end
	
	%send command to FPGA
	structVals = ReadFPGA(objCard,sPortDef.ADRES_LOOPBAND(end),boolReset,structVals,sPortDef);
	
	if (bitand(uint32(structVals.QUADRATURE),uint32(32768)))
		%positive
		intSpeed = 2 * (structVals.QUADRATURE - 32768); %why * 2? -> calibrated
	else
		%negative
		intSpeed = -2 * structVals.QUADRATURE; %why * 2?
	end
	
	intSpeedCount = structVals.COUNTER;
end