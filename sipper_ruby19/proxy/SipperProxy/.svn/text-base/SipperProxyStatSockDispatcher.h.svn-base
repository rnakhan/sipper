#ifndef __STAT_SOCK_DISPATCHER_H__
#define __STAT_SOCK_DISPATCHER_H__

#include "SipperProxyStatMgr.h"

class SipperProxyStatSockDispatcher : public SipperProxyStatDispatcher
{
   private:

      static void * _threadStart(void *inData)
      {
         pthread_detach(pthread_self());
         SipperProxyRefObjHolder<SipperProxyStatSockDispatcher> holder((SipperProxyStatSockDispatcher *)inData);

         SipperProxyStatSockDispatcher *obj = holder.getObj();
         obj->_mgr->addDispatcher(obj);
         obj->_processData();
         obj->_mgr->removeDispathcer(obj);
         return NULL;
      }

   private:
      
      int _sock;

   public:

      SipperProxyStatSockDispatcher(int accSock,
                                    SipperProxyStatMgr *mgr);
      ~SipperProxyStatSockDispatcher();

   private:

      void _processData();
      int _sendSocket(char *buf, unsigned int toSend);
};

#endif
