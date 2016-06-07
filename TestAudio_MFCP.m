%test scripts

%init slave
sMS = MFCP_InitSlave();

%create variables
dblTime = now;
varAudio='whoopie';
MFCP_SetAudio(sMS,dblTime,varAudio)

%close slave
MFCP_CloseSlave(sMS,false);
