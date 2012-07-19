package com.agnity.sipper.loadviewer.view;

import java.awt.FlowLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.ButtonGroup;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JRadioButton;

public class DurationSelectorPanel extends JPanel implements ActionListener
{
    private static final long serialVersionUID = 1L;   
    private String _command;
    private StatisticsViewerPanel _parent;
    
    JRadioButton defaultButton;
    
    public DurationSelectorPanel(String command, StatisticsViewerPanel parent)
    {
        _parent = parent;
        _command = command;
        
        setLayout(new FlowLayout(FlowLayout.LEFT));
        
        add(new JLabel(command));
        JRadioButton rbut;        
        ButtonGroup grp = new ButtonGroup();
        rbut = new JRadioButton("1 sec"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("1");
        grp.add(rbut);
        add(rbut);
        defaultButton = rbut;
        
        rbut = new JRadioButton("5 sec"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("5");
        grp.add(rbut);
        add(rbut);

        rbut = new JRadioButton("15 sec"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("15");
        grp.add(rbut);
        add(rbut);

        rbut = new JRadioButton("30 sec"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("30");
        grp.add(rbut);
        add(rbut);
        
        rbut = new JRadioButton("1 min"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("60");
        grp.add(rbut);
        add(rbut);
        
        rbut = new JRadioButton("2 min"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("120");
        grp.add(rbut);
        add(rbut);
        
        rbut = new JRadioButton("3 min"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("180");
        grp.add(rbut);
        add(rbut);
        
        rbut = new JRadioButton("5 min"); 
        rbut.addActionListener(this); 
        rbut.setActionCommand("300");
        grp.add(rbut);        
        add(rbut);
    }

    public void setupButton()
    {
        defaultButton.doClick();
    }
    
    @Override
    public void actionPerformed(ActionEvent e)
    {
        int duration = Integer.parseInt(e.getActionCommand());
        _parent.handleCommand(_command, duration);
    }
}
