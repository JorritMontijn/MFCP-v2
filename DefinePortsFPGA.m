%DefinePortsFPGA  This function loads the .pdm file to supply the port
%definitions of the FPGA. This function is automatically called by
%InitFPGA() when it is run. You can create a port definition file by
%running MakePortDefFPGA().
%	
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB
% 2012-09-10	Created.

function [sPortDef,strPortDefFile] = DefinePortsFPGA(strPortDefFile)
	if ~exist('strPortDefFile','var') || isempty(strPortDefFile)
		strPortDefFile = 'microscope20130306.pdm';
	end
	if ~exist(strPortDefFile,'file')
		error([mfilename ':NoPortDefFile'],'Port definition file [%s] could be not found',strPortDefFile);
	else
		strFullName = which(strPortDefFile);
		vecFindSep = strfind(strFullName,filesep);
		strFilePath = strFullName(1:vecFindSep(end));
		if ~strcmp([pwd filesep],strFilePath)
			strPortDefFile = [strFilePath strPortDefFile];
		end
	end
	
	dummy = load(strPortDefFile,'-mat');
	sPortDef = dummy.sPortDef;
	clear dummy;
end