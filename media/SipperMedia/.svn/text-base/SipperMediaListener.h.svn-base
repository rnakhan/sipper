#ifndef __SIPPER_MEDIA_LISTENER_H__
#define __SIPPER_MEDIA_LISTENER_H__

#pragma warning(disable: 4786)
#include <string>
#include <map>
#include "SipperMediaLock.h"

class SipperMediaController;
typedef std::map<int, SipperMediaController *> SipperMediaControllerMap;
typedef SipperMediaControllerMap::iterator SipperMediaControllerMapIt;

class SipperMediaListener
{
public:
   SipperMediaListener();
   
   int startListener(unsigned short portnum);
   void shutdown();

   static void setNonBlocking(int fd);
   static void setTcpNoDelay(int fd);
   static void disconnectSocket(int &fd);
   static std::string errorString();

protected:
   
   void addController(int accSock, SipperMediaController *controller);
   void removeController(int accSock);

private:

   SipperMediaControllerMap _controllerMap;
   SipperMediaMutex _mutex;
   bool _shutdownFlag;
   struct timeval _lastActivityTime;

   void _handleAcceptedController(int accSock);

   static void * _startControllerThread(void *);
};

#endif
