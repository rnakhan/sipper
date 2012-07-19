package com.agnity.sipper.loadviewer.data;

import java.nio.ByteBuffer;

public class SipMsgData
{
    public int     totalLen;
    public boolean isIncoming = false;
    public boolean isRequest  = false;
    public String  name;
    public String  branch;
    public String  callId;
    public String  sipMsg;
    public String  respReq;
    public int     ip;
    public short   port;
    public long    time_sec;
    public long    time_usec;

    public String toString()
    {
        return "";
        // return String.format(
        // "Incoming[%s] Request[%s] Name[%s] RespReq[%s] Branch[%s] CallId[%s] Msg[%s] Peer[%d:%d] Time[%d:%d]"
        // ,
        // isIncoming, isRequest, name, respReq, branch, callId, sipMsg, ip,
        // port, time_sec, time_usec);

    }

    public int parse(ByteBuffer inBuf)
    {
        int currPos = inBuf.position();
        totalLen = inBuf.getInt();
        int finalPos = currPos + totalLen;

        if(inBuf.get() == 1) isIncoming = true;
        if(inBuf.get() == 1) isRequest = true;

        int nameLen = inBuf.get();
        int branchLen = inBuf.getShort();
        int callIdLen = inBuf.getShort();
        int sipMsgLen = inBuf.getShort();
        ip = inBuf.getInt();
        port = inBuf.getShort();
        time_sec = inBuf.getInt();
        time_usec = inBuf.getInt();
        int respReqLen = inBuf.get();
        byte[] nameBuf = new byte[nameLen];
        inBuf.get(nameBuf);
        name = new String(nameBuf);

        byte[] branchBuf = new byte[branchLen];
        inBuf.get(branchBuf);
        branch = new String(branchBuf);

        byte[] callIdBuf = new byte[callIdLen];
        inBuf.get(callIdBuf);
        callId = new String(callIdBuf);

        byte[] sipMsgBuf = new byte[sipMsgLen];
        inBuf.get(sipMsgBuf);
        sipMsg = new String(sipMsgBuf);

        byte[] respReqBuf = new byte[respReqLen];
        inBuf.get(respReqBuf);
        respReq = new String(respReqBuf);

        if(inBuf.position() == finalPos)
        {
            return 0;
        }

        System.err.printf("Position mismatch. Final[%d] Actual[%d]\n", finalPos, inBuf.position());
        return -1;
    }
}
