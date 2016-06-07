function [sMsg,intStart,arThisMsg] = MFCP_getMsg(msmf_IO,intMsg,boolReset)
	%MFCP_getMsg Returns message intMsg from shared mem
	%   [sMsg,intStart,arThisMsg] = MFCP_getMsg(msmf_IO,intMsg,boolReset)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%define variables
	intMsgLength = 52;
	arrayMsg = msmf_IO.Data;
	
	%get start location of target message
	intStart = (intMsgLength * (intMsg - 1)) + 1;
	intStop = intStart + intMsgLength - 1;
	
	%get array
	arThisMsg = arrayMsg(intStart:intStop);

	%put array into structure format
	sMsg.flags = arThisMsg(1);
	sMsg.target = typecast(arThisMsg(2:5), 'uint32');
	sMsg.source = typecast(arThisMsg(6:9), 'uint32');
	sMsg.msg = arThisMsg(10);
	xem = char(arThisMsg(11:20));
	sMsg.xem = xem';
	sMsg.data = arThisMsg(21:52);
	
	%check pending
	if ~exist('boolReset','var') || isempty(boolReset)
		boolReset = 0;
	end
	%set pending to 0
	if boolReset
		msmf_IO.Data(intStart) = arThisMsg(1)-128;
	end
end

