package com.agnity.sipper.loadviewer.data;

import java.util.HashMap;
import java.util.Map.Entry;

public class TimeSlotData
{
    public class TxnInfo
    {
        long minDuration   = Long.MAX_VALUE;
        long maxDuration   = Long.MIN_VALUE;
        long totalCount    = 0;
        long totalDuration = 0;

        void add(long duration)
        {
            totalCount++;
            totalDuration += duration;
            if(duration < minDuration) minDuration = duration;
            if(duration > maxDuration) maxDuration = duration;
        }

        public void copyTo(TxnInfo inVal)
        {
            inVal.totalCount += totalCount;
            inVal.totalDuration += totalDuration;

            if(minDuration < inVal.minDuration) inVal.minDuration = minDuration;
            if(maxDuration > inVal.maxDuration) inVal.maxDuration = maxDuration;
        }

        public String toString()
        {
            return String.format("Min[%d] Max[%d] Avg[%d] in usecs", minDuration, maxDuration, totalDuration/totalCount);
            //long avg = totalDuration / totalCount;
            //return "Min[" + minDuration + "] Max[" + maxDuration + "] Avg[" + avg + "] in usecs";
        }
    }

    public long                     sec                = 0;
    public long                     numMsgs            = 0;
    public long                     numDroppedMsgs     = 0;
    public long                     numReqs            = 0;
    public long                     numIncomings       = 0;

    public long                     numNewCalls        = 0;
    public long                     numNewTxns         = 0;
    public long                     numReqRetrans      = 0;

    public long                     numCompCalls       = 0;
    public long                     numCompTxns        = 0;

    public long                     numResRetrans      = 0;
    public long                     numProvisionalResp = 0;

    public HashMap<String, Long>    incomingMsgMap     = new HashMap<String, Long>(25);
    public HashMap<String, Long>    outgoingMsgMap     = new HashMap<String, Long>(25);
    public HashMap<String, TxnInfo> incomingTxnMap     = new HashMap<String, TxnInfo>(25);
    public HashMap<String, TxnInfo> outgoingTxnMap     = new HashMap<String, TxnInfo>(25);

    public void reset()
    {
        sec = 0;
        numNewCalls = 0;
        numCompCalls = 0;
        numNewTxns = 0;
        numCompTxns = 0;
        numResRetrans = 0;
        numReqRetrans = 0;
        numDroppedMsgs = 0;
        numMsgs = 0;
        numReqs = 0;
        numIncomings = 0;
        numProvisionalResp = 0;
        incomingMsgMap.clear();
        outgoingMsgMap.clear();
        incomingTxnMap.clear();
        outgoingTxnMap.clear();
    }

    public void copyTo(TimeSlotData in)
    {
        in.sec = sec;
        in.numNewCalls += numNewCalls;
        in.numCompCalls += numCompCalls;
        in.numNewTxns += numNewTxns;
        in.numCompTxns += numCompTxns;
        in.numResRetrans += numResRetrans;
        in.numReqRetrans += numReqRetrans;
        in.numDroppedMsgs += numDroppedMsgs;
        in.numMsgs += numMsgs;
        in.numReqs += numReqs;
        in.numIncomings += numIncomings;
        in.numProvisionalResp += numProvisionalResp;

        for(Entry<String, Long> entry : incomingMsgMap.entrySet())
        {
            String name = entry.getKey();
            Long value = entry.getValue();

            Long currval = in.incomingMsgMap.get(name);

            if(currval == null)
            {
                in.incomingMsgMap.put(name, value);
            }
            else
            {
                in.incomingMsgMap.put(name, Long.valueOf(currval.longValue() + value.longValue()));
            }
        }

        for(Entry<String, Long> entry : outgoingMsgMap.entrySet())
        {
            String name = entry.getKey();
            Long value = entry.getValue();

            Long currval = in.outgoingMsgMap.get(name);

            if(currval == null)
            {
                in.outgoingMsgMap.put(name, value);
            }
            else
            {
                in.outgoingMsgMap.put(name, Long.valueOf(currval.longValue() + value.longValue()));
            }
        }

        for(Entry<String, TxnInfo> entry : incomingTxnMap.entrySet())
        {
            String name = entry.getKey();
            TxnInfo value = entry.getValue();

            TxnInfo currVal = in.incomingTxnMap.get(name);

            if(currVal == null)
            {
                currVal = new TxnInfo();
                in.incomingTxnMap.put(name, currVal);
            }

            value.copyTo(currVal);
        }

        for(Entry<String, TxnInfo> entry : outgoingTxnMap.entrySet())
        {
            String name = entry.getKey();
            TxnInfo value = entry.getValue();

            TxnInfo currVal = in.outgoingTxnMap.get(name);

            if(currVal == null)
            {
                currVal = new TxnInfo();
                in.outgoingTxnMap.put(name, currVal);
            }

            value.copyTo(currVal);
        }

    }

    public void loadMessage(SipMsgData msg)
    {
        String name = msg.name;
        if(!msg.isRequest)
        {
            name += (" " + msg.respReq);
        }

        HashMap<String, Long> mapToUse = incomingMsgMap;

        if(!msg.isIncoming)
        {
            mapToUse = outgoingMsgMap;
        }

        Long currval = mapToUse.get(name);

        if(currval == null)
        {
            mapToUse.put(name, Long.valueOf(1));
        }
        else
        {
            mapToUse.put(name, Long.valueOf(currval.longValue() + 1));
        }
    }

    public void loadCompTrans(SipMsgData reqData, SipMsgData respMsg)
    {
        long txnDuration = ((respMsg.time_sec - reqData.time_sec) * 1000000) + respMsg.time_usec - reqData.time_usec;

        HashMap<String, TxnInfo> mapToUse = incomingTxnMap;

        if(!reqData.isIncoming)
        {
            mapToUse = outgoingTxnMap;
        }

        TxnInfo locInfo = mapToUse.get(reqData.name);
        if(locInfo == null)
        {
            locInfo = new TxnInfo();
            mapToUse.put(reqData.name, locInfo);
        }
        locInfo.add(txnDuration);
    }
}
