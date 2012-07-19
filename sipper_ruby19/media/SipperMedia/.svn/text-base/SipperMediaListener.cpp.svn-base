#include "SipperMediaLogger.h"
LOG("Listener");
#include "SipperMediaConfig.h"
#include "SipperMediaListener.h"
#include "SipperMediaController.h"
#include "SipperMediaPortable.h"
#include "SipperMediaLogMgr.h"

#include <stdio.h>
#include <pthread.h>
#include <string.h>

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/tcp.h>
#endif

int main(int argc, char**argv)
{
   std::string configFile("SipperMedia.cfg");
   std::string logFile("SipperMediaLog.lcfg");
   unsigned short port = 0;
   
   for(int idx = 1; (idx + 1) < argc; idx += 2)
   {
      std::string option = argv[idx];
      std::string value = argv[idx + 1];

      //printf("Processing CommandLine [%s] [%s]\n", 
      //       option.c_str(), value.c_str());

      if(option == "-c")
      {
        configFile = value;
      }  
      else if(option == "-p") 
      { 
        port = atoi(value.c_str());
      }  
      else if(option == "-l") 
      { 
        logFile = value;
      }  
   }

   LogMgr::instance().init(logFile.c_str());
   SipperMediaConfig &config = SipperMediaConfig::getInstance();
   config.loadConfigFile(configFile);

   unsigned int threshold = atoi(config.getConfig("Global", "SilentThreshold", "256").c_str());
   threshold &= 0xffff;
   SipperMediaCodec::silentThreshold = threshold;
   logger.logMsg(ALWAYS_FLAG, 0, "Using SilentThreshold [%d]\n", SipperMediaCodec::silentThreshold);

   unsigned int silentDuration = atoi(config.getConfig("Global", "SilentDurationMSecs", "2000").c_str());
   if(silentDuration > 10000)
   {
      silentDuration = 10000;
   }
   SipperMediaCodec::silentDuration = silentDuration;
   logger.logMsg(ALWAYS_FLAG, 0, "Using SilentDurationMSecs [%d]\n", SipperMediaCodec::silentDuration);
   SipperMediaCodec::silentDuration *= 1000;

   unsigned int voiceDuration = atoi(config.getConfig("Global", "VoiceDurationMSecs", "200").c_str());
   if(voiceDuration > 3000)
   {
      voiceDuration = 3000;
   }
   SipperMediaCodec::voiceDuration = voiceDuration;
   logger.logMsg(ALWAYS_FLAG, 0, "Using VoiceDurationMSecs [%d]\n", SipperMediaCodec::voiceDuration);
   SipperMediaCodec::voiceDuration *= 1000;

   unsigned int audioStopDuration = atoi(config.getConfig("Global", "AudioStopDuration", "5").c_str());
   if(audioStopDuration > 10)
   {
      audioStopDuration = 10;
   }
   SipperMediaCodec::audioStopDuration = audioStopDuration;
   logger.logMsg(ALWAYS_FLAG, 0, "Using AudioStopDuration [%d]\n", SipperMediaCodec::audioStopDuration);

   SipperMediaListener listener;
   if(port == 0) {
     port = atoi(config.getConfig("Global", "ListenPort", "4680").c_str());
   }
   logger.logMsg(ALWAYS_FLAG, 0, "Using port [%d]\n", port);
   int ret = listener.startListener(port);

   logger.logMsg(ALWAYS_FLAG, 0, "SipperMedia program ended.\n");

   return ret;
}

struct SipperMediaListenerThreadData
{
   int socket;
   SipperMediaListener *listener;
};

SipperMediaListener::SipperMediaListener()
{
   _shutdownFlag = false;
   SipperMediaPortable::getTimeOfDay(&_lastActivityTime);              
}

int SipperMediaListener::startListener(unsigned short port)
{
#ifndef __UNIX__
   WSADATA wsaData;
   int iResult;

   iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
   if (iResult != 0) 
   {
      logger.logMsg(ERROR_FLAG, 0, "WSAStartup failed: %d\n", iResult);
      exit(1);
   }
#endif

   SipperMediaConfig &config = SipperMediaConfig::getInstance();
   int inActiveDuration = atoi(config.getConfig("Global", "InActiveDuration", "300").c_str());

   if(inActiveDuration < 0)
   {
      logger.logMsg(ERROR_FLAG, 0, "InActiveTimer is -ve. Using default Value\n");
      inActiveDuration = 300;
   }

   _shutdownFlag = false;
   int sock = socket(AF_INET, SOCK_STREAM, 0);

   u_int flagOn = 1;
#ifndef __UNIX__
   setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const char *)&flagOn, sizeof(flagOn));
#else
   setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &flagOn, sizeof(flagOn));
#endif

   sockaddr_in svrInfo;
   memset(&svrInfo, 0, sizeof(sockaddr_in));

   svrInfo.sin_family = AF_INET;
   svrInfo.sin_addr.s_addr = INADDR_ANY;
   svrInfo.sin_port = htons(port);

   if(bind(sock, (struct sockaddr *)&svrInfo, sizeof(sockaddr_in)) == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "Unable to bind to Port[%d] Error[%s].\n",
             port, SipperMediaListener::errorString().c_str());
      SipperMediaListener::disconnectSocket(sock);
      return -1;
   }

   if(listen(sock, 5) == -1)
   {
      logger.logMsg(ERROR_FLAG, 0, "Listen call failed for Port[%d] Error[%s].\n",
        port, SipperMediaListener::errorString().c_str());
      SipperMediaListener::disconnectSocket(sock);
      return -2;
   }

   SipperMediaListener::setNonBlocking(sock);
   SipperMediaListener::setTcpNoDelay(sock);

   fd_set read_fds;

   while(true)
   {
      FD_ZERO(&read_fds);
      FD_SET(sock, &read_fds);

      if(inActiveDuration > 0)
      {
         MutexGuard(&_mutex);
         struct timeval currtime;
         SipperMediaPortable::getTimeOfDay(&currtime);

         if(currtime.tv_sec > (_lastActivityTime.tv_sec + inActiveDuration))
         {
            if(_controllerMap.size() == 0)
            {
               logger.logMsg(ALWAYS_FLAG, 0, "Shutdown on inActivity.");
               _shutdownFlag = true;
               break;
            }
         }
      }

      struct timeval time_out;
      time_out.tv_sec = 1;
      time_out.tv_usec = 0;

      if(select(sock + 1, &read_fds, NULL, NULL, &time_out) == -1)
      {
         std::string errMsg = SipperMediaListener::errorString();
         logger.logMsg(ERROR_FLAG, 0, "Error getting socket status. [%s]\n",
                       errMsg.c_str());
         continue;
      }

      if(_shutdownFlag)
      {
         break;
      }

      if(FD_ISSET(sock, &read_fds))
      {
         struct sockaddr_in cliAddr;
         memset(&cliAddr, 0, sizeof(cliAddr));

#ifdef __UNIX__
         socklen_t len = sizeof(cliAddr);
#else
         int len = sizeof(cliAddr);
#endif
         int accSock = accept(sock, (struct sockaddr *)&cliAddr, &len);

         if(accSock == -1)
         {
            std::string errMsg = SipperMediaListener::errorString();
            logger.logMsg(ERROR_FLAG, 0, "Accept failed for [%d]. [%s]\n",
                   sock, errMsg.c_str());
            continue;
         }

         logger.logMsg(ALWAYS_FLAG, 0, "Accepted connection Sock[%d] From IP[%s] Port[%d]\n",
                accSock, inet_ntoa(cliAddr.sin_addr), 
                ntohs(cliAddr.sin_port));

         SipperMediaListener::setNonBlocking(accSock);
         SipperMediaListener::setTcpNoDelay(accSock);

         {
            MutexGuard(&_mutex);
            SipperMediaPortable::getTimeOfDay(&_lastActivityTime);              
         }

         pthread_t currthread;

         SipperMediaListenerThreadData *thrData = new SipperMediaListenerThreadData;
         thrData->listener = this;
         thrData->socket = accSock;

         pthread_create(&currthread, NULL, SipperMediaListener::_startControllerThread, (void *)thrData);
      }
   }

   SipperMediaListener::disconnectSocket(sock);

   this->shutdown();

   {
      MutexGuard(&_mutex);
      while(_controllerMap.size() > 0)
      {
        logger.logMsg(ALWAYS_FLAG, 0, "Waiting for [%d] controllers to exit.\n", _controllerMap.size());
         MutexWait(1000);
      }
   }

#ifndef __UNIX__
   Sleep(100);
#else
   sleep(1);
#endif
   logger.logMsg(ALWAYS_FLAG, 0, "Listener ended.\n");
   return 0;
}

void * SipperMediaListener::_startControllerThread(void *inData)
{
   pthread_detach(pthread_self());
   SipperMediaListenerThreadData *thrData = (SipperMediaListenerThreadData *)inData;
   int accSock = thrData->socket;

   logger.logMsg(ALWAYS_FLAG, 0, "Controller [%d] started.\n", accSock);

   thrData->listener->_handleAcceptedController(accSock);
   SipperMediaListener::disconnectSocket(thrData->socket);
   logger.logMsg(ALWAYS_FLAG, 0, "Controller [%d] stopped.\n", accSock);

   delete thrData;
   return NULL;
}

void SipperMediaListener::addController(int accSock, SipperMediaController *controller)
{
   MutexGuard(&_mutex);
   _controllerMap[accSock] = controller;
   SipperMediaPortable::getTimeOfDay(&_lastActivityTime);              
}

void SipperMediaListener::removeController(int accSock)
{
   MutexGuard(&_mutex);
   _controllerMap.erase(accSock);
   MutexSignal();
   SipperMediaPortable::getTimeOfDay(&_lastActivityTime);              
}

void SipperMediaListener::shutdown()
{   
   logger.logMsg(ALWAYS_FLAG, 0, "Shutdown called on listener. \n");
   MutexGuard(&_mutex);
   _shutdownFlag = true;
   for(SipperMediaControllerMapIt it = _controllerMap.begin(); it != _controllerMap.end(); ++it)
   {
      logger.logMsg(ALWAYS_FLAG, 0, "Shutdown called on controller[%d]. \n", it->first);
      it->second->shutdown();
   }
   return;
}

void SipperMediaListener::_handleAcceptedController(int accSock)
{
   SipperMediaController controller;
   controller.listener = this;

   addController(accSock, &controller);
   controller.handleRequest(accSock);
   removeController(accSock);
}

void SipperMediaListener::setNonBlocking(int fd)
{
#ifdef __UNIX__
   int flags;

   if((flags = fcntl(fd, F_GETFL, 0)) < 0)
   {
     std::string errMsg = SipperMediaListener::errorString();

      logger.logMsg(ERROR_FLAG, 0, "Error getting socket status. [%s]\n",
             errMsg.c_str());

      exit(1);
   }

   flags |= O_NONBLOCK;

   if(fcntl(fd, F_SETFL, flags) < 0)
   {
     std::string errMsg = SipperMediaListener::errorString();

      logger.logMsg(ERROR_FLAG, 0, "Error setting nonBlocking. [%s]\n",
             errMsg.c_str());

      exit(1);
   }
#else
   unsigned long flag = 1;
   if(ioctlsocket(fd, FIONBIO, &flag) != 0)
   {
     std::string errMsg = SipperMediaListener::errorString();

      printf("Error setting nonBlocking. [%s]\n",
             errMsg.c_str());

      exit(1);
   }
#endif
}

void SipperMediaListener::disconnectSocket(int &fd)
{
   if(fd != -1)
   {
#ifdef __UNIX__
      close(fd);
#else
      closesocket(fd);
#endif
      fd = -1;
   }
}

void SipperMediaListener::setTcpNoDelay(int fd)
{
   int flag = 1;
#ifdef __UNIX__
   if(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(int)) < 0)
#else
   if(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (const char *)&flag, sizeof(int)) < 0)
#endif
   {
     std::string errMsg = SipperMediaListener::errorString();

      logger.logMsg(ERROR_FLAG, 0, "Error disabling Nagle algorithm. [%s]\n",
             errMsg.c_str());

      exit(1);
   }

   logger.logMsg(ALWAYS_FLAG, 0, "Successfully changed the Sock[%d] options.\n",
          fd);
}


std::string SipperMediaListener::errorString()
{
   std::string ret = (const char *) strerror(SipperMediaPortable::getErrorCode());
   return ret;
}
