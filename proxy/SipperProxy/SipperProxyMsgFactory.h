#ifndef __SIPPER_PROXY_MSG_FACTORY_H__
#define __SIPPER_PROXY_MSG_FACTORY_H__

#include <string>
#include "SipperProxyQueue.h"

#define SIPPER_PROXY_PRELOAD_MSG 2000
#define SIPPER_PROXY_DEF_MSGLEN 200

template <class _MSG>
class SipperProxyMsgFactory 
{
   private:

      SipperProxyQueue _outQueue;
      SipperProxyQueue _inQueue;

      std::string _name;

      unsigned int _numMsg;

   private:

      static void _queueMsgCleanup(SipperProxyQueueData indata);

   public:

      SipperProxyMsgFactory(unsigned int noMsg);
      void setLen(unsigned int noMsg);

      void close();

      _MSG * getMsg();
      void putMsg(_MSG *);

      void setName(const std::string &inName)
      {
         _name = inName;
      }

   public:

      std::string toLog(unsigned int tabCount) const;
};

template <class _MSG>
void SipperProxyMsgFactory<_MSG>::_queueMsgCleanup(SipperProxyQueueData indata)
{
   _MSG *currMsg = (_MSG *)indata.data;
   currMsg->removeRef();
}

template <class _MSG>
SipperProxyMsgFactory<_MSG>::SipperProxyMsgFactory(unsigned int noMsg) :
   _outQueue(false, SIPPER_PROXY_PRELOAD_MSG, SIPPER_PROXY_PRELOAD_MSG),
   _inQueue(false, SIPPER_PROXY_PRELOAD_MSG, SIPPER_PROXY_PRELOAD_MSG),
   _numMsg(0)
{
   _inQueue.setName("CollectBackQ");
   _outQueue.setName("GiveMsgQ");
   SipperProxyQueueData queueMsg;

   for(; _numMsg < noMsg; _numMsg++)
   {
      _MSG *currMsg = new _MSG;
      currMsg->_facObj = true;
      queueMsg.data = currMsg;
      _outQueue.eventEnqueue(&queueMsg);
   }

   _inQueue.registerCleanupFunc(_queueMsgCleanup);
   _outQueue.registerCleanupFunc(_queueMsgCleanup);
}

template <class _MSG>
void SipperProxyMsgFactory<_MSG>::setLen(unsigned int noMsg)
{
   SipperProxyQueueData queueMsg;
   for(; _numMsg < noMsg; _numMsg++)
   {
      _MSG *currMsg = new _MSG;
      currMsg->_facObj = true;
      queueMsg.data = currMsg;
      _outQueue.eventEnqueue(&queueMsg);
   }
}

template <class _MSG>
_MSG * SipperProxyMsgFactory<_MSG>::getMsg() 
{
   _MSG *retMsg;

   SipperProxyQueueData queueMsg;
   unsigned int ret = _outQueue.eventDequeue(&queueMsg, 0, false);

   if(ret == 0)
   {
      SipperProxyQueueData txfrMsg[500];

      unsigned int noTxfr = 0;

      do
      {
         noTxfr = _inQueue.eventDequeueBlk(txfrMsg, 500, 0, false);
         _outQueue.eventEnqueueBlk(txfrMsg, noTxfr);
      }while(noTxfr > 0);

      ret = _outQueue.eventDequeue(&queueMsg, 0, false);

      if(ret == 0)
      {
         retMsg = new _MSG;
      }
      else
      {
         retMsg = (_MSG *) queueMsg.data;
      }
   }
   else
   {
      retMsg = (_MSG *) queueMsg.data;
   }

   retMsg->addRef();
   return retMsg;
}

template <class _MSG>
void SipperProxyMsgFactory<_MSG>::putMsg(_MSG *inMsg) 
{
   if(!inMsg->_facObj)
   {
      inMsg->removeRef();
      return;
   }

   inMsg->reset();

   SipperProxyQueueData queueMsg;
   queueMsg.data = inMsg;
   if(_inQueue.eventEnqueue(&queueMsg) == 0)
   {
      inMsg->removeRef();
      return;
   }

   return ;
}

template <class _MSG>
void SipperProxyMsgFactory<_MSG>::close() 
{
   _outQueue.stopQueue();
   _inQueue.stopQueue();
}

template <class _MSG>
std::string SipperProxyMsgFactory<_MSG>::toLog(unsigned int tabCount) const
{
   if(tabCount > 19)
   {
      tabCount = 19;
   }

   char tabs[20];

   for(unsigned int idx = 0; idx < tabCount; idx++)
   {
      tabs[idx] = '\t';
   }

   tabs[tabCount] = '\0';

   std::string ret;
   ret += tabs; ret += "<Factory Name=\""; ret += _name + "\">\n";

   ret += _inQueue.toLog(tabCount + 1);
   ret += _outQueue.toLog(tabCount + 1);

   ret += tabs; ret += "</Factory>\n";
   return ret;
}

#endif
