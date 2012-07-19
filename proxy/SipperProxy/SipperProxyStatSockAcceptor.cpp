#include "SipperProxyLogger.h"
LOG("StatSockAcceptor");
#include "SipperProxyStatMgr.h"
#include "SipperProxyStatSockDispatcher.h"

void * SipperProxyStatSockAcceptor::_threadStart(void *inData)
{
   pthread_detach(pthread_self());
   SipperProxyRefObjHolder<SipperProxyStatSockAcceptor> holder((SipperProxyStatSockAcceptor *)inData);
                     
   SipperProxyStatSockAcceptor *obj = holder.getObj();
   obj->_mgr->addAcceptor(obj);
   obj->_processIncomingConnections();
   obj->_mgr->removeAcceptor(obj);
   return NULL;
}

SipperProxyStatSockAcceptor::~SipperProxyStatSockAcceptor()
{
   SipperProxyPortable::disconnectSocket(_sock);
}

int SipperProxyStatSockAcceptor::_openSocket(unsigned short port)
{
   _sock = socket(AF_INET, SOCK_STREAM, 0);

   u_int flagOn = 1;
#ifndef __UNIX__
   setsockopt(_sock, SOL_SOCKET, SO_REUSEADDR, (const char *)&flagOn, sizeof(flagOn));
#else
   setsockopt(_sock, SOL_SOCKET, SO_REUSEADDR, &flagOn, sizeof(flagOn));
#endif

   sockaddr_in svrInfo;
   memset(&svrInfo, 0, sizeof(sockaddr_in));

   svrInfo.sin_family = AF_INET;
   svrInfo.sin_addr.s_addr = INADDR_ANY;
   svrInfo.sin_port = htons(port);

   if(bind(_sock, (struct sockaddr *)&svrInfo, sizeof(sockaddr_in)) == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "Unable to bind to Port[%d] Error[%s].\n",
             port, SipperProxyPortable::errorString().c_str());
      SipperProxyPortable::disconnectSocket(_sock);
      return -1;
   }

   if(listen(_sock, 5) == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "Listen call failed for Port[%d] Error[%s].\n",
        port, SipperProxyPortable::errorString().c_str());
      SipperProxyPortable::disconnectSocket(_sock);
      return -2;
   }

   SipperProxyPortable::setNonBlocking(_sock);
   SipperProxyPortable::setTcpNoDelay(_sock);

   return 0;
}

void SipperProxyStatSockAcceptor::_processIncomingConnections()
{
   fd_set read_fds;

   while(true)
   {
      {
         MutexGuard(&_mutex);
         if(_shutdownFlag) return;
      }

      FD_ZERO(&read_fds);
      FD_SET(_sock, &read_fds);

      struct timeval time_out;
      time_out.tv_sec = 1;
      time_out.tv_usec = 0;

      if(select(_sock + 1, &read_fds, NULL, NULL, &time_out) == -1)
      {
         std::string errMsg = SipperProxyPortable::errorString();
         logger.logMsg(ERROR_FLAG, 0, "Error getting socket status. [%s]\n",
                       errMsg.c_str());
         continue;
      }

      if(FD_ISSET(_sock, &read_fds))
      {
         struct sockaddr_in cliAddr;
         memset(&cliAddr, 0, sizeof(cliAddr));

#ifdef __UNIX__
         socklen_t len = sizeof(cliAddr);
#else
         int len = sizeof(cliAddr);
#endif
         int accSock = accept(_sock, (struct sockaddr *)&cliAddr, &len);

         if(accSock == -1)
         {
            std::string errMsg = SipperProxyPortable::errorString();
            logger.logMsg(ERROR_FLAG, 0, "Accept failed for [%d]. [%s]\n",
                   _sock, errMsg.c_str());
            continue;
         }

         logger.logMsg(ALWAYS_FLAG, 0, "Accepted connection Sock[%d] From IP[%s] Port[%d]\n",
                accSock, inet_ntoa(cliAddr.sin_addr),
                ntohs(cliAddr.sin_port));

         SipperProxyPortable::setNonBlocking(accSock);
         SipperProxyPortable::setTcpNoDelay(accSock);

         SipperProxyRefObjHolder<SipperProxyStatDispatcher> holder(new SipperProxyStatSockDispatcher(accSock, _mgr));
      }
   }
}
