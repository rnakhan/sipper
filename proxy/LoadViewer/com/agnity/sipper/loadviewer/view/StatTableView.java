package com.agnity.sipper.loadviewer.view;

import java.util.Vector;
import java.util.Map.Entry;

import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.AbstractTableModel;

import com.agnity.sipper.loadviewer.data.TimeSlotData;
import com.agnity.sipper.loadviewer.data.TimeSlotData.TxnInfo;

public class StatTableView extends JPanel
{
    private static final long serialVersionUID = 1L;
    class DataModal extends AbstractTableModel
    {
        private static final long serialVersionUID = 1L;

        class Pair        
        {
            String name;
            Object value;
            Pair(String inName, Long inValue)
            {
                name = inName;
                value = inValue;
            }
            
            public Pair(String inName, String inValue)
            {
                name = inName;
                value = inValue;
            }
        };
        
        Vector<Pair> elements = new Vector<Pair>();
        
        DataModal(TimeSlotData data)
        {         
            elements.add(new Pair("Messages:", data.numMsgs));
            elements.add(new Pair("DroppedMessages:", data.numDroppedMsgs));
            elements.add(new Pair("Requests:", data.numReqs));
            elements.add(new Pair("Responses:", data.numMsgs - data.numReqs));
            elements.add(new Pair("Incoming:", data.numIncomings));
            elements.add(new Pair("Outgoing:", data.numMsgs - data.numIncomings));
            elements.add(new Pair("ReqRetrans:", data.numReqRetrans));
            elements.add(new Pair("ResRetrans:", data.numResRetrans));
            elements.add(new Pair("ProvisionalResp:", data.numProvisionalResp));            
            elements.add(new Pair("NewCalls:", data.numNewCalls));
            elements.add(new Pair("CompCalls:", data.numCompCalls));            
            elements.add(new Pair("NewTrans:", data.numNewTxns));
            elements.add(new Pair("CompTrans:", data.numCompTxns));
            
            for(Entry<String, Long> entry:data.incomingMsgMap.entrySet())
            {
                elements.add(new Pair("--> " + entry.getKey(), entry.getValue()));
            }
            for(Entry<String, Long> entry:data.outgoingMsgMap.entrySet())
            {
                elements.add(new Pair("<-- " + entry.getKey(), entry.getValue()));
            }
            for(Entry<String, TxnInfo> entry:data.incomingTxnMap.entrySet())
            {
                elements.add(new Pair("Txn --> " + entry.getKey(), entry.getValue().toString()));
            }
            for(Entry<String, TxnInfo> entry:data.outgoingTxnMap.entrySet())
            {
                elements.add(new Pair("Txn <-- " + entry.getKey(), entry.getValue().toString()));
            }
        }
        
        @Override
        public int getColumnCount()
        {            
            return 2;
        }

        @Override
        public int getRowCount()
        {
            return elements.size();
        }

        @Override
        public Object getValueAt(int rowIndex, int columnIndex)
        {
            Pair val = elements.get(rowIndex);
            
            if(columnIndex == 0)
            {
                return val.name;
            }
            return val.value;
        }
    }
    
    JTable table = new JTable();
    
    public StatTableView(TimeSlotData timeSlotData)
    {   
        add(new JScrollPane(table));
        setDataModal(timeSlotData);
    }

    public void setDataModal(TimeSlotData data)
    {
        DataModal model = new DataModal(data);
        table.setModel(model);
    }
}
