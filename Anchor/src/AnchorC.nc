#include "Msg.h" 
#include "Timer.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

module AnchorC {
  	uses {
  	    interface SplitControl as RadioControl;
  	    interface Boot;
	    interface AMPacket;
	    interface AMSend;
	    interface Receive;
	    interface Packet;
	    interface Timer<TMilli> as Timer1;
	    interface Timer<TMilli> as Timer2;
	    interface Timer<TMilli> as Timer3;
	}
}

implementation {
  message_t packet;
  void sendPacket();
  
  event void Boot.booted() {
	printf("Anchor Node %d booted\n", TOS_NODE_ID);
	call RadioControl.start();
	if(TOS_NODE_ID == 1) {
		call Timer2.startOneShot(WAIT_BEFORE_SYNC);
	}
  }
  
  event void RadioControl.startDone(error_t err){}
  
  event void RadioControl.stopDone(error_t err){
  	call Timer3.stop();
  	call Timer1.stop();	
  }
  
  event void Timer1.fired() {
	call Timer3.startOneShot(TIMESLOT*TOS_NODE_ID);
  }
  
  event void Timer3.fired() {
  	sendPacket();
  }
  
  void sendPacket() {
	nodeMessage_t* mess = (nodeMessage_t*) (call Packet.getPayload(&packet,sizeof(nodeMessage_t)));
	mess->msg_type = BEACON;
	mess->x = anchorCoord[TOS_NODE_ID-1].x;
	mess->y = anchorCoord[TOS_NODE_ID-1].y;
	 
	printf("Anchor Node %d sending beacon message \n", TOS_NODE_ID);
	call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(nodeMessage_t));
	
	call Timer1.startOneShot(SEND_INTERVAL_ANCHOR);
	printf("Anchor node %d triggers Timer1\n", TOS_NODE_ID);

  }
 
  void sendPacketSync() {
	nodeMessage_t* mess = (nodeMessage_t*) (call Packet.getPayload(&packet,sizeof(nodeMessage_t)));
	mess->msg_type = SYNCPACKET;
	 
	printf("Anchor Node %d is sending sync beacon message\n", TOS_NODE_ID);
	call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(nodeMessage_t));
  }
 

  event void AMSend.sendDone(message_t* buf,error_t err) {
    if(&packet == buf && err == SUCCESS ) {}
  }

	event void Timer2.fired(){
			sendPacketSync();					
			call Timer3.startOneShot(TIMESLOT*TOS_NODE_ID);

	}

	event message_t * Receive.receive(message_t* buf,void* payload, uint8_t len) {
		am_addr_t sourceNodeId = call AMPacket.source(buf);	
		nodeMessage_t* mess = (nodeMessage_t*) payload;
	
		if ( mess->msg_type == SYNCPACKET) {
			printf("Anchor Node %d received sync instruction from Anchor Node %d\n", TOS_NODE_ID, sourceNodeId);

			call Timer3.startOneShot(TIMESLOT*TOS_NODE_ID);
		}
		else if( mess->msg_type == SWITCHOFF)  {
			printf("Anchor Node %d received switchoff instruction from Anchor Node %d\n", TOS_NODE_ID, sourceNodeId);
			printf("Anchor Node %d is switching off\n", TOS_NODE_ID);
			call RadioControl.stop();
			call Timer1.stop();
			call Timer3.stop();
		}
		return buf;
	}
}
