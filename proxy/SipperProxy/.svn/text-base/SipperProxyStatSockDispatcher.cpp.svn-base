#include "SipperProxyLogger.h"
LOG("ProxyStatSock");
#include "SipperProxyStatSockDispatcher.h"
#include <sstream>

SipperProxyStatSockDispatcher::SipperProxyStatSockDispatcher(
          int accSock, SipperProxyStatMgr *mgr) :
   SipperProxyStatDispatcher(mgr),
   _sock(accSock)
{
   pthread_t thread;
   addRef();
   pthread_create(&thread, NULL, _threadStart, this);
}

SipperProxyStatSockDispatcher::~SipperProxyStatSockDispatcher()
{
   SipperProxyPortable::disconnectSocket(_sock);
}

void SipperProxyStatSockDispatcher::_processData()
{
   bool errorFlag = false;
   while(!_queue.isQueueStopped())
   {
      errorFlag = false;
      SipperProxyQueueData inMsg[500];
      int msgCount = _queue.eventDequeueBlk(inMsg, 500, 1000, true);

      char locBuf[0x10000];
      unsigned int locBufLen = 0;

      for(int idx = 0; idx < msgCount; idx++)
      {
         SipperProxyRefObjHolder<SipperProxyRawMsg> holder((SipperProxyRawMsg *) (inMsg[idx].data));
         SipperProxyRawMsg *msg = holder.getObj();
         unsigned int msgLen = 0;
         char *buffer = msg->getBuf(msgLen);

         if((0x10000 - locBufLen) > msgLen)
         {
            memcpy(locBuf + locBufLen, buffer, msgLen);
            locBufLen += msgLen;
            continue;
         }
         else
         {
            if(!errorFlag)
            {
               if(_sendSocket(locBuf, locBufLen) != 0)
               {
                  errorFlag = true;
                  _queue.stopQueue();
               }

               locBufLen = 0;
            }
            if(!errorFlag)
            {
               if(_sendSocket(buffer, msgLen) != 0)
               {
                  errorFlag = true;
                  _queue.stopQueue();
               }
            }
         }
      }

      if(!errorFlag)
      {
         if(_sendSocket(locBuf, locBufLen) != 0)
         {
            errorFlag = true;
            _queue.stopQueue();
         }

         locBufLen = 0;
      }
   }

   return;
}

int SipperProxyStatSockDispatcher::_sendSocket(char *buf, unsigned int toSend)
{
   int retVal = 0;

   fd_set write_fds;

   while(toSend)
   {
      retVal = send(_sock, buf, toSend, 0);

      if(retVal >= 0)
      {
         buf += retVal;
         toSend -= retVal;
         continue;
      }

      switch(SipperProxyPortable::getErrorCode())
      {
#ifdef __UNIX__
         case EINTR:
#else
         case WSAEINTR:
#endif
         {
               logger.logMsg(ERROR_FLAG, 0,
                             "Send interrupted. [%d] Msg[%s].\n",
                         _sock, strerror(SipperProxyPortable::getErrorCode()));
             continue;
         }
#ifdef __UNIX__
         case EAGAIN:
#else
         case WSAEWOULDBLOCK:
#endif
         {
         }
         break;

         default:
         {
            logger.logMsg(ERROR_FLAG, 0,
                          "Error in sending [%d] Msg[%s].\n",
                          _sock, strerror(SipperProxyPortable::getErrorCode()));
            return -1;
         }
      }

      FD_ZERO(&write_fds);  FD_SET(_sock, &write_fds);

      struct timeval time_out;

      time_out.tv_sec = 5;
      time_out.tv_usec = 0;

      logger.logMsg(WARNING_FLAG, 0,
                    "Waiting for buffer clearup. Sock[%d].\n",
                    _sock);

      retVal = select(_sock + 1, NULL, &write_fds, NULL, &time_out);

      if(retVal == 0)
      {
         logger.logMsg(ERROR_FLAG, 0,
                       "Write select timedout.\n");
         return -1;
      }
   }

   return 0;
}
