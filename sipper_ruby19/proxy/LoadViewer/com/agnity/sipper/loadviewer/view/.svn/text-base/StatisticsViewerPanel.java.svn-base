package com.agnity.sipper.loadviewer.view;

import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;

import com.agnity.sipper.loadviewer.LoadViewer;
import com.agnity.sipper.loadviewer.data.TimeSlotModalData;

public class StatisticsViewerPanel extends JPanel
{
    private static final long serialVersionUID = 1L;
    Timer                     _timer           = new Timer();
    ViewerTimerTask           _currTimer       = null;

    class ViewerTimerTask extends TimerTask
    {
        int     _duration;
        int     _refresh;
        boolean _incTillLast;

        class LocTimerTask extends TimerTask
        {
            @Override
            public void run()
            {
                _handleTimer();
            }
        }

        public ViewerTimerTask(int duration, int refresh, boolean incTillLast)
        {
            _duration = duration;
            _refresh = refresh;
            _incTillLast = incTillLast;
        }

        private void _handleTimer()
        {
            if(this != _currTimer) return;

            TimeSlotModalData newData = new TimeSlotModalData();
            newData.duration = _duration;
            newData.refreshDuration = _refresh;
            _parent.getData(newData, _incTillLast);

            javax.swing.SwingUtilities.invokeLater(new DataRefresher(newData));
            _timer.schedule(new LocTimerTask(), _refresh * 1000);
        }

        @Override
        public void run()
        {
            _handleTimer();
        }
    }

    class DataRefresher implements Runnable
    {
        TimeSlotModalData _newData;

        public DataRefresher(TimeSlotModalData newData)
        {
            _newData = newData;
        }

        @Override
        public void run()
        {
            _data.activeCalls = _newData.activeCalls;
            _data.activeTransactions = _newData.activeTransactions;
            _data.compData = _newData.compData;
            _data.durationData = _newData.durationData;

            _activeCalls.setText("" + _data.activeCalls);
            _activeTrans.setText("" + _data.activeTransactions);
            _compTable.setDataModal(_data.compData);
            _durationTable.setDataModal(_data.durationData);
            _dateText.setText("" + new Date(_data.compData.sec * 1000));
        }
    }

    LoadViewer            _parent           = null;
    TimeSlotModalData     _data             = null;

    DurationSelectorPanel _refreshSelector  = null;
    DurationSelectorPanel _durationSelector = null;
    StatTableView         _compTable        = null;
    StatTableView         _durationTable    = null;
    JLabel                _activeCalls      = null;
    JLabel                _activeTrans      = null;
    JLabel _dateText = null;

    public StatisticsViewerPanel(LoadViewer parent)
    {
        _parent = parent;
        _data = new TimeSlotModalData();
        _refreshSelector = new DurationSelectorPanel("Refresh", this);
        _durationSelector = new DurationSelectorPanel("Duration", this);
        _compTable = new StatTableView(_data.compData);
        _durationTable = new StatTableView(_data.durationData);
        _activeCalls = new JLabel();
        _activeTrans = new JLabel();
        setLayout(new BorderLayout());
        JPanel topPanel = new JPanel(new GridLayout(3, 1));
        topPanel.add(_refreshSelector);
        topPanel.add(_durationSelector);

        JPanel textPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        textPanel.add(new JLabel("ActiveCalls"));
        textPanel.add(_activeCalls);
        textPanel.add(new JLabel("ActiveTransactions"));
        textPanel.add(_activeTrans);
        {
            JCheckBox box = new JCheckBox("IncludeTillLastSec");
            box.addItemListener(new ItemListener() {
                @Override
                public void itemStateChanged(ItemEvent e)
                {
                    if(e.getStateChange() == ItemEvent.SELECTED)
                        handleCommand("IncludeTillLastSec", 1);
                    else
                        handleCommand("IncludeTillLastSec", 0);
                }
            });
            textPanel.add(box);
        }
        {
            JButton clearButton = new JButton("ClearData");
            clearButton.addActionListener(new ActionListener() {
                @Override
                public void actionPerformed(ActionEvent e)
                {
                    _timer.schedule(new TimerTask() {
                        @Override
                        public void run()
                        {
                            _parent.clearData();
                        }
                    }, 1);
                    _timer.purge();
                }
            });

            textPanel.add(clearButton);
        }
        {
            textPanel.add(new JLabel("Last update time:"));
            
            _dateText = new JLabel("");
            textPanel.add(_dateText);
        }

        topPanel.add(textPanel);

        JPanel bottomPanel = new JPanel();
        bottomPanel.add(_compTable);
        bottomPanel.add(_durationTable);

        add(topPanel, BorderLayout.NORTH);
        add(new JScrollPane(bottomPanel), BorderLayout.CENTER);

        _refreshSelector.setupButton();
        _durationSelector.setupButton();
    }

    public void handleCommand(String command, int inVal)
    {
        if(command.equals("Refresh"))
        {
            _data.refreshDuration = inVal;
        }
        else if(command.equals("Duration"))
        {
            _data.duration = inVal;
        }
        else if(command.equals("IncludeTillLastSec"))
        {
            _data.includeTillLast = (inVal == 1 ? true : false);
        }

        _currTimer = new ViewerTimerTask(_data.duration, _data.refreshDuration, _data.includeTillLast);
        _timer.schedule(_currTimer, 100);
        _timer.purge();
    }
}
