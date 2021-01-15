#include "Msg.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration AnchorAppC {} 

implementation {
	components MainC;
	components SerialPrintfC;
	components AnchorC as App;
	components new AMSenderC(AM_RSSIMSG);
	components new AMReceiverC(AM_RSSIMSG);
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components new TimerMilliC() as Timer3;
	components ActiveMessageC;
	
	  App.Boot -> MainC.Boot;
	  App.RadioControl -> ActiveMessageC;
	 
	  App.AMSend -> AMSenderC;
	  App.Packet -> AMSenderC;
	  App.Receive -> AMReceiverC;
	  App.AMPacket -> AMSenderC;
	 
	  App.Timer1 -> Timer1;
	  App.Timer2 -> Timer2;
	  App.Timer3 -> Timer3;

}
