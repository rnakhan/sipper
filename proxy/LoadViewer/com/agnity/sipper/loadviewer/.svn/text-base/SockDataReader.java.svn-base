package com.agnity.sipper.loadviewer;

import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.util.logging.Logger;

import com.agnity.sipper.loadviewer.data.SipMsgData;

public class SockDataReader
{
    static Logger logger    = Logger.getLogger(SockDataReader.class.toString());
    SocketChannel _channel;
    Selector      _readSel;
    ByteBuffer    _rdBuffer = null;
    LoadViewer    _mgr      = null;

    public SockDataReader(String ip, short port, LoadViewer mgr) throws Exception
    {
        _mgr = mgr;
        while(true)
        {
            try
            {
                _channel = SocketChannel.open(new InetSocketAddress(ip, port));
                break;
            }
            catch(Exception exp)
            {
                System.out.println("Unable to connect will retry after a sec.");
                Thread.sleep(1000);
                continue;
            }
        }
        _channel.configureBlocking(false);
        _channel.socket().setKeepAlive(true);
        _channel.socket().setTcpNoDelay(true);
        _readSel = Selector.open();
        _channel.register(_readSel, SelectionKey.OP_READ);
        _rdBuffer = ByteBuffer.allocateDirect(0x40000);
        _rdBuffer.order(ByteOrder.BIG_ENDIAN);
    }

    public void startRead()
    {
        _rdBuffer.clear();
        boolean locMsgSent = false;

        while(true)
        {
            int ret = 0;

            try
            {
                ret = _channel.read(_rdBuffer);
            }
            catch(Exception exp)
            {
                exp.printStackTrace(System.err);
                return;
            }

            if(ret == -1)
            {
                System.err.printf("Read returned -1.\n");
                return;
            }

            _rdBuffer.flip();

            int dataCanConsume = _rdBuffer.remaining();

            while(dataCanConsume > 4)
            {
                int currMsgLen = _rdBuffer.getInt(_rdBuffer.position());
                if(currMsgLen > 0x40000)
                {
                    System.err.printf("Stream corrupted Received message of len [%d]\n", currMsgLen);
                    return;
                }

                if(dataCanConsume >= currMsgLen)
                {
                    SipMsgData msg = new SipMsgData();

                    if(msg.parse(_rdBuffer) == -1)
                    {
                        System.err.printf("Error parsing message.\n");
                        return;
                    }

                    dataCanConsume = _rdBuffer.remaining();
                    if(dataCanConsume == 0)
                    {
                        _rdBuffer.clear();
                        _rdBuffer.limit(0);
                        _rdBuffer.position(0);
                    }

                    locMsgSent = true;
                    _mgr.processIncomingMsg(msg);
                }
                else
                {
                    break;
                }

                dataCanConsume = _rdBuffer.remaining();
            }

            if(_rdBuffer.remaining() > 0)
            {
                _rdBuffer.compact();
            }
            else
            {
                _rdBuffer.clear();
            }

            if(ret == 0)
            {
                try
                {
                    if(_readSel.select(1000) == 0)
                    {
                        if(locMsgSent)
                        {
                            locMsgSent = false;
                            _mgr.processIncomingMsg(null);
                        }
                    }
                }
                catch(Exception exp)
                {
                    exp.printStackTrace(System.err);
                }
            }
        }
    }
}
