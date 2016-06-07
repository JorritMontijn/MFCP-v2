function MFCP_PlayAudio(dblTime,varAudio)
	%MFCP_PlayAudio Use this function to handle an audio request
	%   Syntax:  MFCP_PlayAudio(dblTime,varAudio), both variables are
	%   identical to those supplied to MFCP_SetAudio(sMS,dblTime,varAudio) 
	%
	% History:
	%
	% 2014-01-20	Created MFCP_PlayAudio function as addition to the 
	%				Matlab FPGA Control Protocol functions
	
	%define transformation factor to seconds
	intTransformationFactor = 86400;
	
	%message received!
	dblSecsBeforeEvent = intTransformationFactor*(dblTime-now) %double sex before event!
	varAudio %any crap you sent along with the requested event onset
end

