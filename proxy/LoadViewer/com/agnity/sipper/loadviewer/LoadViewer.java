package com.agnity.sipper.loadviewer;

import javax.swing.JFrame;

import com.agnity.sipper.loadviewer.data.SipMsgData;
import com.agnity.sipper.loadviewer.data.TimeSlotModalData;
import com.agnity.sipper.loadviewer.view.StatisticsViewerPanel;

public class LoadViewer
{
    String          _ip;
    short           _port;
    LoadDataManager _dataManager;

    public LoadViewer(String ip, short port) throws Exception
    {
        _ip = ip;
        _port = port;
        _dataManager = new LoadDataManager();

        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run()
            {
                try
                {
                    _displayStart();
                }
                catch(Exception e)
                {
                    e.printStackTrace();
                }
            }
        });

        new Thread() {
            public void run()
            {
                boolean firstTry = true;
                while(true)
                {
                    try
                    {
                        if(!firstTry)
                        {
                            Thread.sleep(1000);
                        }
                        firstTry = false;
                        SockDataReader _reader = new SockDataReader(_ip, _port, LoadViewer.this);
                        _reader.startRead();
                    }
                    catch(Exception e)
                    {
                        e.printStackTrace();
                    }
                }
            }
        }.start();

        while(true)
        {
            Thread.sleep(5000);
        }
    }

    public static void main(String[] args) throws Exception
    {
        new LoadViewer(args[0], Short.parseShort(args[1]));
    }

    /**
     * @param msg
     */
    /**
     * @param msg
     */
    public void processIncomingMsg(SipMsgData msg)
    {
        _dataManager.loadData(msg);
    }

    public void getData(TimeSlotModalData data, boolean compFlag)
    {
        _dataManager.getLoadData(data, compFlag);
    }

    private void _displayStart()
    {
        JFrame.setDefaultLookAndFeelDecorated(true);
        JFrame frame = new JFrame("Statistics viewer");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        frame.setContentPane(new StatisticsViewerPanel(this));

        frame.pack();
        frame.setVisible(true);
    }

    public void clearData()
    {
        _dataManager.clearData();
    }
}
