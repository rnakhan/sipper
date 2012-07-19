package com.agnity.sipper.loadviewer;

import java.util.HashMap;
import java.util.HashSet;

import com.agnity.sipper.loadviewer.data.SipMsgData;
import com.agnity.sipper.loadviewer.data.TimeSlotData;
import com.agnity.sipper.loadviewer.data.TimeSlotModalData;

public class LoadDataManager
{
    HashSet<String>             _callMap     = new HashSet<String>(100000);
    HashMap<String, SipMsgData> _txnMap      = new HashMap<String, SipMsgData>(100000);

    TimeSlotData                _totalStat   = new TimeSlotData();
    TimeSlotData                _secSlot[]   = new TimeSlotData[301];

    int                         _currSlotNum = 0;

    public LoadDataManager()
    {
        for(int idx = 0; idx < _secSlot.length; idx++)
        {
            _secSlot[idx] = new TimeSlotData();
        }
    }

    private TimeSlotData _getTimeSlot(SipMsgData msg)
    {
        TimeSlotData currSlot = _secSlot[_currSlotNum];

        if(currSlot.sec == msg.time_sec)
        {
            return currSlot;
        }

        if(currSlot.sec == 0)
        {
            currSlot.sec = msg.time_sec;
            return currSlot;
        }

        if(msg.time_sec < currSlot.sec)
        {
            System.out.println("MsgTime:" + msg.time_sec + " SlotTime:" + currSlot.sec);
            return null;
        }

        _currSlotNum += (msg.time_sec - currSlot.sec);

        if(_currSlotNum < _secSlot.length)
        {
            currSlot.sec = msg.time_sec;
            return currSlot;
        }

        int minSlotNum = _currSlotNum - (_secSlot.length - 1);

        if(minSlotNum >= _secSlot.length)
        {
            _currSlotNum = 0;

            for(int idx = 0; idx < _secSlot.length; idx++)
            {
                _secSlot[idx].reset();
            }
        }
        else
        {
            for(int idx = 0; idx < minSlotNum; idx++)
            {
                _secSlot[idx].reset();
            }

            int tocopy = _secSlot.length - minSlotNum;
            for(int idx = 0; idx < tocopy; idx++)
            {
                TimeSlotData tmp = _secSlot[idx];
                _secSlot[idx] = _secSlot[minSlotNum + idx];
                _secSlot[minSlotNum + idx] = tmp;
            }

            _currSlotNum -= minSlotNum;
        }

        currSlot = _secSlot[_currSlotNum];
        currSlot.sec = msg.time_sec;

        return currSlot;
    }

    public synchronized void loadData(SipMsgData msg)
    {
        if(msg == null)
        {
            //msg = new SipMsgData();
            //msg.time_sec = _secSlot[_currSlotNum].sec + 1;
            //_getTimeSlot(msg);
            return;            
        }
        
        TimeSlotData currSlot = _getTimeSlot(msg);        

        if(currSlot == null)
        {
            _totalStat.numDroppedMsgs++;
            return;
        }
        
        _totalStat.sec = msg.time_sec;

        currSlot.numMsgs++;
        _totalStat.numMsgs++;

        if(msg.isIncoming)
        {
            currSlot.numIncomings++;
            _totalStat.numIncomings++;
        }

        if(msg.isRequest)
        {
            currSlot.numReqs++;
            _totalStat.numReqs++;

            if(_callMap.add(msg.callId))
            {
                currSlot.numNewCalls++;
                _totalStat.numNewCalls++;
            }

            if(!msg.name.equals("ACK"))
            {
                if(_txnMap.put(msg.branch, msg) == null)
                {
                    currSlot.numNewTxns++;
                    _totalStat.numNewTxns++;
                }
                else
                {
                    currSlot.numReqRetrans++;
                    _totalStat.numReqRetrans++;
                }
            }
            else
            {
                currSlot.numNewTxns++;
                _totalStat.numNewTxns++;
                currSlot.numCompTxns++;
                _totalStat.numCompTxns++;
            }
        }
        else
        {
            if(msg.name.charAt(0) == '1')
            {
                currSlot.numProvisionalResp++;
                _totalStat.numProvisionalResp++;
            }
            else
            {
                SipMsgData reqData = _txnMap.remove(msg.branch);

                if(reqData == null)
                {
                    currSlot.numResRetrans++;
                    _totalStat.numResRetrans++;
                }
                else
                {
                    currSlot.loadCompTrans(reqData, msg);
                    _totalStat.loadCompTrans(reqData, msg);
                    currSlot.numCompTxns++;
                    _totalStat.numCompTxns++;
                }
                
                if(msg.respReq.equals("BYE"))
                {
                    if(_callMap.remove(msg.callId))
                    {
                        currSlot.numCompCalls++;
                        _totalStat.numCompCalls++;
                    }
                }
            }
        }

        currSlot.loadMessage(msg);
        _totalStat.loadMessage(msg);
    }
    
    public synchronized void getLoadData(TimeSlotModalData data, boolean compFlag)
    {
        data.activeCalls = _callMap.size();
        data.activeTransactions = _txnMap.size();
        _totalStat.copyTo(data.compData);
        
        int endSlot = _currSlotNum;
        int startSlot = endSlot - data.duration;
        
        if(compFlag)
        {
            endSlot++;
            startSlot++;
        }
        
        if(endSlot < 0) endSlot = 0;
        if(startSlot < 0) startSlot = 0;
        
        for(int idx = startSlot; idx < endSlot; idx++)
        {
            _secSlot[idx].copyTo(data.durationData);
        }
    }

    public synchronized void clearData()
    {
        _callMap.clear();
        _txnMap.clear();
        _totalStat.reset();
        
        for(int idx = 0; idx < _secSlot.length; idx++)
        {
            _secSlot[idx].reset();
        }
        
        _currSlotNum = 0;
    }
}
