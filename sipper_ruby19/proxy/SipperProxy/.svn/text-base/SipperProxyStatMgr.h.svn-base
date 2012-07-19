#ifndef __SIPPER_PROXY_STAT_MGR_H__
#define __SIPPER_PROXY_STAT_MGR_H__

#include "SipperProxyStatSockAcceptor.h"
#include "SipperProxyRawMsg.h"
#include "SipperProxyLock.h"

class SipperProxyStatMgr;
class SipperProxyStatDispatcher : public SipperProxyRef
{
   protected:

      SipperProxyQueue _queue;
      SipperProxyStatMgr *_mgr;

   private:

      static void _queueMsgCleanup(SipperProxyQueueData indata)
      {
         SipperProxyRawMsg *rmsg = (SipperProxyRawMsg *)indata.data;
         rmsg->removeRef();
      }

   public:

      SipperProxyStatDispatcher(SipperProxyStatMgr *mgr) :
         _queue(false, SIPPER_PROXY_PRELOAD_MSG, SIPPER_PROXY_PRELOAD_MSG),
         _mgr(mgr)
      {
         _queue.registerCleanupFunc(_queueMsgCleanup);
      }

      void shutdown()
      {
         _queue.stopQueue();
      }

      void loadMessage(SipperProxyRawMsg *rmsg)
      {
         rmsg->addRef();
         SipperProxyQueueData queueMsg;
         queueMsg.data = rmsg;
         if(_queue.eventEnqueue(&queueMsg) != 1)
         {
            rmsg->removeRef();
         }
      }
};

#define MAX_MSG_DISPATHERS 5
#define MAX_SOCK_ACCEPTORS 5

class SipperProxyStatMgr
{
   private:

      static SipperProxyStatMgr *_instance;
      SipperProxyMutex _mutex;

      SipperProxyStatDispatcher   *_dispatchers[MAX_MSG_DISPATHERS];
      SipperProxyStatSockAcceptor *_acceptors[MAX_MSG_DISPATHERS];

   public:
   
      static SipperProxyStatMgr * getInstance()
      {
         if(_instance == NULL)
         {
            _instance = new SipperProxyStatMgr();
            _instance->_init();
         }

         return _instance;
      }

   private:

      SipperProxyStatMgr() 
      {
         for(int idx = 0; idx < MAX_MSG_DISPATHERS; idx++)
         {
            _dispatchers[idx] = NULL;
         }
      };

      void _init();

   public:

      int addDispatcher(SipperProxyStatDispatcher *dispatcher)
      {
         {
            MutexGuard(&_mutex);
            for(int idx = 0; idx < MAX_MSG_DISPATHERS; idx++)
            {
               if(_dispatchers[idx] == dispatcher) return 0;
            }

            for(int idx = 0; idx < MAX_MSG_DISPATHERS; idx++)
            {
               if(_dispatchers[idx] == NULL) 
               {
                  dispatcher->addRef();
                  _dispatchers[idx] = dispatcher;
                  return 0;
               }
            }
         }

         dispatcher->shutdown();
         return -1;
      }

      void removeDispathcer(SipperProxyStatDispatcher *dispatcher)
      {
         dispatcher->shutdown();
         {
            MutexGuard(&_mutex);
            for(int idx = 0; idx < MAX_MSG_DISPATHERS; idx++)
            {
               if(_dispatchers[idx] == dispatcher) 
               {
                  dispatcher->removeRef();
                  _dispatchers[idx] = NULL;
               }
            }
         }
      }

      int addAcceptor(SipperProxyStatSockAcceptor *acceptor)
      {
         {
            MutexGuard(&_mutex);
            for(int idx = 0; idx < MAX_SOCK_ACCEPTORS; idx++)
            {
               if(_acceptors[idx] == acceptor) return 0;
            }

            for(int idx = 0; idx < MAX_SOCK_ACCEPTORS; idx++)
            {
               if(_acceptors[idx] == NULL) 
               {
                  acceptor->addRef();
                  _acceptors[idx] = acceptor;
                  return 0;
               }
            }
         }

         acceptor->shutdown();
         return -1;
      }

      void removeAcceptor(SipperProxyStatSockAcceptor *acceptor)
      {
         acceptor->shutdown();
         {
            MutexGuard(&_mutex);
            for(int idx = 0; idx < MAX_SOCK_ACCEPTORS; idx++)
            {
               if(_acceptors[idx] == acceptor) 
               {
                  acceptor->removeRef();
                  _acceptors[idx] = NULL;
               }
            }
         }
      }

      void publish(SipperProxyRawMsg *rmsg)
      {
         MutexGuard(&_mutex);
         for(int idx = 0; idx < MAX_MSG_DISPATHERS; idx++)
         {
            if(_dispatchers[idx] != NULL) 
            {
               _dispatchers[idx]->loadMessage(rmsg);
            }
         }
      }
};

#endif
