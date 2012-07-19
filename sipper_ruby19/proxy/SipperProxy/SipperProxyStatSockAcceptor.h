#ifndef __STAT_SOCK_ACCEPTOR_H__
#define __STAT_SOCK_ACCEPTOR_H__

#include "SipperProxyRef.h"
#include "SipperProxyLock.h"
#include <string>

class SipperProxyStatMgr;

class SipperProxyStatSockAcceptor : public SipperProxyRef
{
   private:

      SipperProxyStatMgr *_mgr;
      bool _shutdownFlag;
      SipperProxyMutex _mutex;
      int _sock;

      static void * _threadStart(void *inData);

   public:

      SipperProxyStatSockAcceptor(unsigned short port,
                                  SipperProxyStatMgr *mgr) :
         _mgr(mgr),
         _shutdownFlag(false),
         _sock(-1)
      {
         if(_openSocket(port) != 0)
         {
            return;
         }

         pthread_t thread;
         addRef();
         pthread_create(&thread, NULL, _threadStart, this);
      }
      ~SipperProxyStatSockAcceptor();

      void shutdown()
      {
         MutexGuard(&_mutex);
         _shutdownFlag = true;
      }

   private:

      int _openSocket(unsigned short port);
      void _processIncomingConnections();
};

#endif
